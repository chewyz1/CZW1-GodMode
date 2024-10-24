#!/bin/bash

# Automated Script for Mailcow, Nextcloud + OnlyOffice, and Taiga Setup

# Function for prompting user
prompt_user() {
    echo "Do you want to proceed with the setup of $1? (yes/no)"
    read response
    if [[ "$response" != "yes" ]]; then
        echo "Skipping $1 setup."
        return 1
    fi
    return 0
}

# Step 1: Mailcow Setup
setup_mailcow() {
    echo "Setting up Mailcow..."
    git clone https://github.com/mailcow/mailcow-dockerized
    cd mailcow-dockerized
    ./generate_config.sh
    docker-compose pull
    docker-compose up -d
    echo "Mailcow setup completed."
}

# Step 2: Nextcloud + OnlyOffice Setup
setup_nextcloud_onlyoffice() {
    echo "Setting up Nextcloud + OnlyOffice..."
    docker run -d -v nextcloud:/var/www/html -p 8080:80 nextcloud
    docker run -d -p 8000:80 --name onlyoffice-document-server         -v /app/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data         onlyoffice/documentserver
    echo "Nextcloud and OnlyOffice setup completed."
}

# Step 3: Taiga Setup with Docker
setup_taiga() {
    echo "Setting up Taiga using Docker..."
    git clone https://github.com/taigaio/taiga-docker.git
    cd taiga-docker
    cp .env.sample .env
    docker-compose up -d
    echo "Taiga setup completed."
}

# Step 4: GitHub Integration for Taiga
setup_github_integration() {
    echo "Setting up GitHub integration for Taiga..."
    echo "In Taiga, navigate to Admin -> Integrations and enable GitHub."
    echo "Set up a GitHub app from your account with necessary details and input Client ID and Secret in Taiga."
    echo "You can now track GitHub issues and commits from Taiga."
}

# Step 5: Nextcloud Integration for Taiga
setup_nextcloud_integration() {
    echo "Setting up Nextcloud integration for Taiga..."
    echo "Navigate to Admin -> Integrations -> Nextcloud and input WebDAV or API details to link file sharing."
}

# Step 6: Automate API Workflows
automate_workflows() {
    echo "Setting up automation workflows using Taiga API..."
    echo "Use API to create tasks, track issues, and sync with GitHub and Nextcloud."
}

# Prompt for each section
prompt_user "Mailcow" && setup_mailcow
prompt_user "Nextcloud + OnlyOffice" && setup_nextcloud_onlyoffice
prompt_user "Taiga" && setup_taiga
prompt_user "GitHub Integration for Taiga" && setup_github_integration
prompt_user "Nextcloud Integration for Taiga" && setup_nextcloud_integration
prompt_user "Automated API Workflows" && automate_workflows

echo "All selected setups completed!"
