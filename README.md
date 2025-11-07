# Nextcloud + Postfix Docker Email Setup

This repository contains a Docker Compose setup for running Postfix SMTP server to work with Nextcloud snap installation on Ubuntu. This allows Nextcloud to send emails (notifications, password resets, etc.) through a local SMTP server.

## 🎯 What This Setup Provides

- ✅ **Complete email infrastructure** with SMTP relay and mailbox delivery
- ✅ **Postfix SMTP server** for sending emails from Nextcloud
- ✅ **Full mailserver** with IMAP support for reading emails
- ✅ **Roundcube webmail** interface for email management
- ✅ **Email client support** (Evolution, Thunderbird, etc.)
- ✅ **No authentication required** for local SMTP connections
- ✅ **Working email delivery pipeline** from Nextcloud to inbox
- ✅ **Proper domain routing** and virtual mailbox handling

## 📋 Requirements

- Ubuntu 20.04+ (or any system with Docker and snap)
- Docker and Docker Compose installed
- Nextcloud installed via snap (see installation guide below)
- sudo/root access
- Basic understanding of email delivery concepts

## 🔧 Prerequisites Setup

### 1. Install Nextcloud via Snap

If you don't have Nextcloud installed yet, here's how to install it using snap:

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install snapd (if not already installed)
sudo apt install snapd -y

# Install Nextcloud snap
sudo snap install nextcloud

# Check installation status
sudo snap list | grep nextcloud

# Get initial admin credentials
sudo nextcloud.occ maintenance:install --admin-user admin --admin-pass admin123

# Or create admin account interactively
sudo nextcloud.manual-install
```

### 2. Configure Nextcloud Basic Settings

```bash
# Set trusted domains (replace YOUR_SERVER_IP with actual IP)
sudo nextcloud.occ config:system:set trusted_domains 0 --value=localhost
sudo nextcloud.occ config:system:set trusted_domains 1 --value=127.0.0.1
sudo nextcloud.occ config:system:set trusted_domains 2 --value=YOUR_SERVER_IP

# Enable pretty URLs (optional)
sudo nextcloud.occ config:system:set htaccess.RewriteBase --value="/"
sudo nextcloud.occ maintenance:update:htaccess

# Check Nextcloud status
sudo nextcloud.occ status
```

### 3. Access Nextcloud Web Interface

```bash
# Nextcloud will be available at:
echo "Nextcloud URL: http://localhost (port 80)"
echo "Admin username: admin"
echo "Admin password: admin123"  # or whatever you set during install

# To find the actual URL if using a server:
ip addr show | grep "inet " | grep -v 127.0.0.1
```

### 4. Install Docker and Docker Compose

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Verify installations
docker --version
docker compose version

# Log out and back in for group changes to take effect
```

## 🚀 Quick Start

### 1. Ensure Prerequisites are Met

Make sure you have completed the prerequisites setup above:
- ✅ Nextcloud installed via snap and accessible
- ✅ Docker and Docker Compose installed
- ✅ Admin access to both Nextcloud and system

### 2. Clone and Start Email Services

```bash
git clone <this-repo>
cd mail

# Create required directories and account file
mkdir -p mailserver/config
echo "admin@mail.nextcloud.local|{PLAIN}password123" > mailserver/config/postfix-accounts.cf

# Start all email services
docker compose up -d

# Verify services are running
docker ps --filter "name=nextcloud"
```

### 3. Configure Nextcloud Email Settings

The Nextcloud configuration is set automatically via OCC commands, but here are the key settings:

```bash
sudo nextcloud.occ config:system:set mail_smtpmode --value=smtp
sudo nextcloud.occ config:system:set mail_smtphost --value=localhost
sudo nextcloud.occ config:system:set mail_smtpport --value=2525
sudo nextcloud.occ config:system:set mail_smtpauth --value=false --type=boolean
sudo nextcloud.occ config:system:set mail_smtpsecure --value=""
sudo nextcloud.occ config:system:set mail_from_address --value=admin
sudo nextcloud.occ config:system:set mail_domain --value=mail.nextcloud.local
```

### 4. Test Email Configuration

1. **Via Nextcloud Web Interface:**
   - Login to Nextcloud as admin
   - Go to Settings → Administration → Basic settings
   - In "Email server" section, click **"Send email"** button
   - Check if test email is sent successfully

2. **Via Roundcube Web Interface:**
   - Open browser to `http://localhost:8080`
   - Login with `admin@mail.nextcloud.local` / `password123`
   - Check inbox for delivered emails

3. **Via Command Line:**
   ```bash
   # Send test email via Nextcloud
   sudo nextcloud.occ user:welcome admin
   
   # Check mail delivery in logs
   docker logs nextcloud-mailserver --tail 10
   
   # Verify no emails stuck in queue
   docker exec nextcloud-postfix mailq
   ```

## 🔧 Configuration Details

### Docker Compose Services

- **nextcloud-postfix**: Main SMTP server container
  - Port `2525` → Container port `25` (SMTP)
  - Port `2587` → Container port `587` (Submission)
  - Port `2465` → Container port `465` (SMTPS)

- **nextcloud-mailserver**: Complete mail server with IMAP/POP3
  - Port `3025` → Container port `25` (SMTP)
  - Port `3143` → Container port `143` (IMAP)
  - Port `3993` → Container port `993` (IMAPS)
  - Port `3110` → Container port `110` (POP3)
  - Port `3995` → Container port `995` (POP3S)

- **nextcloud-roundcube**: Web-based email client
  - Port `8080` → Container port `80` (Web interface)

### Key Configuration Features

- **Email Flow**: Nextcloud → Basic Postfix (relay) → Mailserver (delivery) → Dovecot (storage) → Roundcube (web access)
- **Hostname**: Basic Postfix uses `postfix-server`, Mailserver uses `mailserver.nextcloud.local`
- **Domain Routing**: `mail.nextcloud.local` routed via transport maps to avoid conflicts
- **Virtual Domains**: Mailserver handles `mail.nextcloud.local` with virtual mailbox delivery
- **Network**: Bridge network with proper hostname resolution between containers
- **Authentication**: Disabled for localhost connections, enabled for IMAP/webmail access
- **Message Size**: 25MB limit
- **Storage**: Persistent volumes for mailbox data

### Nextcloud Integration

- **SMTP Host**: `localhost`
- **SMTP Port**: `2525`
- **Authentication**: None required
- **Encryption**: None (secure for local connections)
- **From Address**: `admin@mail.nextcloud.local`

## 📧 Email Operations

### Send a Test Email via Nextcloud

Use the Nextcloud admin interface to send test emails:
1. Settings → Administration → Basic settings
2. Scroll to "Email server" section
3. Click "Send email" button

### Check Mail Queue

```bash
# Show current mail queue
docker exec nextcloud-postfix postqueue -p

# View specific email content
docker exec nextcloud-postfix postcat -vq QUEUE_ID

# Clear mail queue (if needed)
docker exec nextcloud-postfix postsuper -d ALL
```

### Monitor Real-time Logs

```bash
# Follow Postfix logs
docker logs nextcloud-postfix --follow

# Show recent logs
docker logs nextcloud-postfix --tail 20
```

## 🔍 Troubleshooting

### Common Issues and Solutions

#### 1. "Invalid SMTP password" Error
- **Fixed**: Authentication is disabled in both Nextcloud and Postfix
- **Verify**: `sudo nextcloud.occ config:system:get mail_smtpauth` should return `false`

#### 2. Hostname Resolution Warnings
- **Fixed**: Added `extra_hosts` mapping in docker-compose.yml
- **Check logs**: Should not see "hostname ubuntu does not resolve" warnings

#### 3. SSL/TLS Errors
- **Fixed**: Completely disabled TLS with `POSTFIX_smtpd_tls_security_level: none`
- **Verify**: No SSL handshake errors in logs

#### 4. Email Stuck in Queue - RESOLVED! ✅
- **Previous Issue**: Emails were queued but not delivered to mailbox
- **Root Cause**: Domain conflict - `mail.nextcloud.local` was in both `mydestination` and `virtual_mailbox_domains`
- **Solution Applied**: 
  - Changed mailserver hostname from `mail.nextcloud.local` to `mailserver.nextcloud.local`
  - Configured transport maps in basic Postfix to relay `mail.nextcloud.local` to mailserver
  - Removed virtual mailbox configuration from basic Postfix
- **Current Status**: Emails now flow properly through the relay to delivery ✅

#### 5. Virtual Domain Configuration Conflict - RESOLVED! ✅
- **Error**: "do not list domain mail.nextcloud.local in BOTH mydestination and virtual_mailbox_domains"
- **Solution**: Fixed hostname conflict and proper transport configuration
- **Verification**: Check logs show successful delivery with `status=sent` messages

#### 6. Mailserver Won't Start (Dovecot Account Error)
- **Error**: "You need at least one mail account to start Dovecot"
- **Solution**: Ensure `/mailserver/config/postfix-accounts.cf` exists with at least one account:
  ```bash
  echo "admin@mail.nextcloud.local|{PLAIN}password123" > ./mailserver/config/postfix-accounts.cf
  docker compose restart mailserver
  ```

#### 7. Evolution/Email Client Can't Connect
- **Check IMAP**: `telnet localhost 3143`
- **Verify account**: `docker exec nextcloud-mailserver setup email list`
- **Check logs**: `docker logs nextcloud-mailserver --tail 20`

#### 8. Nextcloud Snap Issues
- **Service not starting**: `sudo snap start nextcloud`
- **Check snap logs**: `sudo snap logs nextcloud -f`
- **Restart Nextcloud**: `sudo snap restart nextcloud`
- **Check snap status**: `sudo snap list | grep nextcloud`
- **Access snap shell**: `sudo snap run --shell nextcloud`

#### 9. Nextcloud Web Interface Not Accessible
- **Check if running**: `sudo netstat -tlnp | grep :80`
- **Restart Apache**: `sudo nextcloud.occ maintenance:mode --off`
- **Check trusted domains**: `sudo nextcloud.occ config:system:get trusted_domains`
- **Reset admin password**: `sudo nextcloud.occ user:resetpassword admin`

### Verify Email Delivery Pipeline

```bash
# Send test email from Nextcloud
sudo nextcloud.occ user:welcome admin

# Check successful delivery in mailserver logs (should show "Saved")
docker logs nextcloud-mailserver --tail 5

# Verify queue is empty (emails delivered, not stuck)
docker exec nextcloud-postfix mailq

# Check Roundcube web interface
echo "Access Roundcube at: http://localhost:8080"
echo "Login: admin@mail.nextcloud.local / password123"
```

### Check Configuration Status

```bash
# Verify Nextcloud SMTP settings
echo "=== NEXTCLOUD SMTP CONFIG ==="
echo "Host: $(sudo nextcloud.occ config:system:get mail_smtphost)"
echo "Port: $(sudo nextcloud.occ config:system:get mail_smtpport)"
echo "Auth: $(sudo nextcloud.occ config:system:get mail_smtpauth)"
echo "TLS: $(sudo nextcloud.occ config:system:get mail_smtpsecure)"

# Verify Nextcloud status and access
echo "=== NEXTCLOUD STATUS ==="
echo "Nextcloud Status: $(sudo nextcloud.occ status --output=plain)"
echo "Trusted Domains: $(sudo nextcloud.occ config:system:get trusted_domains --output=plain)"

# Verify Postfix settings
echo "=== POSTFIX CONFIG ==="
echo "Basic Postfix Hostname: $(docker exec nextcloud-postfix postconf -h myhostname 2>/dev/null)"
echo "Mailserver Hostname: $(docker exec nextcloud-mailserver postconf -h myhostname 2>/dev/null)"
echo "Transport Maps: $(docker exec nextcloud-postfix postconf -h transport_maps 2>/dev/null)"
```

### Test SMTP Connectivity

```bash
# Test basic connection
telnet localhost 2525

# In telnet session:
# EHLO localhost
# QUIT

# Check container health
docker ps --filter "name=nextcloud"

# Check Nextcloud snap health
sudo nextcloud.occ status
sudo snap services nextcloud
```

### Useful Nextcloud Snap Commands

```bash
# Nextcloud management
sudo nextcloud.occ status                    # Check Nextcloud status
sudo nextcloud.occ user:list                 # List all users
sudo nextcloud.occ app:list                  # List installed apps
sudo nextcloud.occ maintenance:mode --on     # Enable maintenance mode
sudo nextcloud.occ maintenance:mode --off    # Disable maintenance mode

# Configuration management
sudo nextcloud.occ config:system:get trusted_domains    # Show trusted domains
sudo nextcloud.occ config:list system                   # Show all system config
sudo nextcloud.occ mail:test admin@mail.nextcloud.local # Test email (if app installed)

# Snap service management
sudo snap start nextcloud                    # Start Nextcloud
sudo snap stop nextcloud                     # Stop Nextcloud  
sudo snap restart nextcloud                  # Restart Nextcloud
sudo snap logs nextcloud -f                  # Follow Nextcloud logs
sudo snap refresh nextcloud                  # Update Nextcloud

# File locations
echo "Nextcloud data: $(sudo nextcloud.occ config:system:get datadirectory)"
echo "Nextcloud config: /var/snap/nextcloud/current/nextcloud/config/"
echo "Nextcloud logs: /var/snap/nextcloud/current/logs/"
```

## 📁 Directory Structure

```
mail/
├── .gitignore                  # Git ignore file for sensitive data
├── docker-compose.yml          # Main Docker Compose configuration
├── README.md                   # This documentation
├── Makefile                    # Build automation commands
├── mailserver/
│   ├── config/
│   │   ├── postfix-accounts.cf # Email accounts (gitignored)
│   │   └── dovecot-quotas.cf   # Email quotas
│   └── mail-data/              # Mailbox storage (gitignored)
├── dovecot/
│   └── config/                 # Dovecot configuration
└── postfix/
    └── sasl/                   # SASL configuration
```

## 🔐 Security Notes

### Why No Authentication/TLS?

This setup **intentionally disables** authentication and TLS because:

1. **Local Connection**: Nextcloud and Postfix run on the same server
2. **Network Isolation**: Traffic never leaves the local machine
3. **Docker Network**: Communications happen within isolated Docker network
4. **Snap Security**: Nextcloud snap provides additional isolation
5. **No External Access**: SMTP ports are not exposed to external networks (in production)

### Production Considerations

For production deployments:
- Enable TLS certificates for external connections
- Implement proper authentication for remote clients
- Configure firewall rules appropriately
- Use real domain names with proper DNS records
- Consider email delivery services for external recipients

### Current Email Delivery Status ✅

**WORKING**: Complete email infrastructure is now functional!

- ✅ **Nextcloud** → **Basic Postfix** (SMTP relay via localhost:2525)
- ✅ **Basic Postfix** → **Mailserver** (transport maps route mail.nextcloud.local)  
- ✅ **Mailserver** → **Dovecot** (virtual mailbox delivery to user accounts)
- ✅ **Roundcube** ← **Dovecot** (IMAP reading via localhost:3143)

**Access Points:**
- **Roundcube Web**: http://localhost:8080 (admin@mail.nextcloud.local / password123)
- **Evolution IMAP**: localhost:3143 (admin@mail.nextcloud.local / password123)
- **Nextcloud SMTP**: localhost:2525 (no authentication required)

**Verification Commands:**
```bash
# Send test email
sudo nextcloud.occ user:welcome admin

# Confirm delivery (should show "Saved" message)
docker logs nextcloud-mailserver --tail 3

# Check no emails stuck in queue
docker exec nextcloud-postfix mailq
```

## 🚧 Advanced Configuration

### Enable Real Email Delivery

To deliver emails to external addresses, configure a relay host:

```yaml
environment:
  POSTFIX_RELAYHOST: "[smtp.gmail.com]:587"
  POSTFIX_SMTP_AUTH_username: "your-email@gmail.com"
  POSTFIX_SMTP_AUTH_password: "your-app-password"
```

### Add Email Client Support

✅ **ALREADY CONFIGURED**: The setup includes complete IMAP support!

#### Option 1: Using the Full Mailserver ✅ (WORKING)

The docker-compose.yml includes a complete mailserver with IMAP support that is **actively working**:

```bash
# Start both services
docker compose up -d

# Check mailserver status
docker logs nextcloud-mailserver --tail 10
```

#### Access Methods:

**Option A: Web Interface (Roundcube)**
1. Open browser: `http://localhost:8080`
2. Login with:
   - Username: `admin@mail.nextcloud.local`
   - Password: `password123`

**Option B: Email Client (Evolution)**
```bash
# Configure Evolution with:
# IMAP Server: localhost:3143
# Username: admin@mail.nextcloud.local  
# Password: password123
# SMTP Server: localhost:2525 (no auth needed)
```

#### Option 2: ✅ ALREADY CONFIGURED - Nextcloud Delivers to Mailserver

**Current Status**: Nextcloud is **already configured** to deliver emails to the mailserver automatically!

The email flow is working perfectly:
- Nextcloud sends to Basic Postfix (localhost:2525)
- Basic Postfix relays to Mailserver via transport maps
- Mailserver delivers to virtual mailboxes
- Users can read emails via Roundcube or IMAP clients

No additional configuration needed! 🎉

```bash
# Current working configuration (already applied):
# Nextcloud SMTP: localhost:2525 (basic Postfix)
# Basic Postfix relays mail.nextcloud.local → Mailserver:25
# Mailserver delivers to virtual mailboxes
# IMAP access: localhost:3143
```

#### Email Account Details

- **Email Address**: admin@mail.nextcloud.local
- **Password**: password123
- **IMAP Server**: localhost:3143 (no encryption)
- **SMTP Server**: localhost:2525 (no authentication)

#### Manage Email Accounts

```bash
# Add new email account
docker exec nextcloud-mailserver setup email add user@mail.nextcloud.local newpassword

# List accounts
docker exec nextcloud-mailserver setup email list

# Delete account  
docker exec nextcloud-mailserver setup email del user@mail.nextcloud.local
```

## 📝 Changelog

### v2.0 (Current) - Complete Working Email Infrastructure ✅
- ✅ Complete email delivery pipeline from Nextcloud to mailbox
- ✅ Transport maps configuration for proper domain routing  
- ✅ Virtual mailbox delivery working (emails reach user inboxes)
- ✅ Roundcube web interface for email reading
- ✅ IMAP support for email clients (Evolution, Thunderbird)
- ✅ Resolved domain conflict issues (hostname separation)
- ✅ Fixed virtual delivery agent configuration
- ✅ Added .gitignore for sensitive configuration files
- ✅ Updated documentation with troubleshooting solutions

### v1.0 (Previous)
- ✅ Basic Postfix SMTP server for Nextcloud
- ✅ No authentication for local connections
- ✅ Hostname resolution fixed
- ✅ TLS disabled for localhost
- ✅ Working email queue and monitoring
- ✅ Complete integration with Nextcloud snap

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

MIT License - feel free to use and modify as needed.

## 👨‍💻 Author

Created for Nextcloud + Ubuntu snap email integration.
