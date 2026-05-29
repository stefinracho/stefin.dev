terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = ""
    region       = ""
    key          = "core/terraform.tfstate"
    use_lockfile = true
  }
}

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6"

  name = "${var.project_prefix}-vpc"

  cidr           = "10.2.0.0/16"
  public_subnets = ["10.2.101.0/24"]

  azs = [data.aws_availability_zones.available.names[0]]

  tags = {
    Environment = var.environment
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~>5.3"

  name        = "${var.project_prefix}-web-sg-v3"
  description = "Security group for web server allowing HTTP/HTTPS globally"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      description      = "HTTP globally"
      ipv6_cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      description      = "HTTPS globally"
      ipv6_cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_rules = ["all-all"]
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.4"
  name    = "${var.project_prefix}-server"

  create_security_group = false

  depends_on = [module.security_group]

  instance_type               = "t3.micro"
  ami                         = data.aws_ami.ubuntu.id
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true

  create_iam_instance_profile = true
  iam_role_name               = "${var.project_prefix}-ec2-role"
  iam_role_use_name_prefix    = false
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    acme_email = var.acme_email
  })
  user_data_replace_on_change = true

  tags = {
    Environment = var.environment
  }
}

resource "aws_eip" "web" {
  instance = module.ec2_instance.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_prefix}-eip"
    Environment = var.environment
  }
}
