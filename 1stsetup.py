#!/bin/bash

# Welcome message for the initial setup
echo "Welcome to the Godmode Project Setup"
echo "Please provide the following details to configure your system."

# Prompt for user details required for setup
read -p "Enter the project name: " PROJECT_NAME
read -p "Enter the domain (e.g., example.com): " DOMAIN
read -p "Enter the server IP address: " SERVER_IP
read -p "Enter the database name: " DB_NAME
read -p "Enter the database user: " DB_USER
read -sp "Enter the database password: " DB_PASSWORD
echo # For a new line after entering the password
read -p "Enter the admin email: " ADMIN_EMAIL

# Optional settings
read -p "Enable HTTPS (yes/no)? " ENABLE_HTTPS
read -p "Setup VPN (yes/no)? " SETUP_VPN

# Display a summary of the collected input
echo
echo "===== Configuration Summary ====="
echo "Project Name: $PROJECT_NAME"
echo "Domain: $DOMAIN"
echo "Server IP: $SERVER_IP"
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"
echo "Admin Email: $ADMIN_EMAIL"
echo "Enable HTTPS: $ENABLE_HTTPS"
echo "Setup VPN: $SETUP_VPN"
echo "=================================="
echo

# Write the configuration to a file (optional, for later use)
cat <<EOF > godmode_config.txt
PROJECT_NAME=$PROJECT_NAME
DOMAIN=$DOMAIN
SERVER_IP=$SERVER_IP
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
ADMIN_EMAIL=$ADMIN_EMAIL
ENABLE_HTTPS=$ENABLE_HTTPS
SETUP_VPN=$SETUP_VPN
EOF

echo "Configuration saved to godmode_config.txt"

# Proceed with the actual setup steps

# Update package list and install necessary tools (example)
echo "Updating system and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker docker-compose mysql-client

# Set up the database
echo "Setting up the database..."
sudo mysql -u root -p -e "CREATE DATABASE $DB_NAME;"
sudo mysql -u root -p -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
sudo mysql -u root -p -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -u root -p -e "FLUSH PRIVILEGES;"

# Set up HTTPS if the user enabled it
if [ "$ENABLE_HTTPS" == "yes" ]; then
  echo "Configuring HTTPS using Let's Encrypt..."
  sudo apt install -y certbot python3-certbot-nginx
  sudo certbot --nginx -d $DOMAIN --email $ADMIN_EMAIL --agree-tos --non-interactive
  sudo systemctl restart nginx
else
  echo "Skipping HTTPS setup."
fi

# Set up VPN if the user enabled it
if [ "$SETUP_VPN" == "yes" ]; then
  echo "Setting up a VPN server..."
  # Insert VPN setup commands, such as OpenVPN or WireGuard
  sudo apt install -y openvpn
  echo "VPN setup is complete."
else
  echo "Skipping VPN setup."
fi

# Final message
echo "Godmode Project setup is complete!"