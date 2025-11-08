#!/bin/bash

# Localhost Mail Server Deployment Script
# Perfect for learning and development purposes

set -e

PLAYBOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PLAYBOOK_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🏠 Localhost Mail Server Setup${NC}"
echo "================================"
echo -e "${BLUE}Perfect for learning mail server administration!${NC}"
echo ""

# Check if we're running as root or with sudo
if [[ $EUID -eq 0 ]]; then
   echo -e "${YELLOW}⚠️  Running as root. This is fine for localhost development.${NC}"
elif sudo -n true 2>/dev/null; then
   echo -e "${GREEN}✓ Sudo access confirmed${NC}"
else
   echo -e "${RED}❌ This script needs sudo access to install mail server components${NC}"
   echo "Please run: sudo -v"
   exit 1
fi

# Check if inventory file exists
if [[ ! -f "inventories/localhost.yml" ]]; then
    echo -e "${RED}Error: inventories/localhost.yml not found!${NC}"
    echo "Creating localhost inventory from template..."
    cp inventories/example.yml inventories/localhost.yml
    echo -e "${GREEN}✓ Created inventories/localhost.yml${NC}"
fi

# Function to install Ansible if needed
install_ansible() {
    if ! command -v ansible-playbook &> /dev/null; then
        echo -e "${YELLOW}Installing Ansible and dependencies...${NC}"
        sudo apt update
        sudo apt install -y ansible python3-cryptography python3-cffi python3-dev libffi-dev libssl-dev
        echo -e "${GREEN}✓ Ansible and dependencies installed${NC}"
    else
        echo -e "${GREEN}✓ Ansible already installed${NC}"
        echo -e "${YELLOW}Ensuring Python crypto dependencies are installed...${NC}"
        sudo apt update
        sudo apt install -y python3-cryptography python3-cffi python3-dev libffi-dev libssl-dev
        echo -e "${GREEN}✓ Dependencies checked${NC}"
    fi
}

# Function to install required Ansible collections
install_collections() {
    echo -e "${YELLOW}Installing required Ansible collections...${NC}"
    ansible-galaxy collection install community.general
    echo -e "${GREEN}✓ Collections installed${NC}"
}

# Function to run syntax check
syntax_check() {
    echo -e "${YELLOW}Checking playbook syntax...${NC}"
    if ansible-playbook -i inventories/localhost.yml site.yml --syntax-check; then
        echo -e "${GREEN}✓ Syntax check passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Syntax check failed${NC}"
        return 1
    fi
}

# Function to run dry run
dry_run() {
    echo -e "${YELLOW}Running dry run...${NC}"
    ansible-playbook -i inventories/localhost.yml site.yml --check --diff
}

# Function to deploy mail server
deploy() {
    echo -e "${YELLOW}Deploying localhost mail server...${NC}"
    echo -e "${BLUE}This will install: Postfix, Dovecot, Apache, and Roundcube${NC}"
    ansible-playbook -i inventories/localhost.yml site.yml
}

# Function to show access info
show_access_info() {
    echo ""
    echo -e "${GREEN}🎉 Mail Server Setup Complete!${NC}"
    echo "=================================="
    echo ""
    echo -e "${BLUE}📧 Access Information:${NC}"
    echo "• Webmail URL: https://mail.localhost.local/mail"
    echo "• Or try: https://localhost/mail"
    echo ""
    echo -e "${BLUE}📱 Email Client Settings:${NC}"
    echo "• IMAP Server: mail.localhost.local:993 (SSL)"
    echo "• POP3 Server: mail.localhost.local:995 (SSL)"
    echo "• SMTP Server: mail.localhost.local:587 (STARTTLS)"
    echo ""
    echo -e "${BLUE}👤 Test Accounts:${NC}"
    echo "• admin@localhost.local / admin123"
    echo "• test@localhost.local / test123"
    echo "• user@localhost.local / user123"
    echo ""
    echo -e "${YELLOW}⚠️  Certificate Warning:${NC}"
    echo "You'll see SSL certificate warnings in your browser."
    echo "This is normal for self-signed certificates - just accept them."
    echo ""
    echo -e "${BLUE}🔍 Useful Commands:${NC}"
    echo "• Check services: sudo systemctl status postfix dovecot apache2"
    echo "• View logs: sudo journalctl -u postfix -f"
    echo "• Test SMTP: telnet localhost 587"
    echo ""
}

# Function to add hosts entries
setup_hosts() {
    echo -e "${YELLOW}Setting up /etc/hosts entries...${NC}"
    
    # Check if entries already exist
    if ! grep -q "mail.localhost.local" /etc/hosts; then
        echo "127.0.0.1 localhost.local mail.localhost.local" | sudo tee -a /etc/hosts
        echo -e "${GREEN}✓ Added hosts entries${NC}"
    else
        echo -e "${GREEN}✓ Hosts entries already exist${NC}"
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "Choose an option:"
    echo "1) 🚀 Quick Deploy (recommended for first time)"
    echo "2) 🔍 Check syntax only"
    echo "3) 🧪 Dry run (see what would be changed)"
    echo "4) ⚙️  Deploy mail server"
    echo "5) 📋 Show access information"
    echo "6) 🔧 Setup /etc/hosts entries"
    echo "7) 📊 Check service status"
    echo "8) 🚪 Exit"
    echo ""
}

# Service status check
check_status() {
    echo -e "${YELLOW}Checking mail services status...${NC}"
    
    services=("postfix" "dovecot" "apache2")
    for service in "${services[@]}"; do
        if sudo systemctl is-active --quiet $service; then
            echo -e "${GREEN}✓ $service is running${NC}"
        else
            echo -e "${RED}✗ $service is not running${NC}"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}Port status:${NC}"
    for port in 25 587 993 995 80 443; do
        if sudo netstat -tlnp | grep -q ":$port "; then
            echo -e "${GREEN}✓ Port $port is listening${NC}"
        else
            echo -e "${RED}✗ Port $port is not listening${NC}"
        fi
    done
}

# Quick deploy function
quick_deploy() {
    echo -e "${BLUE}🚀 Starting Quick Deploy for localhost mail server${NC}"
    echo "This will:"
    echo "  1. Install Ansible if needed"
    echo "  2. Install required collections"
    echo "  3. Setup hosts entries"
    echo "  4. Deploy the mail server"
    echo ""
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        install_ansible
        install_collections
        setup_hosts
        if syntax_check; then
            deploy
            show_access_info
        fi
    fi
}

# Main loop
while true; do
    show_menu
    read -p "Enter choice [1-8]: " choice
    
    case $choice in
        1) quick_deploy ;;
        2) syntax_check ;;
        3) dry_run ;;
        4) 
            read -p "Are you sure you want to deploy? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                deploy
                show_access_info
            fi
            ;;
        5) show_access_info ;;
        6) setup_hosts ;;
        7) check_status ;;
        8) echo -e "${GREEN}Happy learning! 🎓${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done