#!/bin/bash

# Manual deployment script for Telegram Mini App
# Usage: ./deploy.sh [environment]

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

# Configuration
ENVIRONMENT="${1:-production}"
PROJECT_SLUG="${PROJECT_SLUG:-telegram-miniapp}"
PROJECT_DIR="/opt/$PROJECT_SLUG"

log_info "Starting deployment for environment: $ENVIRONMENT"

# Check if we're in the project root
if [ ! -f "docker-compose.prod.yml" ] && [ ! -f "package.json" ]; then
    log_error "Please run this script from the project root directory"
fi

# Load environment variables
if [ -f ".env.${ENVIRONMENT}" ]; then
    log_info "Loading environment variables from .env.${ENVIRONMENT}"
    set -a
    source ".env.${ENVIRONMENT}"
    set +a
elif [ -f ".env" ]; then
    log_info "Loading environment variables from .env"
    set -a
    source ".env"
    set +a
else
    log_warning "No environment file found. Using system environment variables."
fi

# Validate required environment variables
required_vars=(
    "API_DOMAIN"
    "APP_DOMAIN"
    "BOT_TOKEN"
    "WEBHOOK_SECRET"
    "SUPABASE_URL"
    "SUPABASE_SERVICE_ROLE_KEY"
    "REGISTRY"
    "PROJECT_SLUG"
)

log_info "Validating environment variables..."
for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
        log_error "Required environment variable $var is not set"
    fi
done

log_success "All required environment variables are set"

# Pre-deployment checks
log_info "Running pre-deployment checks..."

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running or not accessible"
fi

# Check if images exist in registry
check_image() {
    local image=$1
    log_info "Checking if image exists: $image"
    
    if ! docker manifest inspect "$image" > /dev/null 2>&1; then
        log_warning "Image $image not found in registry. Building locally..."
        return 1
    fi
    return 0
}

API_IMAGE="${REGISTRY}/${PROJECT_SLUG}/api:latest"
WEB_IMAGE="${REGISTRY}/${PROJECT_SLUG}/web:latest"

# Build images if they don't exist in registry
if ! check_image "$API_IMAGE" || ! check_image "$WEB_IMAGE"; then
    log_info "Building images locally..."
    
    # Build API image
    log_info "Building API image..."
    docker build -f apps/api/Dockerfile -t "$API_IMAGE" .
    
    # Build Web image
    log_info "Building Web image..."
    docker build -f apps/web/Dockerfile --build-arg VITE_API_DOMAIN="$API_DOMAIN" -t "$WEB_IMAGE" .
    
    log_success "Images built successfully"
fi

# Create nginx configurations from templates
log_info "Creating nginx configurations..."
mkdir -p infra/nginx/conf.d

envsubst '${API_DOMAIN} ${APP_DOMAIN}' < infra/nginx/conf.d/api.conf.template > infra/nginx/conf.d/api.conf
envsubst '${API_DOMAIN} ${APP_DOMAIN}' < infra/nginx/conf.d/web.conf.template > infra/nginx/conf.d/web.conf

log_success "Nginx configurations created"

# Pull latest images (if available in registry)
log_info "Pulling latest images from registry..."
docker-compose -f docker-compose.prod.yml pull || log_warning "Failed to pull some images, using local versions"

# Run database migrations
log_info "Running database migrations..."
if docker-compose -f docker-compose.prod.yml run --rm api npm run db:migrate; then
    log_success "Database migrations completed"
else
    log_warning "Database migrations failed or were skipped"
fi

# Start services
log_info "Starting services..."
docker-compose -f docker-compose.prod.yml up -d --remove-orphans

# Wait for services to be ready
log_info "Waiting for services to be ready..."
sleep 30

# Health checks
log_info "Running health checks..."

# Check API health
check_api_health() {
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "http://localhost:3001/health" > /dev/null; then
            log_success "API health check passed"
            return 0
        fi
        
        log_info "API health check attempt $attempt/$max_attempts failed, retrying in 10s..."
        sleep 10
        ((attempt++))
    done
    
    log_error "API health check failed after $max_attempts attempts"
    return 1
}

# Check Web health
check_web_health() {
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "http://localhost:8080/health" > /dev/null; then
            log_success "Web health check passed"
            return 0
        fi
        
        log_info "Web health check attempt $attempt/$max_attempts failed, retrying in 5s..."
        sleep 5
        ((attempt++))
    done
    
    log_error "Web health check failed after $max_attempts attempts"
    return 1
}

check_api_health
check_web_health

# Setup Telegram webhook
log_info "Setting up Telegram webhook..."
if curl -X POST "http://localhost:3001/api/webhook/set" \
     -H "Content-Type: application/json" \
     -f -s > /dev/null; then
    log_success "Telegram webhook configured successfully"
else
    log_warning "Failed to configure Telegram webhook. You may need to set it manually."
fi

# Show service status
log_info "Service status:"
docker-compose -f docker-compose.prod.yml ps

# Cleanup old images
log_info "Cleaning up old Docker images..."
docker image prune -f

log_success "Deployment completed successfully!"
echo ""
echo "========================================="
echo "         Deployment Summary"
echo "========================================="
echo "🚀 Application deployed successfully!"
echo ""
echo "🌐 URLs:"
echo "  Web App: https://$APP_DOMAIN"
echo "  API Health: https://$API_DOMAIN/health"
echo "  API Webhook: https://$API_DOMAIN/webhook"
echo ""
echo "🔍 Quick Tests:"
echo "  curl -f https://$API_DOMAIN/health"
echo "  curl -f https://$APP_DOMAIN/health"
echo ""
echo "📊 Monitor services:"
echo "  docker-compose -f docker-compose.prod.yml logs -f"
echo "  docker-compose -f docker-compose.prod.yml ps"
echo ""
echo "🎉 Your Telegram Mini App is now live!"

# Optional: Run a quick test
read -p "Run quick connectivity tests? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Running connectivity tests..."
    
    # Test API endpoint
    if curl -f -s "https://$API_DOMAIN/health" > /dev/null; then
        log_success "✅ API endpoint is accessible"
    else
        log_warning "❌ API endpoint is not accessible"
    fi
    
    # Test Web endpoint
    if curl -f -s "https://$APP_DOMAIN/" > /dev/null; then
        log_success "✅ Web app is accessible"
    else
        log_warning "❌ Web app is not accessible"
    fi
    
    # Test SSL certificates
    if openssl s_client -connect "$API_DOMAIN:443" -servername "$API_DOMAIN" < /dev/null 2>/dev/null | openssl x509 -noout -dates; then
        log_success "✅ SSL certificate for API domain is valid"
    else
        log_warning "❌ SSL certificate for API domain has issues"
    fi
    
    if openssl s_client -connect "$APP_DOMAIN:443" -servername "$APP_DOMAIN" < /dev/null 2>/dev/null | openssl x509 -noout -dates; then
        log_success "✅ SSL certificate for App domain is valid"
    else
        log_warning "❌ SSL certificate for App domain has issues"
    fi
fi
