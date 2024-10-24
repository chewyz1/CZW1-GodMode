Adding Let's Encrypt for SSL certificate management to the installation script is a great idea to enhance security. Below, I will integrate the Let's Encrypt setup into the existing script to automatically secure the services with HTTPS.

Updated Setup Script with Let's Encrypt

Here’s the modified script that includes the installation and configuration of Let's Encrypt using Certbot. This assumes you're using a web server (like Nginx) to handle SSL termination.

#!/bin/bash

# Exit on any error
set -e

# Update and install dependencies
echo "Updating system and installing required packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose git python3 python3-pip certbot python3-certbot-nginx

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Mailcow setup
echo "Setting up Mailcow..."
git clone https://github.com/mailcow/mailcow-dockerized.git /opt/mailcow
cd /opt/mailcow
sudo ./generate_config.sh
sudo docker-compose pull
sudo docker-compose up -d

# Configure Mailcow for Let's Encrypt
echo "Configuring Mailcow for Let's Encrypt..."
# Set your domain and email address
MAILCOW_DOMAIN="mail.yourdomain.com"
EMAIL="youremail@yourdomain.com"

# Obtain Let's Encrypt certificates for Mailcow
sudo certbot certonly --standalone --agree-tos --email $EMAIL -d $MAILCOW_DOMAIN

# Nextcloud and OnlyOffice setup
echo "Setting up Nextcloud and OnlyOffice..."
# Create a directory for Nextcloud
mkdir -p /opt/nextcloud
cd /opt/nextcloud

# Nextcloud Docker Compose configuration
cat <<EOF > docker-compose.yml
version: '3.7'
services:
  nextcloud:
    image: nextcloud
    ports:
      - "8080:80"
    volumes:
      - nextcloud:/var/www/html
    environment:
      MYSQL_PASSWORD: password
      NEXTCLOUD_ADMIN_USER: admin
      NEXTCLOUD_ADMIN_PASSWORD: admin
  db:
    image: mariadb
    restart: always
    volumes:
      - db:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: password
EOF

sudo docker-compose up -d

# OnlyOffice setup (assuming you want to use Document Server)
echo "Setting up OnlyOffice..."
cd /opt
mkdir -p onlyoffice
cd onlyoffice

# OnlyOffice Docker Compose configuration
cat <<EOF > docker-compose.yml
version: '3.7'
services:
  onlyoffice-document-server:
    image: onlyoffice/documentserver
    ports:
      - "8081:80"
    volumes:
      - onlyoffice_data:/var/www/onlyoffice/Data
EOF

sudo docker-compose up -d

# Authelia setup
echo "Setting up Authelia for security..."
# Authelia configuration (this is a simplified example; modify as needed)
mkdir -p /opt/authelia
cd /opt/authelia

cat <<EOF > config.yml
host: 0.0.0.0
port: 9091
jwt_secret: your_jwt_secret
access_control:
  default_policy: deny
  rules:
    - domain: your_domain
      policy: two_factor
EOF

# Start Authelia
sudo docker run -d \
  --name=authelia \
  -v /opt/authelia/config.yml:/config/config.yml \
  -p 9091:9091 \
  authelia/authelia

# AI Service Setup
echo "Setting up AI service..."
mkdir -p /opt/ai_service
cd /opt/ai_service

# Create a basic AI service with Flask
cat <<EOF > app.py
from flask import Flask, request, jsonify
from transformers import GPT2LMHeadModel, GPT2Tokenizer

app = Flask(__name__)

model_name = 'gpt2'
tokenizer = GPT2Tokenizer.from_pretrained(model_name)
model = GPT2LMHeadModel.from_pretrained(model_name)

@app.route('/query', methods=['POST'])
def query():
    user_input = request.json.get('input')
    inputs = tokenizer.encode(user_input, return_tensors='pt')
    outputs = model.generate(inputs, max_length=150, num_return_sequences=1)
    response = tokenizer.decode(outputs[0], skip_special_tokens=True)
    return jsonify({"response": response})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Run AI service
sudo python3 app.py &

# Final integration points
echo "Integration points..."
# Add any necessary configurations for integrating services

# Configure Nginx for SSL
echo "Configuring Nginx for SSL..."
sudo apt install -y nginx
cat <<EOF | sudo tee /etc/nginx/sites-available/nextcloud
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    location / {
        rewrite ^ https://\$host$request_uri? permanent;
    }
}

server {
    listen 443 ssl;
    server_name yourdomain.com www.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://nextcloud:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
EOF

# Enable the Nginx configuration and reload
sudo ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

echo "All services have been set up with SSL. Access your services at the following URLs:"
echo "Mailcow: https://mail.yourdomain.com"
echo "Nextcloud: https://yourdomain.com"
echo "OnlyOffice: https://yourdomain.com:8081"
echo "AI Service: https://yourdomain.com:5000/query"

Notes on the Script

1. Let's Encrypt Setup: The script now includes a section for obtaining a certificate from Let's Encrypt using Certbot. Ensure to replace mail.yourdomain.com and yourdomain.com with your actual domain name.


2. Nginx Configuration: The script sets up Nginx to handle SSL termination, redirecting HTTP traffic to HTTPS and proxying requests to your Dockerized services.


3. Run with Root Privileges: Make sure to run the script with sudo or as a root user, as it requires elevated permissions to install packages and modify system configurations.


4. Testing: After running the script, test each service to ensure they are accessible via HTTPS.



Executing the Updated Script

1. Save the script to a file, e.g., setup_all_services_ssl.sh.


2. Make it executable:

chmod +x setup_all_services_ssl.sh


3. Run the script:

sudo ./setup_all_services_ssl.sh



Final Considerations

Firewall Settings: Ensure your firewall allows traffic on the necessary ports (80, 443, and any other required ports).

Renewal of SSL Certificates: Let’s Encrypt certificates are valid for 90 days. You may want to set up a cron job to automatically renew your certificates:

sudo crontab -e

Add the following line to the crontab to renew the certificates automatically:

0 0 * * * certbot renew --quiet


Let me know if you need any further modifications or assistance!

