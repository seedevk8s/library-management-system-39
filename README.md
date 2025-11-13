# 📚 Library Management System

Spring Boot 기반의 도서관 관리 시스템입니다.

## 🚀 Features

- 📖 도서 관리 (CRUD)
- 👥 회원 관리
- 📝 대여/반납 관리
- 📋 게시판 시스템
- 📎 파일 업로드
- 🔐 Spring Security 인증/인가

## 🛠️ Tech Stack

- **Backend**: Spring Boot 3.5.6, Java 17
- **Database**: MySQL 8.0
- **Security**: Spring Security
- **View**: Thymeleaf
- **ORM**: Spring Data JPA
- **Build Tool**: Gradle
- **Containerization**: Docker, Docker Compose

## 📋 Prerequisites

- Java 17+
- Docker & Docker Compose
- MySQL 8.0 (또는 Docker로 실행)

## 🏃 Quick Start

### 1. 저장소 클론

```bash
git clone <repository-url>
cd library-management-system-39
```

### 2. Docker Compose로 실행 (권장)

```bash
# MySQL + 애플리케이션 동시 실행
docker-compose up -d

# 로그 확인
docker-compose logs -f app
```

애플리케이션이 시작되면 http://localhost:8081 에서 접속 가능합니다.

### 3. 로컬 개발 환경 실행

```bash
# MySQL 컨테이너만 실행
docker-compose up -d mysql

# 애플리케이션 빌드 및 실행
./gradlew bootRun
```

## 📁 Project Structure

```
library-management-system-39/
├── src/
│   ├── main/
│   │   ├── java/com/library/
│   │   │   ├── controller/
│   │   │   ├── service/
│   │   │   ├── repository/
│   │   │   ├── entity/
│   │   │   └── config/
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── templates/
│   │       └── static/
│   └── test/
├── docs/                        # 📖 배포 가이드
│   ├── README.md               # 문서 인덱스
│   ├── QUICK-START.md          # 빠른 시작 가이드
│   └── AWS-DEPLOYMENT-GUIDE.md # AWS 배포 상세 가이드
├── scripts/                     # 🔧 배포 스크립트
│   ├── deploy.sh               # 자동 배포 스크립트
│   └── setup-ec2.sh            # EC2 초기 설정 스크립트
├── .github/workflows/           # 🔄 CI/CD
│   └── deploy.yml              # GitHub Actions 워크플로우
├── Dockerfile
├── docker-compose.yml           # 로컬 개발용
├── docker-compose.prod.yml      # 프로덕션용
├── .env.example                 # 환경 변수 템플릿
└── build.gradle
```

## 🌐 AWS 배포

이 프로젝트는 **AWS 프리티어를 활용하여 완전 무료로 배포**할 수 있습니다!

### 배포 가이드

- **[Quick Start Guide](./docs/QUICK-START.md)** ⚡ - 빠른 배포 (약 1시간 30분)
- **[AWS Deployment Guide](./docs/AWS-DEPLOYMENT-GUIDE.md)** 📘 - 상세 배포 가이드

### 배포 아키텍처

```
사용자 → Elastic IP → EC2 (t2.micro) → RDS MySQL (t2.micro)
                         ↓
                    Docker Container
                    (Spring Boot App)
```

### 사용 AWS 서비스 (모두 프리티어 무료)

| 서비스 | 용도 | 프리티어 | 월 비용 |
|--------|------|----------|---------|
| EC2 t2.micro | 애플리케이션 서버 | 750시간/월 | **$0** |
| RDS MySQL t2.micro | 데이터베이스 | 750시간/월 | **$0** |
| Elastic IP | 고정 IP | 1개 | **$0** |
| EBS | 스토리지 | 30GB | **$0** |

**총 월 예상 비용: $0** (프리티어 범위 내)

### CI/CD

GitHub Actions를 통한 자동 배포:

1. 코드를 `main` 브랜치에 푸시
2. 자동으로 테스트 실행
3. Docker 이미지 빌드 및 푸시
4. EC2에 자동 배포

```bash
git add .
git commit -m "feat: 새로운 기능 추가"
git push origin main
# 🎉 자동 배포 시작!
```

## 🔧 Configuration

### 환경 변수

`.env.example` 파일을 복사하여 `.env` 파일을 생성하고 환경에 맞게 수정하세요.

```bash
cp .env.example .env
nano .env
```

### 주요 설정

- **Port**: 8081
- **Database**: MySQL 8.0
- **Upload Directory**: `./uploads`
- **Max File Size**: 10MB
- **Profiles**: `dev` (개발), `prod` (운영)

## 🧪 Testing

```bash
# 모든 테스트 실행
./gradlew test

# 특정 테스트 실행
./gradlew test --tests com.library.service.*
```

## 📊 Monitoring

### Health Check

```bash
curl http://localhost:8081/actuator/health
```

### Logs

```bash
# Docker Compose
docker-compose logs -f app

# 로컬 파일
tail -f logs/library-system.log
```

## 🛠️ Development

### 로컬 개발 환경 설정

1. **MySQL 실행**:
   ```bash
   docker-compose up -d mysql
   ```

2. **애플리케이션 실행**:
   ```bash
   ./gradlew bootRun
   ```

3. **Hot Reload** (Spring DevTools 활성화됨):
   - 코드 수정 후 자동 재시작

### 데이터베이스 접속

```bash
# Docker MySQL 접속
docker exec -it library-mysql mysql -u root -p12345

# RDS 접속 (AWS 배포 시)
mysql -h <RDS-ENDPOINT> -u admin -p
```

## 📦 Build & Deploy

### Docker 이미지 빌드

```bash
# 이미지 빌드
docker build -t library-management-system:latest .

# 컨테이너 실행
docker run -d \
  -p 8081:8081 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e DB_URL=jdbc:mysql://... \
  -e DB_USERNAME=admin \
  -e DB_PASSWORD=password \
  library-management-system:latest
```

### Docker Hub에 푸시

```bash
docker login
docker tag library-management-system:latest <username>/library-management-system:latest
docker push <username>/library-management-system:latest
```

## 🔒 Security

- Spring Security를 사용한 인증/인가
- 비밀번호 암호화 (BCrypt)
- CSRF 보호 활성화
- SQL Injection 방지 (JPA Prepared Statement)
- XSS 방지 (Thymeleaf 자동 이스케이핑)

## 📝 API Endpoints

### Public

- `GET /` - 메인 페이지
- `GET /login` - 로그인
- `POST /login` - 로그인 처리
- `GET /register` - 회원가입

### Protected (인증 필요)

- `GET /books` - 도서 목록
- `GET /books/{id}` - 도서 상세
- `POST /books` - 도서 등록
- `PUT /books/{id}` - 도서 수정
- `DELETE /books/{id}` - 도서 삭제

### Admin Only

- `GET /admin/*` - 관리자 페이지

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Spring Boot Team
- Thymeleaf Team
- Docker Community

## 📞 Contact

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)

---

## 📚 Additional Resources

### Documentation
- [Quick Start Guide](./docs/QUICK-START.md) - AWS 배포 빠른 시작
- [AWS Deployment Guide](./docs/AWS-DEPLOYMENT-GUIDE.md) - AWS 배포 상세 가이드
- [Documentation Index](./docs/README.md) - 모든 문서 목록

### Scripts
- [Deploy Script](./scripts/deploy.sh) - 자동 배포 스크립트
- [EC2 Setup Script](./scripts/setup-ec2.sh) - EC2 초기 설정 스크립트

### External Links
- [Spring Boot Documentation](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/)
- [Docker Documentation](https://docs.docker.com/)
- [AWS Free Tier](https://aws.amazon.com/free/)

---

**Version**: 1.0.0
**Last Updated**: 2025-11-13
**Maintained by**: Development Team
