# Mail Server Ansible Playbook

This Ansible playbook automates the installation and configuration of a complete mail server stack based on the [Vultr guide](https://docs.vultr.com/how-to-install-postfix-dovecot-and-roundcube-on-ubuntu-20-04), with SQLite replacing MySQL for Roundcube.

## 🏠 Quick Start for Localhost Development

**Perfect for learning mail server administration!**

```bash
cd ansible
./deploy-localhost.sh
# Choose option 1 for quick deploy
```

This will set up a complete mail server on your local machine with self-signed certificates. No domain or SSL setup required!

## Components

- **Postfix**: Mail Transfer Agent (MTA) for sending and receiving emails
- **Dovecot**: IMAP/POP3 server for email retrieval
- **Apache**: Web server for hosting Roundcube
- **Roundcube**: Web-based email client with SQLite database
- **UFW**: Firewall configuration

## Prerequisites

### For Production Deployment

Before running this playbook, ensure you have:

1. **Target Server**: Ubuntu 20.04+ server with sudo privileges
2. **SSL Certificate**: Valid SSL certificate for your domain (Let's Encrypt recommended)
3. **DNS Configuration**: Proper DNS records for your mail domain:
   - A record: `mail.example.com` → Your server IP
   - MX record: `example.com` → `mail.example.com`
4. **Ansible**: Installed on your control machine

### For Localhost Development

**Much simpler!** Just need:

1. **Ubuntu/Debian system** (or WSL on Windows)
2. **Sudo access** on your local machine
3. **Internet connection** for package downloads

The playbook will automatically:
- Install Ansible if needed
- Generate self-signed SSL certificates
- Configure all services for localhost
- Set up test email accounts

### SSL Certificate Setup (if using Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-apache
sudo certbot certonly --standalone -d mail.example.com
```

## Directory Structure

```
ansible/
├── ansible.cfg
├── site.yml
├── inventories/
│   └── production.yml
└── roles/
    ├── common/
    ├── apache/
    ├── postfix/
    ├── dovecot/
    └── roundcube/
```

## Configuration

### 1. Edit Inventory File

Edit `inventories/production.yml` and update the following variables:

```yaml
all:
  children:
    mailservers:
      hosts:
        mail.example.com:  # Your mail server hostname
          ansible_host: 192.168.1.100  # Your server IP
          ansible_user: ubuntu  # SSH user
          ansible_ssh_private_key_file: ~/.ssh/id_rsa  # SSH key path
      vars:
        # Domain configuration
        mail_domain: example.com  # Your email domain
        mail_hostname: mail.example.com  # Your mail server FQDN
        
        # SSL Certificate paths
        ssl_cert_path: "/etc/letsencrypt/live/example.com/fullchain.pem"
        ssl_key_path: "/etc/letsencrypt/live/example.com/privkey.pem"
        
        # Email accounts to create
        mail_users:
          - email: "admin@example.com"
            password: "secure_password_123"
          - email: "info@example.com"
            password: "another_secure_password"
          - email: "billing@example.com"
            password: "billing_password_456"
```

### 2. Key Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `mail_domain` | Your email domain | `example.com` |
| `mail_hostname` | Mail server FQDN | `mail.example.com` |
| `ssl_cert_path` | SSL certificate file path | `/etc/letsencrypt/live/example.com/fullchain.pem` |
| `ssl_key_path` | SSL private key file path | `/etc/letsencrypt/live/example.com/privkey.pem` |
| `mail_users` | List of email accounts | See example above |
| `apache_server_admin` | Apache server admin email | `admin@example.com` |
| `roundcube_db_path` | SQLite database path | `/var/lib/roundcube/sqlite.db` |

## Deployment

### Localhost Development (Recommended for Learning)

**Super easy setup for learning and testing:**

```bash
cd ansible
./deploy-localhost.sh
```

The script will guide you through:
1. Installing Ansible (if needed)
2. Setting up self-signed certificates
3. Deploying the complete mail stack
4. Showing you how to access everything

**After deployment, access:**
- **Webmail**: https://mail.localhost.local/mail (accept certificate warning)
- **Test accounts**: 
  - admin@localhost.local / admin123
  - test@localhost.local / test123
  - user@localhost.local / user123

### Production Deployment

### 1. Test Connection

```bash
cd ansible
ansible mailservers -m ping
```

### 2. Run the Complete Playbook

```bash
ansible-playbook site.yml
```

### 3. Run Specific Roles

```bash
# Install only Postfix
ansible-playbook site.yml --tags postfix

# Install only Roundcube
ansible-playbook site.yml --tags roundcube

# Install web components only
ansible-playbook site.yml --tags web,roundcube
```

### 4. Check Playbook Syntax

```bash
ansible-playbook site.yml --check --diff
```

## Post-Installation

### 1. Access Roundcube

Visit: `https://mail.example.com/mail`

Login with any of the configured email accounts from your inventory.

### 2. Test Email Functionality

1. **Send Test Email**: Use Roundcube to send an email to an external address
2. **Receive Test Email**: Send an email to one of your configured accounts from an external provider

### 3. Email Client Configuration

For external email clients (Outlook, Thunderbird, etc.):

- **IMAP Server**: `mail.example.com:993` (SSL/TLS)
- **POP3 Server**: `mail.example.com:995` (SSL/TLS)  
- **SMTP Server**: `mail.example.com:587` (STARTTLS)
- **Authentication**: Use full email address and password

### 4. Firewall Verification

The playbook configures UFW with the following ports:

- `22`: SSH
- `25`: SMTP
- `80`: HTTP (redirects to HTTPS)
- `443`: HTTPS
- `587`: SMTP Submission
- `993`: IMAPS
- `995`: POP3S

## Troubleshooting

### Localhost Development Issues

**Can't access webmail?**
```bash
# Check if services are running
sudo systemctl status apache2 postfix dovecot

# Check if ports are listening
sudo netstat -tlnp | grep -E ':(80|443|25|587|993|995)'

# Check /etc/hosts
grep localhost.local /etc/hosts
```

**Browser certificate warnings?**
- This is normal with self-signed certificates
- Click "Advanced" → "Accept Risk" in your browser
- For Chrome: type "thisisunsafe" on the warning page

**Services not starting?**
```bash
# Check detailed logs
sudo journalctl -u postfix -f
sudo journalctl -u dovecot -f
sudo journalctl -u apache2 -f

# Restart all services
sudo systemctl restart postfix dovecot apache2
```

### Production Troubleshooting

### Check Service Status

```bash
# Check all mail services
sudo systemctl status postfix dovecot apache2

# View service logs
sudo journalctl -u postfix -f
sudo journalctl -u dovecot -f
```

### Test SMTP Connection

```bash
# Test SMTP connectivity
telnet mail.example.com 587

# Test IMAP connectivity  
openssl s_client -connect mail.example.com:993
```

### Roundcube Logs

```bash
# Check Roundcube logs
sudo tail -f /var/log/roundcube/errors.log

# Check Apache logs
sudo tail -f /var/log/apache2/example.com_error.log
```

### Database Issues

```bash
# Check SQLite database
sudo -u www-data sqlite3 /var/lib/roundcube/sqlite.db ".tables"

# Reinitialize database if needed
sudo rm /var/lib/roundcube/sqlite.db
sudo -u www-data sqlite3 /var/lib/roundcube/sqlite.db < /usr/share/roundcube/SQL/sqlite.initial.sql
```

## Security Considerations

1. **Strong Passwords**: Use strong, unique passwords for email accounts
2. **SSL Certificates**: Keep SSL certificates updated (Let's Encrypt auto-renewal)
3. **Firewall**: Only necessary ports are opened
4. **Updates**: Regularly update the system and mail components
5. **Backup**: Implement regular backups of mail data and configurations

## Backup Strategy

### Mail Data Backup

```bash
# Backup mail directories
sudo tar -czf mail-backup-$(date +%Y%m%d).tar.gz /var/mail/vhosts/

# Backup Roundcube database
sudo cp /var/lib/roundcube/sqlite.db roundcube-backup-$(date +%Y%m%d).db
```

### Configuration Backup

```bash
# Backup mail server configurations
sudo tar -czf mail-config-backup-$(date +%Y%m%d).tar.gz \
    /etc/postfix/ \
    /etc/dovecot/ \
    /etc/roundcube/ \
    /etc/apache2/sites-available/
```

## Customization

### Adding More Email Accounts

1. Edit `inventories/production.yml`
2. Add new entries to the `mail_users` list
3. Re-run the playbook: `ansible-playbook site.yml --tags dovecot`

### Custom Roundcube Configuration

Edit `roles/roundcube/templates/config.inc.php.j2` to customize Roundcube settings.

### Additional Security

Consider implementing:

- Fail2ban for intrusion detection
- SPF, DKIM, and DMARC records
- Regular security updates
- Mail filtering and spam protection

## License

This playbook is provided as-is under the MIT License.

## Support

For issues related to the original setup process, refer to the [Vultr documentation](https://docs.vultr.com/how-to-install-postfix-dovecot-and-roundcube-on-ubuntu-20-04).

For Ansible-specific issues, check the troubleshooting section above or consult the Ansible documentation.