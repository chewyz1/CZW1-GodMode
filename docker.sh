#!/bin/bash

# Welcome message
echo "Welcome to the Godmode Services Docker Setup"

# Prompt for user inputs
read -p "Enter the project name (e.g., godmode): " PROJECT_NAME
read -p "Enter the domain (e.g., example.com): " DOMAIN
read -p "Enter the server IP address: " SERVER_IP
read -p "Enter the database name: " DB_NAME
read -p "Enter the database user: " DB_USER
read -sp "Enter the database password: " DB_PASSWORD
echo
read -p "Enter the admin email: " ADMIN_EMAIL
read -p "Enter the AI model (e.g., GPT-3, BERT): " AI_MODEL
read -p "Enter the AI API key (if applicable): " AI_API_KEY
read -p "Enter the number of AI workers (default 4): " AI_WORKERS
read -p "Enable HTTPS (yes/no)? " ENABLE_HTTPS
read -p "Setup VPN (yes/no)? " SETUP_VPN

# Write the docker-compose.yml file
cat <<EOF > docker-compose.yml
version: '3'
services:
  db:
    image: mysql:latest
    container_name: ${PROJECT_NAME}_db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: $DB_PASSWORD
      MYSQL_DATABASE: $DB_NAME
      MYSQL_USER: $DB_USER
      MYSQL_PASSWORD: $DB_PASSWORD
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - godmode_net

  web:
    image: nginx:latest
    container_name: ${PROJECT_NAME}_web
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx_conf:/etc/nginx/conf.d
      - ./certs:/etc/ssl/certs
    networks:
      - godmode_net
    depends_on:
      - app

  app:
    image: custom_godmode_service:latest
    container_name: ${PROJECT_NAME}_app
    restart: always
    environment:
      DB_NAME: $DB_NAME
      DB_USER: $DB_USER
      DB_PASSWORD: $DB_PASSWORD
      AI_MODEL: $AI_MODEL
      AI_API_KEY: $AI_API_KEY
      AI_WORKERS: ${AI_WORKERS:-4}
    ports:
      - "5000:5000"
    networks:
      - godmode_net
    depends_on:
      - db

volumes:
  db_data:

networks:
  godmode_net:
EOF

echo "Docker Compose file has been generated."

# Optional HTTPS configuration
if [ "$ENABLE_HTTPS" == "yes" ]; then
  echo "Enabling HTTPS configuration..."
  mkdir -p certs
  docker run -it --rm -v $(pwd)/certs:/etc/letsencrypt \
    -v $(pwd)/nginx_conf:/etc/nginx/conf.d certbot/certbot \
    certonly --standalone --preferred-challenges http --agree-tos --email $ADMIN_EMAIL -d $DOMAIN
  echo "Certificates generated and saved in the 'certs' directory."
fi

# Create nginx configuration for the domain
echo "Setting up NGINX configuration..."
mkdir -p nginx_conf
cat <<EOF > nginx_conf/default.conf
server {
    listen 80;
    server_name $DOMAIN;
    location / {
        proxy_pass http://app:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/ssl/certs/fullchain.pem;
    ssl_certificate_key /etc/ssl/certs/privkey.pem;

    location / {
        proxy_pass http://app:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Optional VPN setup
if [ "$SETUP_VPN" == "yes" ]; then
  echo "Setting up a VPN service..."
  # Sample setup for OpenVPN
  docker pull kylemanna/openvpn
  docker run -v $(pwd)/openvpn_data:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://$SERVER_IP
  docker run -v $(pwd)/openvpn_data:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki
  docker run -v $(pwd)/openvpn_data:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn
  echo "VPN setup complete and running on port 1194."
fi

# Docker Compose up
echo "Starting Godmode services..."
docker-compose up -d

echo "All services are up and running!"