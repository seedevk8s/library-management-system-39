#!/bin/bash

# ============================================
# Library Management System Deployment Script
# ============================================

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 변수 설정
APP_DIR="/home/ubuntu/app"
DOCKER_IMAGE="${DOCKERHUB_USERNAME:-your-username}/library-management-system:latest"
COMPOSE_FILE="docker-compose.prod.yml"
LOG_FILE="/home/ubuntu/app/logs/deploy.log"

# 로그 함수
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

# 시작 메시지
echo ""
echo "=========================================="
echo "  Library Management System Deployment"
echo "=========================================="
echo ""

# 작업 디렉토리로 이동
cd "$APP_DIR" || {
    log_error "Failed to change directory to $APP_DIR"
    exit 1
}

# 1. Docker 이미지 다운로드
log "[1/6] Pulling latest Docker image..."
if docker pull "$DOCKER_IMAGE"; then
    log "✅ Image pulled successfully"
else
    log_error "Failed to pull Docker image"
    exit 1
fi

# 2. 현재 컨테이너 상태 확인
log "[2/6] Checking current application status..."
if docker compose -f "$COMPOSE_FILE" ps | grep -q "library-app"; then
    log "Found running application"

    # 백업 생성 (선택사항)
    log "Creating backup of uploads directory..."
    BACKUP_DIR="backups/$(date +'%Y%m%d_%H%M%S')"
    mkdir -p "$BACKUP_DIR"
    if [ -d "uploads" ] && [ "$(ls -A uploads)" ]; then
        cp -r uploads "$BACKUP_DIR/"
        log "✅ Backup created: $BACKUP_DIR"
    else
        log_warning "No files to backup"
    fi
else
    log "No running application found"
fi

# 3. 기존 컨테이너 중지
log "[3/6] Stopping current application..."
if docker compose -f "$COMPOSE_FILE" down; then
    log "✅ Application stopped"
else
    log_warning "No application to stop or stop failed"
fi

# 4. 오래된 리소스 정리
log "[4/6] Cleaning up old Docker resources..."
docker container prune -f >> "$LOG_FILE" 2>&1
docker image prune -f >> "$LOG_FILE" 2>&1
log "✅ Cleanup completed"

# 5. 새 컨테이너 시작
log "[5/6] Starting new application..."
if docker compose -f "$COMPOSE_FILE" up -d; then
    log "✅ Application started"
else
    log_error "Failed to start application"
    log "Checking logs..."
    docker compose -f "$COMPOSE_FILE" logs --tail=50
    exit 1
fi

# 6. Health Check
log "[6/6] Performing health check..."
MAX_ATTEMPTS=15
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))

    if curl -f -s http://localhost:8081/actuator/health > /dev/null 2>&1; then
        log "✅ Application is healthy!"

        # 컨테이너 상태 표시
        echo ""
        docker compose -f "$COMPOSE_FILE" ps

        # 최종 메시지
        echo ""
        echo "=========================================="
        echo "  ✅ Deployment Completed Successfully!"
        echo "=========================================="
        echo ""
        echo "Application URL: http://$(curl -s http://checkip.amazonaws.com):8081"
        echo "Health Check: http://$(curl -s http://checkip.amazonaws.com):8081/actuator/health"
        echo ""
        echo "To view logs:"
        echo "  docker compose -f $COMPOSE_FILE logs -f app"
        echo ""

        exit 0
    fi

    log "Waiting for application to be healthy... ($ATTEMPT/$MAX_ATTEMPTS)"
    sleep 10
done

# Health check 실패
log_error "Application health check failed after $MAX_ATTEMPTS attempts!"
echo ""
echo "=========================================="
echo "  ❌ Deployment Failed"
echo "=========================================="
echo ""
echo "Checking application logs..."
docker compose -f "$COMPOSE_FILE" logs --tail=100

echo ""
echo "To troubleshoot:"
echo "  1. Check logs: docker compose -f $COMPOSE_FILE logs -f app"
echo "  2. Check container status: docker compose -f $COMPOSE_FILE ps"
echo "  3. Check environment variables: cat .env"
echo "  4. Check database connection from EC2:"
echo "     mysql -h <RDS_ENDPOINT> -u admin -p"
echo ""

exit 1
