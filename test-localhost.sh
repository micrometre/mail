#!/bin/bash

# Test script for localhost mail server
echo "🔍 Testing localhost mail server setup..."

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test functions
test_service() {
    local service=$1
    if sudo systemctl is-active --quiet $service; then
        echo -e "${GREEN}✓ $service is running${NC}"
        return 0
    else
        echo -e "${RED}✗ $service is not running${NC}"
        return 1
    fi
}

test_port() {
    local port=$1
    local desc=$2
    if sudo netstat -tlnp | grep -q ":$port "; then
        echo -e "${GREEN}✓ Port $port ($desc) is listening${NC}"
        return 0
    else
        echo -e "${RED}✗ Port $port ($desc) is not listening${NC}"
        return 1
    fi
}

test_ssl_cert() {
    if [[ -f "/etc/ssl/mailserver/localhost.local.crt" ]]; then
        echo -e "${GREEN}✓ Self-signed certificate exists${NC}"
        # Show certificate info
        echo -e "${YELLOW}Certificate details:${NC}"
        sudo openssl x509 -in /etc/ssl/mailserver/localhost.local.crt -noout -dates -subject
        return 0
    else
        echo -e "${RED}✗ SSL certificate not found${NC}"
        return 1
    fi
}

test_roundcube_db() {
    if [[ -f "/var/lib/roundcube/sqlite.db" ]]; then
        echo -e "${GREEN}✓ Roundcube SQLite database exists${NC}"
        echo -e "${YELLOW}Database size: $(du -h /var/lib/roundcube/sqlite.db | cut -f1)${NC}"
        return 0
    else
        echo -e "${RED}✗ Roundcube database not found${NC}"
        return 1
    fi
}

echo ""
echo "=== Service Status ==="
test_service "postfix"
test_service "dovecot" 
test_service "apache2"

echo ""
echo "=== Port Status ==="
test_port "25" "SMTP"
test_port "587" "SMTP Submission"
test_port "993" "IMAPS"
test_port "995" "POP3S"
test_port "80" "HTTP"
test_port "443" "HTTPS"

echo ""
echo "=== Configuration Status ==="
test_ssl_cert
test_roundcube_db

echo ""
echo "=== Hosts File Check ==="
if grep -q "localhost.local" /etc/hosts; then
    echo -e "${GREEN}✓ Hosts entries configured${NC}"
    grep "localhost.local" /etc/hosts
else
    echo -e "${RED}✗ Hosts entries missing${NC}"
    echo "Run: sudo echo '127.0.0.1 localhost.local mail.localhost.local' >> /etc/hosts"
fi

echo ""
echo "=== Mail User Check ==="
if [[ -f "/etc/dovecot/dovecot-users" ]]; then
    echo -e "${GREEN}✓ Mail users configured${NC}"
    echo -e "${YELLOW}Available accounts:${NC}"
    grep "@" /etc/dovecot/dovecot-users | cut -d: -f1 | sed 's/^/  - /'
else
    echo -e "${RED}✗ Mail users file not found${NC}"
fi

echo ""
echo "=== Quick Access Info ==="
echo -e "${YELLOW}🌐 Webmail:${NC} https://mail.localhost.local/mail"
echo -e "${YELLOW}📧 Test with:${NC} admin@localhost.local / admin123"
echo ""

# Overall health check
if systemctl is-active --quiet postfix dovecot apache2; then
    echo -e "${GREEN}🎉 Mail server appears to be running correctly!${NC}"
else
    echo -e "${RED}⚠️ Some services are not running properly${NC}"
    echo "Run './deploy-localhost.sh' to fix issues"
fi