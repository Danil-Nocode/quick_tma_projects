#!/bin/bash

# Backup script for Telegram Mini App
# Usage: ./backup.sh [backup_name]

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
BACKUP_NAME="${1:-$(date +%Y%m%d_%H%M%S)}"
PROJECT_SLUG="${PROJECT_SLUG:-telegram-miniapp}"
PROJECT_DIR="/opt/$PROJECT_SLUG"
BACKUP_DIR="/opt/backups"
BACKUP_PATH="$BACKUP_DIR/backup_$BACKUP_NAME"

log_info "Creating backup: $BACKUP_NAME"

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Backup project files
log_info "Backing up project files..."
tar -czf "$BACKUP_PATH/project_files.tar.gz" \
    -C "$PROJECT_DIR" \
    --exclude="node_modules" \
    --exclude="dist" \
    --exclude=".git" \
    --exclude="logs" \
    .

log_success "Project files backed up"

# Backup Docker images
log_info "Backing up Docker images..."
mkdir -p "$BACKUP_PATH/images"

# Get running images
RUNNING_IMAGES=$(docker-compose -f "$PROJECT_DIR/docker-compose.prod.yml" images -q)

for image_id in $RUNNING_IMAGES; do
    # Get image name
    image_name=$(docker inspect --format='{{index .RepoTags 0}}' "$image_id" | sed 's/[\/:]/_/g')
    
    if [ "$image_name" != "<no_value>" ]; then
        log_info "Saving image: $image_name"
        docker save "$image_id" | gzip > "$BACKUP_PATH/images/${image_name}.tar.gz"
    fi
done

log_success "Docker images backed up"

# Backup Docker volumes (if any)
log_info "Checking for Docker volumes to backup..."
volumes=$(docker volume ls --format "{{.Name}}" | grep "$PROJECT_SLUG" || true)

if [ -n "$volumes" ]; then
    mkdir -p "$BACKUP_PATH/volumes"
    
    for volume in $volumes; do
        log_info "Backing up volume: $volume"
        docker run --rm \
            -v "$volume:/data" \
            -v "$BACKUP_PATH/volumes:/backup" \
            alpine \
            tar -czf "/backup/${volume}.tar.gz" -C /data .
    done
    
    log_success "Docker volumes backed up"
else
    log_info "No Docker volumes found to backup"
fi

# Backup SSL certificates
if [ -d "$PROJECT_DIR/infra/ssl" ]; then
    log_info "Backing up SSL certificates..."
    tar -czf "$BACKUP_PATH/ssl_certificates.tar.gz" \
        -C "$PROJECT_DIR/infra" \
        ssl/
    log_success "SSL certificates backed up"
fi

# Backup environment files
log_info "Backing up environment configuration..."
find "$PROJECT_DIR" -name ".env*" -not -path "*/node_modules/*" -exec cp {} "$BACKUP_PATH/" \;

# Create backup metadata
log_info "Creating backup metadata..."
cat > "$BACKUP_PATH/backup_info.json" << EOF
{
    "backup_name": "$BACKUP_NAME",
    "timestamp": "$(date -Iseconds)",
    "project_slug": "$PROJECT_SLUG",
    "project_dir": "$PROJECT_DIR",
    "created_by": "$(whoami)",
    "hostname": "$(hostname)",
    "docker_version": "$(docker --version)",
    "compose_version": "$(docker-compose --version)",
    "git_commit": "$(cd "$PROJECT_DIR" && git rev-parse HEAD 2>/dev/null || echo 'N/A')",
    "git_branch": "$(cd "$PROJECT_DIR" && git branch --show-current 2>/dev/null || echo 'N/A')",
    "services": [
$(docker-compose -f "$PROJECT_DIR/docker-compose.prod.yml" ps --services | sed 's/^/        "/' | sed 's/$/",/' | sed '$ s/,$//')
    ]
}
EOF

# Create checksums
log_info "Creating checksums..."
cd "$BACKUP_PATH"
find . -type f -exec sha256sum {} \; > checksums.sha256

# Compress entire backup
log_info "Compressing backup..."
cd "$BACKUP_DIR"
tar -czf "backup_${BACKUP_NAME}.tar.gz" "backup_$BACKUP_NAME"

# Calculate final backup size
BACKUP_SIZE=$(du -h "backup_${BACKUP_NAME}.tar.gz" | cut -f1)

# Remove uncompressed backup directory
rm -rf "backup_$BACKUP_NAME"

log_success "Backup completed successfully!"
echo ""
echo "========================================="
echo "         Backup Summary"
echo "========================================="
echo "📦 Backup Name: $BACKUP_NAME"
echo "📍 Backup Location: $BACKUP_DIR/backup_${BACKUP_NAME}.tar.gz"
echo "📏 Backup Size: $BACKUP_SIZE"
echo "🕒 Created: $(date)"
echo ""
echo "Backup includes:"
echo "✅ Project files (excluding node_modules, dist)"
echo "✅ Docker images"
echo "✅ Docker volumes (if any)"
echo "✅ SSL certificates"
echo "✅ Environment configuration"
echo "✅ Backup metadata and checksums"
echo ""

# Cleanup old backups (keep last 7 days)
log_info "Cleaning up old backups (keeping last 7 days)..."
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +7 -delete || log_warning "Failed to cleanup old backups"

# Show remaining backups
echo "Available backups:"
ls -lh "$BACKUP_DIR"/backup_*.tar.gz | awk '{print "  " $9 " (" $5 ", " $6 " " $7 " " $8 ")"}' | head -10

echo ""
echo "🎉 Backup process completed successfully!"

# Optional: Test backup integrity
read -p "Test backup integrity? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Testing backup integrity..."
    
    if tar -tzf "$BACKUP_DIR/backup_${BACKUP_NAME}.tar.gz" > /dev/null; then
        log_success "✅ Backup archive integrity verified"
    else
        log_error "❌ Backup archive is corrupted"
    fi
    
    # Extract checksums temporarily and verify
    TEMP_DIR=$(mktemp -d)
    tar -xzf "$BACKUP_DIR/backup_${BACKUP_NAME}.tar.gz" -C "$TEMP_DIR"
    
    if (cd "$TEMP_DIR/backup_$BACKUP_NAME" && sha256sum -c checksums.sha256 --quiet); then
        log_success "✅ File checksums verified"
    else
        log_warning "❌ Some file checksums don't match"
    fi
    
    rm -rf "$TEMP_DIR"
fi
