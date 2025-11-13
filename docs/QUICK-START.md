# 🚀 AWS 배포 빠른 시작 가이드

이 문서는 AWS 프리티어를 활용하여 Library Management System을 빠르게 배포하는 방법을 안내합니다.

## 📋 전체 흐름

```
1. AWS 계정 생성 및 설정 (30분)
   ↓
2. RDS MySQL 데이터베이스 생성 (10분)
   ↓
3. EC2 인스턴스 생성 및 설정 (15분)
   ↓
4. Docker 이미지 빌드 및 배포 (10분)
   ↓
5. GitHub Actions CI/CD 설정 (10분)
   ↓
6. 배포 완료 및 테스트 (5분)
```

**총 소요 시간: 약 1시간 30분**

---

## 🎯 단계별 체크리스트

### ✅ 사전 준비 (5분) - Windows

- [ ] AWS 계정 생성 완료
- [ ] GitHub 계정 로그인
- [ ] Docker Hub 계정 생성 (https://hub.docker.com/)
- [ ] Windows 로컬 환경 준비:
  - [ ] Git for Windows 설치 (https://git-scm.com/download/win)
  - [ ] SSH 클라이언트: PuTTY (https://www.putty.org/) 또는 OpenSSH
  - [ ] VS Code 설치 (https://code.visualstudio.com/)

### ✅ 1단계: AWS Billing Alerts 설정 (10분)

**필수! 비용 초과 방지를 위해 반드시 설정하세요.**

1. **결제 대시보드 접속**
   - AWS 콘솔 우측 상단 계정 이름 클릭 → **"결제 및 비용 관리"**

2. **결제 알림 활성화**
   - 좌측 메뉴 **"결제 기본 설정"** → **"결제 알림 수신"** 체크 → **"기본 설정 저장"**

3. **CloudWatch 경보 생성**
   - 검색창에 **"CloudWatch"** 입력
   - ⚠️ 리전을 **"미국 동부(버지니아 북부)"** 로 변경
   - **"경보"** → **"경보 생성"** → **"지표 선택"**
   - **"결제"** → **"총 예상 요금"** → USD 선택
   - 임계값: **1** 달러 입력 → **"새 주제 생성"**
   - 이메일 입력 → **"주제 생성"** → **"경보 생성"**
   - 📧 이메일 확인 링크 클릭 (필수!)

4. **예산 생성**
   - 결제 대시보드 → **"예산"** → **"예산 생성"**
   - **"템플릿 사용(간편)"** → **"제로 지출 예산"** 선택
   - 예산 이름: **"프리티어-무료-예산"** → 이메일 입력 → **"예산 생성"**

📖 **상세 가이드**: [AWS-DEPLOYMENT-GUIDE.md](./AWS-DEPLOYMENT-GUIDE.md#13-billing-alerts-설정-필수)

### ✅ 2단계: RDS MySQL 생성 (10분)

1. **RDS 콘솔 접속**
   - 검색창에 **"RDS"** 입력 → 서울 리전(ap-northeast-2) 확인

2. **데이터베이스 생성**
   - 좌측 메뉴 **"데이터베이스"** → **"데이터베이스 생성"** 클릭

3. **템플릿 선택**
   - **"표준 생성"** 선택
   - 엔진: **MySQL** → 버전: MySQL 8.0.35
   - 템플릿: **"프리 티어"** 선택 ✅

4. **설정**
   - **DB 인스턴스 식별자**: `library-db`
   - **마스터 사용자 이름**: `admin`
   - **마스터 암호**: `LibraryAdmin2024!` (⚠️ 안전하게 저장!)

5. **스토리지**
   - 할당된 스토리지: **20 GiB**
   - **스토리지 자동 조정**: 체크 해제 (비용 초과 방지)

6. **연결**
   - **퍼블릭 액세스**: **"예"** 선택
   - **VPC 보안 그룹**: **"새로 생성"** → 이름: `library-rds-sg`

7. **추가 구성**
   - **초기 데이터베이스 이름**: `librarydb` (⚠️ 필수!)
   - **자동 백업 활성화**: ✅ 체크 (7일)
   - **삭제 방지**: ✅ 체크

8. **데이터베이스 생성**
   - **"데이터베이스 생성"** 버튼 클릭
   - ⏳ 상태가 "사용 가능"이 될 때까지 대기 (약 5-10분)

9. **엔드포인트 확인**
   - `library-db` 클릭 → **"연결 및 보안"** 탭
   - **엔드포인트** 복사: `library-db.xxxxxx.ap-northeast-2.rds.amazonaws.com`
   - ⚠️ 메모장에 저장!

📖 **상세 가이드**: [AWS-DEPLOYMENT-GUIDE.md](./AWS-DEPLOYMENT-GUIDE.md#2단계-rds-mysql-데이터베이스-생성)

### ✅ 3단계: EC2 인스턴스 생성 (15분)

1. **키 페어 생성** (Windows)
   - 검색창에 **"EC2"** 입력 → 서울 리전 확인
   - **"네트워크 및 보안"** → **"키 페어"** → **"키 페어 생성"**
   - 이름: `library-app-key` / 유형: RSA
   - 형식: **`.ppk`** (PuTTY 권장) 또는 `.pem` (Git Bash/PowerShell)
   - 다운로드 후 저장 (PowerShell):
     ```powershell
     # SSH 폴더 생성 및 키 파일 이동
     New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.ssh"
     Move-Item -Path "$env:USERPROFILE\Downloads\library-app-key.ppk" -Destination "$env:USERPROFILE\.ssh\"
     ```

2. **EC2 인스턴스 시작**
   - **"인스턴스"** → **"인스턴스 시작"** 클릭
   - **이름**: `library-app-server`
   - **AMI**: **Ubuntu Server 22.04 LTS** (프리 티어 ✅)
   - **인스턴스 유형**: **t2.micro** (프리 티어 ✅)
   - **키 페어**: `library-app-key` 선택

   **네트워크 설정** (편집 클릭):
   - **퍼블릭 IP 자동 할당**: 활성화
   - **보안 그룹 생성**: 이름 `library-app-sg`
   - **인바운드 보안 그룹 규칙**:
     ```
     SSH (22): 내 IP
     HTTP (80): 위치 무관 (0.0.0.0/0)
     HTTPS (443): 위치 무관 (0.0.0.0/0)
     사용자 지정 TCP (8081): 위치 무관 (0.0.0.0/0)
     ```

   **스토리지**: 30 GiB gp3

   **고급 세부 정보 → 사용자 데이터**:
   ```bash
   #!/bin/bash
   apt-get update -y && apt-get upgrade -y
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   usermod -aG docker ubuntu
   mkdir -p /home/ubuntu/app/{uploads,logs,backups}
   chown -R ubuntu:ubuntu /home/ubuntu/app
   ```

   - **"인스턴스 시작"** 클릭
   - 상태가 **"실행 중"**, 검사 **"2/2 통과"** 확인 (약 2-3분)

3. **Elastic IP 할당 및 연결**
   - **"네트워크 및 보안"** → **"탄력적 IP"** → **"탄력적 IP 주소 할당"**
   - **"할당"** 클릭 → IP 체크 → **"작업"** → **"탄력적 IP 주소 연결"**
   - 인스턴스: `library-app-server` 선택 → **"연결"** 클릭
   - ⚠️ **이 IP 주소를 메모하세요!** (예: 3.35.123.456)

4. **SSH 접속 테스트** (Windows)

   **PuTTY 사용 (권장)**:
   - PuTTY 실행 → Host Name: `ubuntu@<YOUR-ELASTIC-IP>`
   - Connection → SSH → Auth → Credentials → Private key: `.ppk` 파일 선택
   - Open 클릭

   **PowerShell/CMD 사용** (Windows 10+):
   ```powershell
   ssh -i %USERPROFILE%\.ssh\library-app-key.pem ubuntu@<YOUR-ELASTIC-IP>
   ```

   **Git Bash 사용**:
   ```bash
   ssh -i ~/.ssh/library-app-key.pem ubuntu@<YOUR-ELASTIC-IP>
   ```

5. **RDS 보안 그룹 업데이트**
   - **"보안 그룹"** → `library-rds-sg` 선택
   - **"인바운드 규칙 편집"** 클릭
   - MySQL/Aurora (3306) → 소스: EC2 보안 그룹 ID (sg-xxx) 입력
   - **"규칙 저장"** 클릭

📖 **상세 가이드**: [AWS-DEPLOYMENT-GUIDE.md](./AWS-DEPLOYMENT-GUIDE.md#3단계-ec2-인스턴스-생성-및-설정)

### ✅ 4단계: Docker 배포 (10분)

1. **EC2에 환경 변수 설정**:
   ```bash
   # EC2에 SSH 접속 후
   cd /home/ubuntu/app
   nano .env
   ```

   ```bash
   SPRING_PROFILES_ACTIVE=prod
   DB_URL=jdbc:mysql://library-db.xxxxxx.ap-northeast-2.rds.amazonaws.com:3306/librarydb?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul&characterEncoding=UTF-8
   DB_USERNAME=admin
   DB_PASSWORD=LibraryAdmin2024!
   FILE_UPLOAD_DIR=/app/uploads
   SERVER_PORT=8081
   ```

2. **Docker Compose 파일 복사**:
   ```bash
   # 로컬에서 실행
   scp -i ~/.ssh/library-app-key.pem \
       docker-compose.prod.yml \
       ubuntu@<YOUR-ELASTIC-IP>:/home/ubuntu/app/
   ```

3. **Docker 이미지 빌드 및 푸시**:
   ```bash
   # 로컬에서 실행
   docker login
   docker build -t library-management-system:latest .
   docker tag library-management-system:latest <your-dockerhub-username>/library-management-system:latest
   docker push <your-dockerhub-username>/library-management-system:latest
   ```

4. **EC2에서 애플리케이션 실행**:
   ```bash
   # EC2에서 실행
   cd /home/ubuntu/app

   # docker-compose.prod.yml의 image 수정
   nano docker-compose.prod.yml
   # image: <your-dockerhub-username>/library-management-system:latest

   # 실행
   docker pull <your-dockerhub-username>/library-management-system:latest
   docker compose -f docker-compose.prod.yml up -d

   # 로그 확인
   docker compose logs -f app
   ```

5. **배포 확인**:
   ```bash
   # Health check
   curl http://localhost:8081/actuator/health

   # 브라우저에서 접속
   # http://<YOUR-ELASTIC-IP>:8081
   ```

📖 **상세 가이드**: [AWS-DEPLOYMENT-GUIDE.md](./AWS-DEPLOYMENT-GUIDE.md#4단계-docker-및-애플리케이션-배포)

### ✅ 5단계: GitHub Actions CI/CD 설정 (10분)

1. **GitHub Secrets 설정**:
   - GitHub 저장소 → Settings → Secrets and variables → Actions
   - "New repository secret" 클릭하여 다음 추가:

   | Secret 이름 | 값 |
   |-------------|-----|
   | `DOCKERHUB_USERNAME` | your-dockerhub-username |
   | `DOCKERHUB_TOKEN` | (Docker Hub Access Token) |
   | `EC2_HOST` | 3.35.123.456 |
   | `EC2_USERNAME` | ubuntu |
   | `EC2_SSH_KEY` | (pem 파일 내용 전체) |
   | `DB_URL` | jdbc:mysql://... |
   | `DB_USERNAME` | admin |
   | `DB_PASSWORD` | LibraryAdmin2024! |

2. **Docker Hub Access Token 생성**:
   - https://hub.docker.com/settings/security
   - "New Access Token" 클릭
   - 토큰 복사 → GitHub Secret `DOCKERHUB_TOKEN`에 추가

3. **코드 푸시**:
   ```bash
   git add .
   git commit -m "feat: AWS 프리티어 배포 설정 추가"
   git push origin main
   ```

4. **GitHub Actions 확인**:
   - GitHub 저장소 → Actions 탭
   - "Deploy to AWS EC2" 워크플로우 실행 확인
   - 자동 배포 완료 대기 (약 5-10분)

📖 **상세 가이드**: [AWS-DEPLOYMENT-GUIDE.md](./AWS-DEPLOYMENT-GUIDE.md#5단계-github-actions-cicd-설정)

---

## 🎉 배포 완료!

애플리케이션이 성공적으로 배포되었습니다!

### 접속 정보

- **애플리케이션**: http://<YOUR-ELASTIC-IP>:8081
- **Health Check**: http://<YOUR-ELASTIC-IP>:8081/actuator/health

### 테스트

1. 브라우저에서 애플리케이션 접속
2. 회원가입 및 로그인 테스트
3. 도서 관리 기능 테스트
4. 파일 업로드 기능 테스트

### 향후 배포

이제부터는 코드를 수정하고 `main` 브랜치에 푸시하면 **자동으로 배포**됩니다!

```bash
# 코드 수정 후
git add .
git commit -m "feat: 새로운 기능 추가"
git push origin main

# GitHub Actions가 자동으로:
# 1. 테스트 실행
# 2. Docker 이미지 빌드
# 3. Docker Hub에 푸시
# 4. EC2에 자동 배포
```

---

## 🛠️ 유용한 명령어

### EC2 SSH 접속
```bash
ssh -i ~/.ssh/library-app-key.pem ubuntu@<YOUR-ELASTIC-IP>
```

### 로그 확인
```bash
# 실시간 로그
docker compose -f docker-compose.prod.yml logs -f app

# 최근 100줄
docker compose -f docker-compose.prod.yml logs --tail=100 app
```

### 애플리케이션 재시작
```bash
docker compose -f docker-compose.prod.yml restart app
```

### 수동 배포 (배포 스크립트 사용)
```bash
cd /home/ubuntu/app
./deploy.sh
```

### 데이터베이스 백업
```bash
mysqldump -h <RDS-ENDPOINT> -u admin -p librarydb > backup_$(date +%Y%m%d).sql
```

---

## 📊 비용 모니터링

### 프리티어 사용량 확인

1. **AWS Billing Dashboard**:
   - AWS 콘솔 → Billing Dashboard
   - "Free Tier" 탭에서 사용량 확인

2. **월별 예상 비용**:
   - "Bills" 탭에서 현재 월 비용 확인
   - 프리티어 범위 내: **$0.00**

3. **알림 설정 확인**:
   - CloudWatch Alarms 확인
   - $1 초과 시 이메일 알림

### 프리티어 한도

| 서비스 | 프리티어 한도 | 현재 사용 |
|--------|--------------|----------|
| EC2 t2.micro | 750시간/월 | 720시간 (30일 × 24시간) |
| RDS t2.micro | 750시간/월 | 720시간 (30일 × 24시간) |
| EBS 스토리지 | 30GB | 50GB (EC2 30GB + RDS 20GB) |
| 데이터 전송 | 15GB/월 | 예상 < 1GB |

---

## ❓ 문제 해결

### 애플리케이션이 시작되지 않음

1. **로그 확인**:
   ```bash
   docker compose logs app
   ```

2. **일반적인 원인**:
   - RDS 연결 실패 → 보안 그룹 확인
   - 환경 변수 오류 → `.env` 파일 확인
   - 메모리 부족 → `docker stats` 확인

### RDS 연결 실패

```bash
# EC2에서 테스트
mysql -h <RDS-ENDPOINT> -u admin -p

# 보안 그룹 확인:
# - RDS 보안 그룹 인바운드 규칙에 EC2 보안 그룹 ID 추가
```

### GitHub Actions 배포 실패

1. **Secrets 확인**: 모든 Secret이 올바르게 설정되었는지 확인
2. **SSH Key 확인**: `EC2_SSH_KEY`에 전체 pem 파일 내용 포함 (-----BEGIN ... END----- 포함)
3. **로그 확인**: GitHub Actions 탭에서 에러 로그 확인

### 메모리 부족 (OOMKilled)

```bash
# Swap 메모리 추가
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## 📚 추가 문서

- **[AWS 배포 가이드 (전체)](./AWS-DEPLOYMENT-GUIDE.md)**: 모든 단계의 상세 설명
- **[환경 변수 예시](./.env.example)**: 환경 변수 템플릿
- **[배포 스크립트](../scripts/deploy.sh)**: 자동 배포 스크립트
- **[EC2 초기 설정 스크립트](../scripts/setup-ec2.sh)**: EC2 초기화 스크립트

---

## 💡 다음 단계

### 보안 강화
- [ ] Nginx 리버스 프록시 설정
- [ ] Let's Encrypt SSL 인증서 설정
- [ ] RDS SSL 연결 활성화
- [ ] AWS Secrets Manager 사용

### 성능 최적화
- [ ] CloudFront CDN 설정 (정적 파일)
- [ ] S3 버킷 연동 (파일 업로드)
- [ ] Redis 캐시 추가

### 고가용성
- [ ] RDS Multi-AZ 배포
- [ ] EC2 Auto Scaling
- [ ] Application Load Balancer

---

**작성일**: 2025-11-13
**버전**: 1.0.0
**문의**: GitHub Issues
