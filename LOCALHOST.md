# 🏠 Localhost Mail Server - Quick Start Guide

Perfect for learning mail server administration without needing a domain or real SSL certificates!

## 🚀 One-Command Setup

```bash
cd ansible
./deploy-localhost.sh
```

Choose option **1** for quick deploy - it handles everything automatically!

## 📧 What You Get

- **Complete Mail Server**: Postfix (SMTP) + Dovecot (IMAP/POP3) + Roundcube (Webmail)
- **Self-Signed SSL**: Automatically generated certificates
- **SQLite Database**: Lightweight database for Roundcube
- **Test Accounts**: Ready-to-use email accounts for testing

## 🌐 Access Points

After deployment:

- **Webmail Interface**: https://mail.localhost.local/mail
- **Alternative URL**: https://localhost/mail

### 📱 Email Client Settings

For Thunderbird, Outlook, or other mail clients:

- **IMAP Server**: mail.localhost.local:993 (SSL)
- **POP3 Server**: mail.localhost.local:995 (SSL)
- **SMTP Server**: mail.localhost.local:587 (STARTTLS)

### 👤 Test Accounts

- **admin@localhost.local** / password: `admin123`
- **test@localhost.local** / password: `test123`  
- **user@localhost.local** / password: `user123`

## 🔧 Useful Commands

```bash
# Test the setup
./test-localhost.sh

# Check service status
sudo systemctl status postfix dovecot apache2

# View logs
sudo journalctl -u postfix -f
sudo journalctl -u dovecot -f

# Restart services
sudo systemctl restart postfix dovecot apache2

# Test SMTP manually
telnet localhost 587
```

## ⚠️ Expected Warnings

1. **SSL Certificate Warning**: Your browser will warn about self-signed certificates
   - Click "Advanced" → "Accept Risk" or "Proceed to site"
   - In Chrome: type `thisisunsafe` on the warning page

2. **Domain Resolution**: Uses localhost.local which is automatically added to /etc/hosts

## 🎯 Learning Objectives

This setup lets you learn:

- Mail server architecture (MTA, MDA, Webmail)
- Postfix configuration (virtual domains, SMTP)
- Dovecot configuration (IMAP, POP3, authentication)
- Apache virtual host configuration
- SSL certificate management
- SQLite database administration
- Email troubleshooting

## 🔍 Troubleshooting

**Services won't start?**
```bash
sudo systemctl restart postfix dovecot apache2
./test-localhost.sh
```

**Can't access webmail?**
```bash
curl -k https://localhost/mail
grep localhost.local /etc/hosts
```

**Forgot test passwords?**
Check: `sudo cat /etc/dovecot/dovecot-users`

## 🎓 Next Steps

Once comfortable with localhost:

1. Try the production deployment with a real domain
2. Set up SPF, DKIM, and DMARC records
3. Add anti-spam filters
4. Implement backup strategies
5. Configure mail client apps

## 📚 Files Reference

- **Main Playbook**: `site.yml`
- **Localhost Config**: `inventories/localhost.yml` 
- **Deploy Script**: `deploy-localhost.sh`
- **Test Script**: `test-localhost.sh`
- **SSL Certificates**: `/etc/ssl/mailserver/`
- **Mail Storage**: `/var/mail/vhosts/localhost.local/`
- **Roundcube DB**: `/var/lib/roundcube/sqlite.db`

Happy learning! 🎉