#!/bin/bash
set -e

################################################################################
# Update OS
################################################################################
apt-get update -y
apt-get upgrade -y

################################################################################
# Install Docker
# source: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
################################################################################
# Add Docker's official GPG key:
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

################################################################################
# Docker post-installation
# source: https://docs.docker.com/engine/install/linux-postinstall
################################################################################
# Add default ubuntu user to docker group
usermod -aG docker ubuntu

# Configure Docker to use the 'local' logging driver to prevent disk exhaustion
mkdir -p /etc/docker
cat <<EOF >/etc/docker/daemon.json
{
  "log-driver": "local"
}
EOF

# Ensure Docker starts on boot and apply logging changes
systemctl enable docker.service
systemctl enable containerd.service
systemctl restart docker

################################################################################
# Setup Traefik
################################################################################
mkdir -p /opt/traefik
cd /opt/traefik

# Create empty acme.json for Let's Encrypt certs (strict permissions required)
touch acme.json
chmod 600 acme.json

# Create docker-compose.yml for Traefik
cat <<EOF >docker-compose.yml
services:
  traefik:
    image: traefik:v3.3
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - proxy
    ports:
      - 80:80
      - 443:443
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/traefik.yml:ro
      - ./acme.json:/acme.json
networks:
  proxy:
    external: true
EOF

# Create traefik.yml configuration
cat <<EOF >traefik.yml
log:
  level: INFO
accessLog: {}

api:
  dashboard: true
  insecure: false

entryPoints:
  http:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: https
          scheme: https
  https:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false

certificatesResolvers:
  le:
    acme:
      email: "${acme_email}"
      storage: acme.json
      httpChallenge:
        entryPoint: http
EOF

# Create external docker network for Traefik and other containers
docker network create proxy || true

# Start Traefik
docker compose up -d

################################################################################
# Setup Web Application & Watchtower (Automated Bootstrap)
################################################################################
mkdir -p /opt/app
cd /opt/app

# # Download the latest compose.yml
curl -fsSL \
  --retry 5 \
  --retry-all-errors \
  --retry-delay 5 \
  -o compose.yml \
  https://raw.githubusercontent.com/stefinracho/stefin.dev/main/compose.yml

for attempt in $(seq 1 30); do
  if docker compose pull && docker compose up -d; then
    exit 0
  fi
  sleep 30
done

echo "Failed to start application after retries"
exit 1
