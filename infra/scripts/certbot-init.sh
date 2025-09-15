#!/bin/bash

# SSL certificate setup script using Let's Encrypt
# Usage: ./certbot-init.sh domain1.com domain2.com email@example.com

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
    exit 1
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_error "This script should not be run as root. Use a user with sudo privileges."
fi

# Parse arguments
if [ $# -lt 3 ]; then
    log_error "Usage: $0 <api_domain> <app_domain> <email>"
fi

API_DOMAIN="$1"
APP_DOMAIN="$2"
EMAIL="$3"
PROJECT_SLUG=${PROJECT_SLUG:-"telegram-miniapp"}
PROJECT_DIR="/opt/$PROJECT_SLUG"

log_info "Setting up SSL certificates for:"
log_info "  API Domain: $API_DOMAIN"
log_info "  App Domain: $APP_DOMAIN"
log_info "  Email: $EMAIL"

# Validate domains are pointing to this server
log_info "Validating DNS configuration..."

check_dns() {
    local domain=$1
    local server_ip=$(curl -s ifconfig.me)
    local domain_ip=$(dig +short $domain | tail -1)
    
    if [ "$server_ip" != "$domain_ip" ]; then
        log_warning "DNS for $domain ($domain_ip) doesn't match server IP ($server_ip)"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Please configure DNS before proceeding"
        fi
    else
        log_success "DNS for $domain is correctly configured"
    fi
}

check_dns "$API_DOMAIN"
check_dns "$APP_DOMAIN"

# Create SSL directories
log_info "Creating SSL directories..."
sudo mkdir -p /etc/nginx/ssl/{$API_DOMAIN,$APP_DOMAIN}
sudo mkdir -p $PROJECT_DIR/infra/ssl/{$API_DOMAIN,$APP_DOMAIN}

# Create temporary nginx config for initial verification
log_info "Creating temporary nginx configuration..."
sudo tee /etc/nginx/sites-available/temp-ssl > /dev/null << EOF
server {
    listen 80;
    server_name $API_DOMAIN $APP_DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/temp-ssl /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo mkdir -p /var/www/certbot

# Install nginx if not present
if ! command -v nginx &> /dev/null; then
    log_info "Installing nginx..."
    sudo apt-get update
    sudo apt-get install -y nginx
fi

# Test and restart nginx
sudo nginx -t && sudo systemctl reload nginx

# Obtain SSL certificates
log_info "Obtaining SSL certificates from Let's Encrypt..."

# Certificate for API domain
log_info "Requesting certificate for $API_DOMAIN..."
sudo certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d $API_DOMAIN

# Certificate for App domain
log_info "Requesting certificate for $APP_DOMAIN..."
sudo certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d $APP_DOMAIN

# Copy certificates to project directory for Docker
log_info "Copying certificates to project directory..."
sudo cp -r /etc/letsencrypt/live/$API_DOMAIN/* $PROJECT_DIR/infra/ssl/$API_DOMAIN/
sudo cp -r /etc/letsencrypt/live/$APP_DOMAIN/* $PROJECT_DIR/infra/ssl/$APP_DOMAIN/

# Set proper permissions
sudo chown -R deploy:deploy $PROJECT_DIR/infra/ssl/
sudo chmod -R 644 $PROJECT_DIR/infra/ssl/
sudo chmod 600 $PROJECT_DIR/infra/ssl/$API_DOMAIN/privkey.pem
sudo chmod 600 $PROJECT_DIR/infra/ssl/$APP_DOMAIN/privkey.pem

# Create certificate renewal script
log_info "Setting up automatic certificate renewal..."
sudo tee /usr/local/bin/renew-certs.sh > /dev/null << EOF
#!/bin/bash

# Renew certificates
certbot renew --quiet

# Copy renewed certificates to project directory
cp -r /etc/letsencrypt/live/$API_DOMAIN/* $PROJECT_DIR/infra/ssl/$API_DOMAIN/
cp -r /etc/letsencrypt/live/$APP_DOMAIN/* $PROJECT_DIR/infra/ssl/$APP_DOMAIN/

# Set permissions
chown -R deploy:deploy $PROJECT_DIR/infra/ssl/
chmod -R 644 $PROJECT_DIR/infra/ssl/
chmod 600 $PROJECT_DIR/infra/ssl/$API_DOMAIN/privkey.pem
chmod 600 $PROJECT_DIR/infra/ssl/$APP_DOMAIN/privkey.pem

# Reload nginx in docker
docker kill --signal=USR1 \$(docker ps -q --filter "name=tma-nginx") 2>/dev/null || true

echo "Certificates renewed successfully"
EOF

sudo chmod +x /usr/local/bin/renew-certs.sh

# Add to crontab for automatic renewal
(sudo crontab -l 2>/dev/null; echo "0 12 * * * /usr/local/bin/renew-certs.sh") | sudo crontab -

# Test certificate renewal
log_info "Testing certificate renewal..."
sudo certbot renew --dry-run

# Create SSL parameter file for better security
sudo tee $PROJECT_DIR/infra/ssl/options-ssl-nginx.conf > /dev/null << EOF
# Mozilla Intermediate configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;

ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_session_tickets off;

# OCSP stapling
ssl_stapling on;
ssl_stapling_verify on;

# verify chain of trust of OCSP response using Root CA and Intermediate certs
ssl_trusted_certificate /path/to/root_CA_cert_plus_intermediates;

resolver 8.8.8.8;
EOF

# Remove temporary nginx config
sudo rm -f /etc/nginx/sites-enabled/temp-ssl
sudo rm -f /etc/nginx/sites-available/temp-ssl
sudo systemctl reload nginx

# Verify certificates
log_info "Verifying SSL certificates..."
openssl x509 -in $PROJECT_DIR/infra/ssl/$API_DOMAIN/cert.pem -text -noout | grep -A 2 "Subject:"
openssl x509 -in $PROJECT_DIR/infra/ssl/$APP_DOMAIN/cert.pem -text -noout | grep -A 2 "Subject:"

log_success "SSL certificates setup completed!"
echo ""
echo "========================================="
echo "         SSL Setup Summary"
echo "========================================="
echo "✅ SSL certificates obtained for both domains"
echo "✅ Certificates copied to project directory"
echo "✅ Automatic renewal configured (runs daily at 12:00)"
echo "✅ Security parameters configured"
echo ""
echo "Certificate locations:"
echo "  $PROJECT_DIR/infra/ssl/$API_DOMAIN/"
echo "  $PROJECT_DIR/infra/ssl/$APP_DOMAIN/"
echo ""
echo "Next steps:"
echo "1. Deploy your application"
echo "2. Test HTTPS access:"
echo "   - https://$API_DOMAIN/health"
echo "   - https://$APP_DOMAIN"
echo ""
echo "🔒 Your domains are now secured with HTTPS!"
