#!/bin/bash

# Server setup script for Telegram Mini App deployment
# Run as root: curl -sSL https://raw.githubusercontent.com/your-repo/quickstart-telegram-miniapp-supabase/main/infra/scripts/server-setup.sh | bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
PROJECT_SLUG=${PROJECT_SLUG:-"telegram-miniapp"}
PROJECT_DIR="/opt/$PROJECT_SLUG"
DOCKER_COMPOSE_VERSION="2.21.0"

log_info "Starting server setup for Telegram Mini App..."

# Update system
log_info "Updating system packages..."
apt-get update && apt-get upgrade -y

# Install required packages
log_info "Installing required packages..."
apt-get install -y \
    curl \
    wget \
    git \
    nano \
    htop \
    ufw \
    fail2ban \
    unattended-upgrades \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    certbot \
    python3-certbot-nginx

# Install Docker
log_info "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add docker group and current user
    groupadd -f docker
    usermod -aG docker $USER
    
    log_success "Docker installed successfully"
else
    log_warning "Docker is already installed"
fi

# Install Docker Compose (standalone)
log_info "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    log_success "Docker Compose installed successfully"
else
    log_warning "Docker Compose is already installed"
fi

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Configure firewall
log_info "Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Configure fail2ban
log_info "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
EOF

systemctl enable fail2ban
systemctl restart fail2ban

# Configure automatic updates
log_info "Configuring automatic security updates..."
cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# Create project directory
log_info "Creating project directory..."
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create deploy user (if not exists)
if ! id "deploy" &>/dev/null; then
    log_info "Creating deploy user..."
    useradd -m -s /bin/bash deploy
    usermod -aG docker deploy
    
    # Setup SSH key for deploy user (placeholder)
    log_warning "Remember to add your SSH public key to /home/deploy/.ssh/authorized_keys"
    mkdir -p /home/deploy/.ssh
    chmod 700 /home/deploy/.ssh
    chown deploy:deploy /home/deploy/.ssh
    
    # Allow deploy user to restart docker services without password
    echo "deploy ALL=(ALL) NOPASSWD: /usr/bin/docker-compose, /usr/bin/docker" >> /etc/sudoers
fi

# Set project directory permissions
chown -R deploy:deploy "$PROJECT_DIR"

# Create nginx log directory
mkdir -p /var/log/nginx
chown -R www-data:www-data /var/log/nginx

# Create systemd service for the application
log_info "Creating systemd service..."
cat > /etc/systemd/system/telegram-miniapp.service << EOF
[Unit]
Description=Telegram Mini App
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/local/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.prod.yml down
TimeoutStartSec=0
User=deploy
Group=docker

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable telegram-miniapp.service

# Setup log rotation
log_info "Setting up log rotation..."
cat > /etc/logrotate.d/telegram-miniapp << EOF
/var/log/nginx/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        docker kill --signal=USR1 \$(docker ps -q --filter "name=tma-nginx") 2>/dev/null || true
    endscript
}
EOF

# Install Node.js (for running migration scripts if needed)
log_info "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Create backup directory
mkdir -p /opt/backups
chown deploy:deploy /opt/backups

# Setup basic monitoring (optional)
log_info "Setting up basic system monitoring..."
cat > /usr/local/bin/system-monitor.sh << 'EOF'
#!/bin/bash
# Basic system monitoring script

THRESHOLD_CPU=80
THRESHOLD_MEMORY=80
THRESHOLD_DISK=90

# Check CPU usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
if (( $(echo "$CPU_USAGE > $THRESHOLD_CPU" | bc -l) )); then
    echo "High CPU usage: ${CPU_USAGE}%"
fi

# Check memory usage
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
if [ "$MEMORY_USAGE" -gt "$THRESHOLD_MEMORY" ]; then
    echo "High memory usage: ${MEMORY_USAGE}%"
fi

# Check disk usage
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt "$THRESHOLD_DISK" ]; then
    echo "High disk usage: ${DISK_USAGE}%"
fi

# Check Docker containers
STOPPED_CONTAINERS=$(docker ps -a --filter "status=exited" --format "{{.Names}}" | wc -l)
if [ "$STOPPED_CONTAINERS" -gt 0 ]; then
    echo "Warning: $STOPPED_CONTAINERS containers are stopped"
fi
EOF

chmod +x /usr/local/bin/system-monitor.sh

# Add monitoring to crontab
(crontab -u deploy -l 2>/dev/null; echo "*/15 * * * * /usr/local/bin/system-monitor.sh") | crontab -u deploy -

# Print setup summary
log_success "Server setup completed!"
echo ""
echo "========================================="
echo "         Setup Summary"
echo "========================================="
echo "✅ System updated and secured"
echo "✅ Docker and Docker Compose installed"
echo "✅ Firewall configured (ports 22, 80, 443)"
echo "✅ Fail2ban configured"
echo "✅ Automatic security updates enabled"
echo "✅ Project directory: $PROJECT_DIR"
echo "✅ Deploy user created"
echo "✅ Log rotation configured"
echo "✅ System monitoring enabled"
echo ""
echo "Next steps:"
echo "1. Add your SSH public key to /home/deploy/.ssh/authorized_keys"
echo "2. Configure your domain DNS to point to this server"
echo "3. Run the SSL setup script: ./infra/scripts/certbot-init.sh"
echo "4. Deploy your application using GitHub Actions"
echo ""
echo "🎉 Your server is ready for deployment!"
