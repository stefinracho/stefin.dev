# ==============================================================================
# Shared State Access
# ==============================================================================
data "aws_iam_policy_document" "terraform_state_access" {
  statement {
    sid    = "AllowStateRead"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListBucket",
      "s3:GetBucketVersioning",
    ]
    resources = [
      aws_s3_bucket.terraform_state.arn,
      "${aws_s3_bucket.terraform_state.arn}/*",
    ]
  }

  statement {
    sid    = "AllowStateLockOperations"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${aws_s3_bucket.terraform_state.arn}/*.tflock",
    ]
  }
}

# ==============================================================================
# State Write (apply only)
# ==============================================================================
data "aws_iam_policy_document" "terraform_state_write" {
  statement {
    sid    = "AllowStateWrite"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.terraform_state.arn}/*.tfstate",
    ]
  }
}

# ==============================================================================
# Plan Role Policies
# ==============================================================================
resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.github_actions_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
resource "aws_iam_role_policy" "plan_state_access" {
  name   = "terraform-state-access"
  role   = aws_iam_role.github_actions_plan.id
  policy = data.aws_iam_policy_document.terraform_state_access.json
}

# ==============================================================================
# Apply Role Policies
# ==============================================================================
data "aws_iam_policy_document" "terraform_apply_permissions" {
  statement {
    sid    = "AllowInfrastructureProvisioning"
    effect = "Allow"
    actions = [
      # Compute and Systems Manager
      "ec2:*",
      "ssm:*",

      # Bucket lifecycle
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:ListBucket",
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",

      # Bucket configuration (read)
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketLogging",
      "s3:GetBucketNotification",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketOwnershipControls",
      "s3:GetBucketPolicy",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketWebsite",
      "s3:GetEncryptionConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",

      # Bucket configuration (write)
      "s3:PutBucketCORS",
      "s3:PutBucketLogging",
      "s3:PutBucketNotification",
      "s3:PutBucketObjectLockConfiguration",
      "s3:PutBucketOwnershipControls",
      "s3:PutBucketPolicy",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketTagging",
      "s3:PutBucketVersioning",
      "s3:PutBucketWebsite",
      "s3:PutEncryptionConfiguration",
      "s3:PutLifecycleConfiguration",
      "s3:PutReplicationConfiguration",
      "s3:DeleteBucketPolicy",
      "s3:DeleteBucketWebsite",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid    = "ManageScopedRolesAndInstanceProfiles"
    effect = "Allow"
    actions = [
      # Role CRUD
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:UpdateRoleDescription",
      "iam:UpdateAssumeRolePolicy",
      "iam:PassRole",

      # Inline role policies
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:ListRolePolicies",

      # Attached managed role policies
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",

      # Role tags
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags",

      # Instance profile CRUD
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:ListInstanceProfilesForRole",

      # Instance profile tags
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
      "iam:ListInstanceProfileTags",
    ]
    resources = [
      "arn:aws:iam::*:role/${var.project_prefix}-*",
      "arn:aws:iam::*:instance-profile/${var.project_prefix}-*",
    ]
  }

  statement {
    sid    = "DenyStateBucketDestructiveActions"
    effect = "Deny"
    actions = [
      "s3:DeleteBucket",
      "s3:DeleteBucketPolicy",
      "s3:DeleteObjectVersion",
      "s3:PutBucketPolicy",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketAcl",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketVersioning",
      "s3:PutLifecycleConfiguration",
    ]
    resources = [
      aws_s3_bucket.terraform_state.arn,
      "${aws_s3_bucket.terraform_state.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "apply_infrastructure" {
  name   = "terraform-infrastructure-policy"
  role   = aws_iam_role.github_actions_apply.id
  policy = data.aws_iam_policy_document.terraform_apply_permissions.json
}

resource "aws_iam_role_policy" "apply_state_access" {
  name   = "terraform-state-access"
  role   = aws_iam_role.github_actions_apply.id
  policy = data.aws_iam_policy_document.terraform_state_access.json
}

resource "aws_iam_role_policy" "apply_state_write" {
  name   = "terraform-state-write"
  role   = aws_iam_role.github_actions_apply.id
  policy = data.aws_iam_policy_document.terraform_state_write.json
}
