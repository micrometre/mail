#!/bin/bash

# Mail Server Deployment Script
# This script provides a convenient way to deploy the mail server

set -e

PLAYBOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PLAYBOOK_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Mail Server Ansible Deployment Script${NC}"
echo "======================================"

# Check if inventory file exists
if [[ ! -f "inventories/production.yml" ]]; then
    echo -e "${RED}Error: inventories/production.yml not found!${NC}"
    echo "Please copy and configure the inventory file first."
    exit 1
fi

# Function to test connection
test_connection() {
    echo -e "${YELLOW}Testing connection to mail servers...${NC}"
    if ansible mailservers -m ping; then
        echo -e "${GREEN}✓ Connection successful${NC}"
        return 0
    else
        echo -e "${RED}✗ Connection failed${NC}"
        return 1
    fi
}

# Function to run syntax check
syntax_check() {
    echo -e "${YELLOW}Checking playbook syntax...${NC}"
    if ansible-playbook site.yml --syntax-check; then
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
    ansible-playbook site.yml --check --diff
}

# Function to deploy mail server
deploy() {
    echo -e "${YELLOW}Deploying mail server...${NC}"
    ansible-playbook site.yml
}

# Function to deploy specific role
deploy_role() {
    local role=$1
    echo -e "${YELLOW}Deploying $role role...${NC}"
    ansible-playbook site.yml --tags "$role"
}

# Main menu
show_menu() {
    echo ""
    echo "Choose an option:"
    echo "1) Test connection"
    echo "2) Syntax check"
    echo "3) Dry run (check mode)"
    echo "4) Deploy complete mail server"
    echo "5) Deploy specific role"
    echo "6) View logs"
    echo "7) Exit"
    echo ""
}

# Log viewing function
view_logs() {
    echo "Select log to view:"
    echo "1) Postfix logs"
    echo "2) Dovecot logs"
    echo "3) Apache logs"
    echo "4) Roundcube logs"
    echo "5) Back to main menu"
    
    read -p "Enter choice [1-5]: " log_choice
    
    case $log_choice in
        1) ansible mailservers -m shell -a "journalctl -u postfix -n 50" ;;
        2) ansible mailservers -m shell -a "journalctl -u dovecot -n 50" ;;
        3) ansible mailservers -m shell -a "tail -n 50 /var/log/apache2/access.log" ;;
        4) ansible mailservers -m shell -a "tail -n 50 /var/log/roundcube/errors.log" ;;
        5) return ;;
        *) echo "Invalid option" ;;
    esac
}

# Role selection function
select_role() {
    echo "Select role to deploy:"
    echo "1) Common (base system setup)"
    echo "2) Apache (web server)"
    echo "3) Postfix (SMTP server)"
    echo "4) Dovecot (IMAP/POP3 server)"
    echo "5) Roundcube (webmail client)"
    echo "6) Back to main menu"
    
    read -p "Enter choice [1-6]: " role_choice
    
    case $role_choice in
        1) deploy_role "common" ;;
        2) deploy_role "apache" ;;
        3) deploy_role "postfix" ;;
        4) deploy_role "dovecot" ;;
        5) deploy_role "roundcube" ;;
        6) return ;;
        *) echo "Invalid option" ;;
    esac
}

# Main loop
while true; do
    show_menu
    read -p "Enter choice [1-7]: " choice
    
    case $choice in
        1) test_connection ;;
        2) syntax_check ;;
        3) dry_run ;;
        4) 
            if test_connection && syntax_check; then
                read -p "Are you sure you want to deploy? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    deploy
                fi
            fi
            ;;
        5) select_role ;;
        6) view_logs ;;
        7) echo "Goodbye!"; exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done