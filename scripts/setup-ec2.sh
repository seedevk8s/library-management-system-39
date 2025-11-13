#!/bin/bash

# ============================================
# EC2 초기 설정 스크립트
# ============================================

set -e

echo "=========================================="
echo "  EC2 Initial Setup"
echo "=========================================="
echo ""

# 색상 정의
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# 1. 시스템 업데이트
log "[1/8] Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# 2. 필수 패키지 설치
log "[2/8] Installing essential packages..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    vim \
    htop \
    mysql-client

# 3. Docker 설치
log "[3/8] Installing Docker..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 4. Docker 서비스 시작
log "[4/8] Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# 5. 사용자를 docker 그룹에 추가
log "[5/8] Adding user to docker group..."
sudo usermod -aG docker $USER

# 6. 애플리케이션 디렉토리 생성
log "[6/8] Creating application directories..."
mkdir -p /home/ubuntu/app
mkdir -p /home/ubuntu/app/uploads
mkdir -p /home/ubuntu/app/logs
mkdir -p /home/ubuntu/app/backups

# 7. Swap 메모리 설정 (t2.micro 메모리 부족 대비)
log "[7/8] Setting up swap memory..."
if [ ! -f /swapfile ]; then
    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    log "✅ Swap memory (1GB) created"
else
    log "Swap file already exists"
fi

# 8. 방화벽 설정 (UFW)
log "[8/8] Configuring firewall..."
sudo ufw --force enable
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8081/tcp  # Application
sudo ufw reload

echo ""
echo "=========================================="
echo "  ✅ EC2 Setup Completed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Logout and login again to apply docker group membership"
echo "  2. Verify Docker installation: docker --version"
echo "  3. Create .env file in /home/ubuntu/app/"
echo "  4. Run deployment: ./deploy.sh"
echo ""
echo "⚠️  Please logout and login again for changes to take effect!"
echo ""
