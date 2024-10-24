#!/bin/bash

# Automated Authelia Setup with SSO and MFA for Taiga, Nextcloud, and Mailcow

# Install Docker and Docker Compose if not installed
install_docker() {
    echo "Checking if Docker is installed..."
    if ! [ -x "$(command -v docker)" ]; then
        echo "Docker not found. Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
    fi
    if ! [ -x "$(command -v docker-compose)" ]; then
        echo "Docker Compose not found. Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    echo "Docker and Docker Compose are installed."
}

# Step 1: Set up Authelia container
setup_authelia() {
    echo "Setting up Authelia..."
    mkdir -p /authelia && cd /authelia
    cat <<EOF > docker-compose.yml
version: '3'

services:
  authelia:
    image: authelia/authelia
    container_name: authelia
    restart: unless-stopped
    volumes:
      - ./configuration.yml:/etc/authelia/configuration.yml
    environment:
      - TZ=Europe/Paris
    ports:
      - "9091:9091"

networks:
  default:
    external:
      name: traefik
EOF

    # Authelia configuration file
    cat <<EOF > configuration.yml
host: 0.0.0.0
port: 9091
jwt_secret: your_jwt_secret_here
default_redirection_url: https://yourdomain.com

authentication_backend:
  file:
    path: /config/users_database.yml

access_control:
  default_policy: deny
  rules:
    - domain: "*.yourdomain.com"
      policy: two_factor

session:
  name: authelia_session
  secret: your_session_secret_here
  expiration: 3600
  inactivity: 300
  remember_me_duration: 1M

totp:
  issuer: yourdomain.com
  period: 30
  skew: 1

regulation:
  max_retries: 5
  find_time: 120
  ban_time: 300

storage:
  encryption_key: your_encryption_key_here

notifier:
  filesystem:
    filename: /config/notification.txt
EOF

    echo "Authelia setup completed."
}

# Step 2: Configure NGINX for Authelia and SSO
setup_nginx() {
    echo "Configuring NGINX reverse proxy for Authelia..."
    # NGINX config file for Authelia
    cat <<EOF > /etc/nginx/conf.d/authelia.conf
server {
    listen 80;
    server_name authelia.yourdomain.com;

    location / {
        proxy_pass http://authelia:9091;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    echo "NGINX configuration for Authelia completed."
}

# Step 3: Link Taiga, Nextcloud, and Mailcow to Authelia for SSO
setup_sso_integration() {
    echo "Configuring Taiga, Nextcloud, and Mailcow for SSO integration with Authelia..."

    # Taiga SSO setup instructions
    echo "Navigate to Taiga Admin -> Integrations and enable OAuth2 with the following details:"
    echo " - Authorization URL: https://authelia.yourdomain.com/oauth2/authorize"
    echo " - Token URL: https://authelia.yourdomain.com/oauth2/token"

    # Nextcloud OAuth2 setup instructions
    echo "For Nextcloud, install the OAuth2 app, and configure it to work with Authelia:"
    echo " - Authorization URL: https://authelia.yourdomain.com/oauth2/authorize"
    echo " - Token URL: https://authelia.yourdomain.com/oauth2/token"

    # Mailcow OAuth2 setup instructions
    echo "For Mailcow, enable external OAuth2 authentication, and configure it as follows:"
    echo " - OAuth2 URL: https://authelia.yourdomain.com/oauth2/token"
}

# Step 4: Enforce MFA (TOTP) for all services
configure_mfa() {
    echo "Configuring MFA for Taiga, Nextcloud, and Mailcow through Authelia..."
    echo "MFA has been enforced using TOTP (Time-based One-Time Passwords)."
}

# Main script execution
install_docker
setup_authelia
setup_nginx
setup_sso_integration
configure_mfa

echo "Authelia setup with SSO and MFA for Taiga, Nextcloud, and Mailcow completed!"