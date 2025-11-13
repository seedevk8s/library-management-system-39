# AWS 프리티어 무료 배포 가이드

## 목차
1. [개요](#개요)
2. [AWS 프리티어 리소스](#aws-프리티어-리소스)
3. [사전 준비사항](#사전-준비사항)
4. [1단계: AWS 계정 생성 및 설정](#1단계-aws-계정-생성-및-설정)
5. [2단계: RDS MySQL 데이터베이스 생성](#2단계-rds-mysql-데이터베이스-생성)
6. [3단계: EC2 인스턴스 생성 및 설정](#3단계-ec2-인스턴스-생성-및-설정)
7. [4단계: Docker 및 애플리케이션 배포](#4단계-docker-및-애플리케이션-배포)
8. [5단계: GitHub Actions CI/CD 설정](#5단계-github-actions-cicd-설정)
9. [운영 및 모니터링](#운영-및-모니터링)
10. [비용 절감 팁](#비용-절감-팁)
11. [문제 해결](#문제-해결)

---

## 개요

이 가이드는 **AWS 프리티어를 활용하여 완전 무료로** Library Management System을 배포하는 방법을 단계별로 설명합니다.

### 배포 아키텍처

```
┌─────────────────────────────────────────────┐
│              사용자(인터넷)                    │
└─────────────┬───────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────┐
│        Elastic IP (고정 IP)                  │
└─────────────┬───────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────┐
│     EC2 t2.micro (프리티어)                  │
│  ┌──────────────────────────────────────┐  │
│  │  Docker                              │  │
│  │  ├─ Library App (Spring Boot)       │  │
│  │  └─ Nginx (Optional)                │  │
│  └──────────────────────────────────────┘  │
└─────────────┬───────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────┐
│   RDS MySQL t2.micro (프리티어)              │
│   - 20GB Storage                            │
│   - 자동 백업 활성화                          │
└─────────────────────────────────────────────┘
```

### 사용할 AWS 서비스 (모두 프리티어)

| 서비스 | 용도 | 프리티어 제공량 | 예상 비용 |
|--------|------|----------------|----------|
| EC2 t2.micro | 애플리케이션 서버 | 750시간/월 | **$0** |
| RDS MySQL t2.micro | 데이터베이스 | 750시간/월, 20GB | **$0** |
| Elastic IP | 고정 IP | 1개 (사용 중) | **$0** |
| EBS | 스토리지 | 30GB | **$0** |
| 데이터 전송 | 트래픽 | 15GB/월 | **$0** |
| **총 예상 비용** | | | **$0/월** |

> ⚠️ **주의**: 프리티어는 **가입 후 12개월간** 유효합니다. 제공량을 초과하면 요금이 부과됩니다.

---

## AWS 프리티어 리소스

### 프리티어 한도 (12개월간)

1. **EC2 (컴퓨팅)**
   - t2.micro 인스턴스: 750시간/월
   - 30GB EBS 스토리지
   - 1GB 스냅샷 스토리지

2. **RDS (데이터베이스)**
   - t2.micro 인스턴스: 750시간/월
   - 20GB 범용 SSD 스토리지
   - 20GB 백업 스토리지

3. **네트워크**
   - 데이터 전송: 15GB/월
   - Elastic IP: 1개 (인스턴스 연결 시 무료)

4. **기타**
   - CloudWatch: 10개 알람
   - S3: 5GB (선택사항)

### 비용 초과 방지

- AWS Billing Alerts 설정 ($1 이상 시 알림)
- AWS Budget 생성 (월 $0 예산 설정)
- Cost Explorer로 일일 사용량 모니터링

---

## 사전 준비사항

### 1. 로컬 환경 (Windows)

**필수 설치**:
- **Git for Windows**: [다운로드](https://git-scm.com/download/win)
  - Git Bash 포함 (Unix 명령어 사용 가능)
  - PowerShell/CMD에서도 git 사용 가능
- **텍스트 에디터**: [VS Code](https://code.visualstudio.com/) 권장

**SSH 클라이언트** (하나 선택):
- **PuTTY** (권장): [다운로드](https://www.putty.org/)
  - Windows 전용 SSH 클라이언트
  - .ppk 키 파일 형식 사용
- **Windows OpenSSH**: Windows 10(1809+) 및 Windows 11 기본 포함
  - 설정 → 앱 → 선택적 기능에서 "OpenSSH 클라이언트" 설치 확인
  - .pem 키 파일 형식 사용
- **Git Bash**: Git for Windows 설치 시 자동 포함
  - Unix 스타일 명령어 사용 가능

### 2. 계정 및 서비스
- AWS 계정 (신용카드 필요, 단 프리티어 범위 내 사용 시 무료)
- GitHub 계정
- Docker Hub 계정 (선택사항: GitHub Container Registry 사용 가능)

### 3. 이 저장소 클론

**PowerShell 또는 CMD**:
```powershell
# Git Bash, PowerShell 또는 CMD에서 실행
git clone <repository-url>
cd library-management-system-39
```

**또는 파일 탐색기 사용**:
1. 원하는 폴더에서 우클릭 → "Git Bash Here" 클릭
2. `git clone <repository-url>` 실행

---

## 1단계: AWS 계정 생성 및 설정

### 1.1 AWS 계정 생성

1. **AWS 회원가입**
   - https://aws.amazon.com/ko/ 접속
   - "AWS 계정 생성" 클릭
   - 이메일, 비밀번호, AWS 계정 이름 입력

2. **연락처 정보 입력**
   - 개인 또는 비즈니스 선택
   - 전체 이름, 전화번호, 주소 입력

3. **결제 정보 입력**
   - 신용카드 또는 체크카드 등록
   - ⚠️ 프리티어 사용 시 요금 부과 안 됨 (단, 인증용)
   - $1 임시 승인 후 취소됨

4. **신원 확인**
   - 전화번호로 인증 코드 수신
   - 음성 또는 SMS 선택 가능

5. **지원 플랜 선택**
   - **"기본 지원 - 무료"** 선택

6. **가입 완료**
   - 가입 완료까지 약 24시간 소요 (즉시 활성화되는 경우도 있음)

### 1.2 MFA (Multi-Factor Authentication) 설정 (권장)

1. **IAM 대시보드 접속**
   - AWS 콘솔 → "IAM" 검색
   - "Dashboard" 메뉴

2. **루트 사용자 MFA 활성화**
   - "Add MFA" 클릭
   - "Virtual MFA device" 선택
   - Google Authenticator 또는 Authy 앱 사용
   - QR 코드 스캔 후 연속된 2개 코드 입력

### 1.3 Billing Alerts 설정 (필수)

#### 중요! 비용 초과 방지를 위해 반드시 설정하세요.

1. **결제 대시보드 접속**
   - AWS 콘솔 우측 상단 계정 이름 클릭
   - **"결제 및 비용 관리"** (Billing and Cost Management) 선택
   - 또는 검색창에 "결제" 입력

2. **알림 설정 활성화**
   - 좌측 메뉴에서 **"결제 기본 설정"** (Billing preferences) 클릭
   - **"결제 알림 수신"** (Receive Billing Alerts) 체크
   - 이메일 주소 입력
   - 하단 **"기본 설정 저장"** (Save preferences) 클릭

3. **CloudWatch 경보 생성**
   - 좌측 상단 **"서비스"** (Services) 메뉴 클릭
   - 검색창에 **"CloudWatch"** 입력 후 선택
   - ⚠️ **중요**: 우측 상단 리전을 **"미국 동부(버지니아 북부)"** (US East N. Virginia)로 변경
     - 결제 관련 지표는 이 리전에서만 확인 가능합니다

   **경보 생성 과정**:
   - 좌측 메뉴 **"경보"** (Alarms) → **"결제"** (Billing) 클릭
   - 또는 **"경보"** → **"모든 경보"** → **"경보 생성"** (Create alarm) 클릭
   - **"지표 선택"** (Select metric) 클릭
   - **"결제"** (Billing) → **"총 예상 요금"** (Total Estimated Charge) 선택
   - 통화: **USD** 선택 → **"지표 선택"** 클릭

   **임계값 설정**:
   - **"보다 큼"** (Greater than) 선택
   - 임계값: **1** 입력 (1달러 초과 시 알림)
   - **"다음"** 클릭

   **알림 설정**:
   - **"새 주제 생성"** (Create new topic) 선택
   - 주제 이름: **"Billing-Alert"**
   - 이메일 엔드포인트: 본인 이메일 입력
   - **"주제 생성"** (Create topic) 클릭
   - **"다음"** 클릭

   **경보 이름 설정**:
   - 경보 이름: **"프리티어-초과-알림"**
   - **"다음"** → **"경보 생성"** 클릭

   **이메일 구독 확인**:
   - 이메일로 전송된 **"AWS Notification - Subscription Confirmation"** 확인
   - **"Confirm subscription"** 링크 클릭 (필수!)

4. **AWS Budget 생성** (추가 안전장치)
   - 결제 대시보드 좌측 메뉴 → **"예산"** (Budgets) 클릭
   - **"예산 생성"** (Create budget) 클릭
   - **"템플릿 사용(간편)"** 선택
   - **"제로 지출 예산"** (Zero spend budget) 선택
   - 예산 이름: **"프리티어-무료-예산"**
   - 이메일 수신자: 본인 이메일 입력
   - **"예산 생성"** (Create budget) 클릭

> ✅ **설정 완료 확인**
> - 이메일에서 CloudWatch SNS 구독 확인 완료
> - 결제 알림 활성화 확인
> - Budget 생성 확인

### 1.4 리전 선택

- 이 가이드에서는 **서울 리전 (ap-northeast-2)** 사용
- AWS 콘솔 우측 상단에서 리전 확인 및 변경

---

## 2단계: RDS MySQL 데이터베이스 생성

### 2.1 RDS 인스턴스 생성

1. **RDS 대시보드 접속**
   - AWS 콘솔 검색창에 **"RDS"** 입력 후 선택
   - 우측 상단 리전이 **"서울 (ap-northeast-2)"** 인지 확인

2. **데이터베이스 생성 시작**
   - 좌측 메뉴 **"데이터베이스"** (Databases) 클릭
   - 오렌지색 **"데이터베이스 생성"** (Create database) 버튼 클릭

3. **데이터베이스 생성 방식**
   - **"표준 생성"** (Standard create) 선택

4. **엔진 옵션**
   - 엔진 유형: **MySQL** 선택
   - 에디션: **MySQL Community**
   - 엔진 버전: **MySQL 8.0.35** (또는 최신 8.0.x 버전)

5. **템플릿**
   - ✅ **"프리 티어"** (Free tier) 선택
   - 자동으로 프리티어 최적 옵션 적용됨

6. **설정**
   - **DB 인스턴스 식별자**: `library-db` 입력
   - 자격 증명 설정:
     - **마스터 사용자 이름**: `admin` 입력 (기본값 유지)
     - **마스터 암호**: 강력한 비밀번호 입력 (예: `LibraryAdmin2024!`)
     - **암호 확인**: 동일하게 입력
   - ⚠️ **마스터 암호를 안전하게 메모장에 저장하세요!**

7. **인스턴스 구성**
   - **DB 인스턴스 클래스**: **db.t2.micro** (프리 티어 선택 시 자동 설정됨)
   - 버스터블 클래스 (t 클래스 포함)

8. **스토리지**
   - 스토리지 유형: **범용 SSD (gp2)**
   - 할당된 스토리지: **20 GiB** (프리티어 최대)
   - **스토리지 자동 조정 활성화**: ✅ **체크 해제** (비용 초과 방지)

9. **연결**
   - 컴퓨팅 리소스: **"EC2 컴퓨팅 리소스에 연결 안 함"** (Don't connect to an EC2 compute resource) 선택
   - 네트워크 유형: **IPv4**
   - **Virtual Private Cloud (VPC)**: 기본 VPC 선택
   - **DB 서브넷 그룹**: default
   - **퍼블릭 액세스**: **"예"** (Yes) 선택 ⚠️ EC2에서 접근하려면 필요
   - **VPC 보안 그룹**:
     - **"새로 생성"** (Create new) 선택
     - 새 VPC 보안 그룹 이름: `library-rds-sg` 입력
   - **가용 영역**: **ap-northeast-2a** 선택

10. **데이터베이스 인증**
    - **"암호 인증"** (Password authentication) 선택

11. **추가 구성** 확장
    - 클릭하여 펼치기

    **데이터베이스 옵션**:
    - **초기 데이터베이스 이름**: `librarydb` 입력 (⚠️ 필수!)
    - **DB 파라미터 그룹**: default.mysql8.0 (기본값)
    - **옵션 그룹**: default:mysql-8-0 (기본값)

    **백업**:
    - **자동 백업 활성화**: ✅ 체크 (프리티어 20GB 포함)
    - **백업 보존 기간**: **7일** 선택
    - **백업 기간**: 적절한 시간 선택 (예: **03:00-04:00 UTC** 또는 **18:00-19:00 UTC**)
    - 백업할 스냅샷 복사 대상 리전: 없음

    **암호화**:
    - **암호화 활성화**: 체크 해제 (프리티어에서는 선택사항)

    **로그 내보내기**:
    - 모든 로그 체크 해제 (CloudWatch Logs 비용 발생 방지)
      - 감사 로그
      - 오류 로그
      - 일반 로그
      - 느린 쿼리 로그

    **유지 관리**:
    - **마이너 버전 자동 업그레이드 활성화**: ✅ 체크
    - 유지 관리 기간: 기본값

    **삭제 방지**:
    - **삭제 방지 활성화**: ✅ 체크 (실수로 삭제 방지)

12. **월별 추정 요금 확인**
    - 우측 하단 **"월별 추정 요금"** (Estimated monthly costs) 확인
    - 프리티어 범위 내: **USD 0.00**

13. **데이터베이스 생성**
    - 하단 오렌지색 **"데이터베이스 생성"** (Create database) 버튼 클릭
    - ⏳ 데이터베이스 생성 중... (약 5-10분 소요)
    - 상태가 **"생성 중"** (Creating) → **"백업 중"** (Backing-up) → **"사용 가능"** (Available)으로 변경됨

### 2.2 RDS 보안 그룹 설정

1. **RDS 인스턴스 상태 확인**
   - RDS 대시보드 → **"데이터베이스"** 메뉴
   - `library-db` 인스턴스의 상태가 **"사용 가능"** (Available)이 될 때까지 대기
   - 약 5-10분 소요

2. **엔드포인트 확인**
   - `library-db` 인스턴스 이름 클릭 (파란색 링크)
   - **"연결 및 보안"** (Connectivity & security) 탭 클릭
   - **엔드포인트 및 포트** 섹션에서:
     - **엔드포인트**: 복사 (예: `library-db.xxxxxx.ap-northeast-2.rds.amazonaws.com`)
     - **포트**: 3306 확인
   - ⚠️ **엔드포인트를 메모장에 안전하게 저장하세요!**

3. **보안 그룹 설정**
   - 같은 페이지 **"연결 및 보안"** 탭에서
   - **VPC 보안 그룹** 섹션의 `library-rds-sg` 링크 클릭 (새 탭 열림)
   - EC2 보안 그룹 페이지가 열림
   - **"인바운드 규칙"** (Inbound rules) 탭 클릭
   - **"인바운드 규칙 편집"** (Edit inbound rules) 버튼 클릭

   기본 규칙 확인 (EC2 생성 후 수정 예정):
   ```
   유형(Type): MySQL/Aurora
   프로토콜(Protocol): TCP
   포트 범위(Port range): 3306
   소스(Source): Custom (나중에 EC2 보안 그룹 ID로 변경)
   설명(Description): Allow from EC2
   ```
   - **"규칙 저장"** (Save rules) 클릭

> 📝 **참고**: EC2 인스턴스 생성 후, 이 보안 그룹의 소스를 EC2 보안 그룹 ID로 변경하여 EC2에서만 RDS에 접근 가능하도록 설정합니다.

### 2.3 RDS 연결 테스트 (선택사항)

로컬에서 MySQL 클라이언트로 테스트:

```bash
# MySQL 클라이언트 설치 (Mac)
brew install mysql-client

# MySQL 클라이언트 설치 (Ubuntu)
sudo apt-get install mysql-client

# 연결 테스트
mysql -h library-db.xxxxxx.ap-northeast-2.rds.amazonaws.com \
  -P 3306 \
  -u admin \
  -p

# 암호 입력 후 연결 확인
mysql> SHOW DATABASES;
mysql> exit;
```

---

## 3단계: EC2 인스턴스 생성 및 설정

### 3.1 EC2 키 페어 생성

1. **EC2 대시보드 접속**
   - AWS 콘솔 검색창에 **"EC2"** 입력 후 선택
   - 우측 상단 리전이 **"서울 (ap-northeast-2)"** 인지 확인

2. **키 페어 생성**
   - 좌측 메뉴에서 **"네트워크 및 보안"** (Network & Security) → **"키 페어"** (Key Pairs) 클릭
   - 우측 상단 오렌지색 **"키 페어 생성"** (Create key pair) 버튼 클릭

   **키 페어 설정**:
   - **이름**: `library-app-key` 입력
   - **키 페어 유형**: **RSA** 선택
   - **프라이빗 키 파일 형식**:
     - ✅ **Windows 사용자 (권장)**: **".ppk"** 선택 (PuTTY용)
     - 또는 **".pem"** 선택 (Git Bash, PowerShell용)
   - **"키 페어 생성"** (Create key pair) 버튼 클릭
   - 🔑 **키 파일이 자동으로 다운로드됩니다. 안전하게 보관하세요!**

3. **키 파일 저장 (Windows)**

   **옵션 1: PuTTY 사용자 (.ppk 파일)**
   ```powershell
   # 다운로드 폴더에서 안전한 위치로 이동
   # 파일 탐색기에서 직접 이동하거나 PowerShell 사용:

   # SSH 키 저장 폴더 생성
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.ssh"

   # 다운로드된 키 파일을 .ssh 폴더로 이동
   Move-Item -Path "$env:USERPROFILE\Downloads\library-app-key.ppk" -Destination "$env:USERPROFILE\.ssh\library-app-key.ppk"
   ```

   **옵션 2: Git Bash 또는 Windows OpenSSH 사용자 (.pem 파일)**
   ```bash
   # Git Bash 또는 PowerShell에서 실행

   # SSH 디렉토리 생성
   mkdir -p ~/.ssh

   # 키 파일 이동
   mv ~/Downloads/library-app-key.pem ~/.ssh/

   # 권한 설정 (Git Bash에서만 필요)
   chmod 400 ~/.ssh/library-app-key.pem
   ```

   > 💡 **Windows 10/11 사용자 참고**:
   > - Windows 10(1809 이상) 및 Windows 11에는 OpenSSH가 기본 포함되어 있어 `.pem` 파일 사용 가능
   > - PuTTY를 사용하려면 [PuTTY 다운로드](https://www.putty.org/) 필요
   > - Git Bash를 사용하려면 [Git for Windows](https://git-scm.com/download/win) 설치 필요

### 3.2 EC2 인스턴스 생성

1. **인스턴스 시작**
   - EC2 대시보드 좌측 메뉴 → **"인스턴스"** (Instances) 클릭
   - 우측 상단 오렌지색 **"인스턴스 시작"** (Launch instances) 버튼 클릭

2. **이름 및 태그**
   - **이름**: `library-app-server` 입력
   - **태그 추가** (선택사항) - "새 태그 추가" 클릭:
     - 키: `Environment`, 값: `production`
     - 키: `Project`, 값: `library-management`

3. **애플리케이션 및 OS 이미지 (AMI)**
   - **빠른 시작** (Quick Start) 탭 선택 (기본값)
   - **Ubuntu** 선택
   - AMI: **Ubuntu Server 22.04 LTS (HVM), SSD Volume Type** 선택
   - 아키텍처: **64비트 (x86)** 확인
   - ✅ **"프리 티어 사용 가능"** (Free tier eligible) 표시 확인

4. **인스턴스 유형**
   - 인스턴스 유형: **t2.micro** 선택
   - ✅ **"프리 티어 사용 가능"** 표시 확인
   - 사양: vCPU 1개, 메모리 1 GiB

5. **키 페어 (로그인)**
   - **키 페어 이름**: 드롭다운에서 **library-app-key** 선택
   - 이전 단계에서 생성한 키 페어 사용

6. **네트워크 설정**
   - 우측 **"편집"** (Edit) 버튼 클릭하여 상세 설정

   **네트워크 설정 상세**:
   - **VPC**: 기본 VPC 선택 (vpc-xxxxx)
   - **서브넷**: 기본값 유지 또는 ap-northeast-2a 선택
   - **퍼블릭 IP 자동 할당**: **"활성화"** (Enable) 선택

   **방화벽 (보안 그룹)**:
   - **"보안 그룹 생성"** (Create security group) 선택
   - **보안 그룹 이름**: `library-app-sg` 입력
   - **설명**: `Security group for library application` 입력

   **인바운드 보안 그룹 규칙** 설정:

   | 유형(Type) | 프로토콜 | 포트 범위 | 소스 유형 | 소스 | 설명 |
   |-----------|---------|----------|----------|------|------|
   | SSH | TCP | 22 | 내 IP | (자동) | SSH access from my IP |
   | HTTP | TCP | 80 | 위치 무관 | 0.0.0.0/0 | HTTP access |
   | HTTPS | TCP | 443 | 위치 무관 | 0.0.0.0/0 | HTTPS access |
   | 사용자 지정 TCP | TCP | 8081 | 위치 무관 | 0.0.0.0/0 | Spring Boot app |

   규칙 추가 방법:
   - **"보안 그룹 규칙 추가"** 버튼 클릭
   - 각 규칙에 대해 위 표의 값 입력

   > ⚠️ **보안 강화**: SSH는 **"내 IP"** (My IP)로 자동 설정되어 본인 IP에서만 접속 가능

7. **스토리지 구성**
   - **루트 볼륨 (Root volume)**:
     - 크기: **30 GiB** 입력 (프리티어 최대)
     - 볼륨 유형: **gp3** (범용 SSD) 선택
     - 암호화: 체크 해제 (선택사항)
     - **종료 시 삭제**: ✅ 체크 (기본값)

8. **고급 세부 정보** (선택사항)
   - 모니터링: 기본 (상세 모니터링은 비용 발생)
   - User data (초기 설정 스크립트):

   ```bash
   #!/bin/bash
   # 시스템 업데이트
   apt-get update -y
   apt-get upgrade -y

   # Docker 설치
   apt-get install -y ca-certificates curl gnupg lsb-release
   mkdir -p /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
   apt-get update -y
   apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

   # Docker 서비스 시작
   systemctl start docker
   systemctl enable docker

   # ubuntu 사용자를 docker 그룹에 추가
   usermod -aG docker ubuntu

   # 애플리케이션 디렉토리 생성
   mkdir -p /home/ubuntu/app
   mkdir -p /home/ubuntu/app/uploads
   mkdir -p /home/ubuntu/app/logs
   chown -R ubuntu:ubuntu /home/ubuntu/app

   # Git 설치
   apt-get install -y git

   # 완료 메시지
   echo "EC2 initialization completed" > /home/ubuntu/init-complete.txt
   ```

8. **고급 세부 정보** (선택사항)
   - **고급 세부 정보** 섹션 클릭하여 확장
   - **상세 모니터링**: 비활성화 유지 (활성화 시 비용 발생)
   - **사용자 데이터** (User data): 아래 스크립트 복사하여 붙여넣기

   > 📝 User data는 EC2 인스턴스가 처음 시작될 때 자동으로 실행되는 스크립트입니다.

   ```bash
   #!/bin/bash
   # 시스템 업데이트
   apt-get update -y
   apt-get upgrade -y

   # Docker 설치
   apt-get install -y ca-certificates curl gnupg lsb-release
   mkdir -p /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
   apt-get update -y
   apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

   # Docker 서비스 시작
   systemctl start docker
   systemctl enable docker

   # ubuntu 사용자를 docker 그룹에 추가
   usermod -aG docker ubuntu

   # 애플리케이션 디렉토리 생성
   mkdir -p /home/ubuntu/app
   mkdir -p /home/ubuntu/app/uploads
   mkdir -p /home/ubuntu/app/logs
   chown -R ubuntu:ubuntu /home/ubuntu/app

   # Git 설치
   apt-get install -y git

   # 완료 메시지
   echo "EC2 initialization completed" > /home/ubuntu/init-complete.txt
   ```

9. **요약 확인 및 인스턴스 시작**
   - 우측 **"요약"** (Summary) 패널에서 설정 확인
     - 인스턴스 개수: 1
     - 인스턴스 유형: t2.micro
     - 프리티어 사용량: 750시간/월
   - 하단 오렌지색 **"인스턴스 시작"** (Launch instance) 버튼 클릭

10. **인스턴스 시작 확인**
    - 성공 메시지가 표시되면 **"모든 인스턴스 보기"** (View all instances) 클릭
    - 인스턴스 목록에서 `library-app-server` 확인
    - **인스턴스 상태**가 **"실행 중"** (Running)이 될 때까지 대기 (약 1-2분)
    - **상태 검사**가 **"2/2 검사 통과"** (2/2 checks passed)가 될 때까지 대기 (약 2-3분)

### 3.3 Elastic IP 할당

> 💡 **Elastic IP란?** 고정된 공인 IP 주소로, EC2 인스턴스를 재시작해도 IP가 변경되지 않습니다.

1. **Elastic IP 주소 할당**
   - EC2 대시보드 좌측 메뉴 → **"네트워크 및 보안"** → **"탄력적 IP"** (Elastic IPs) 클릭
   - 우측 상단 오렌지색 **"탄력적 IP 주소 할당"** (Allocate Elastic IP address) 버튼 클릭
   - **네트워크 경계 그룹**: ap-northeast-2 (기본값)
   - 하단 오렌지색 **"할당"** (Allocate) 버튼 클릭
   - ✅ Elastic IP 주소가 생성됨 (예: 3.35.123.456)

2. **Elastic IP를 EC2 인스턴스에 연결**
   - 방금 생성된 Elastic IP 주소 체크박스 선택
   - 상단 **"작업"** (Actions) → **"탄력적 IP 주소 연결"** (Associate Elastic IP address) 클릭

   **연결 설정**:
   - **리소스 유형**: **인스턴스** 선택
   - **인스턴스**: `library-app-server` 선택 (드롭다운에서 검색)
   - **프라이빗 IP 주소**: 자동 선택됨 (기본값 유지)
   - 하단 오렌지색 **"연결"** (Associate) 버튼 클릭

3. **Elastic IP 확인**
   - EC2 대시보드 → **"인스턴스"** 메뉴
   - `library-app-server` 인스턴스 선택
   - 하단 세부 정보에서:
     - **퍼블릭 IPv4 주소**가 Elastic IP로 변경되었는지 확인
     - **탄력적 IP 주소**에도 같은 IP가 표시됨
   - ⚠️ **이 IP 주소를 메모장에 안전하게 저장하세요!** (예: 3.35.123.456)

> 💡 **중요**: Elastic IP는 EC2 인스턴스에 **연결되어 실행 중일 때만 무료**입니다.
> - ✅ 인스턴스 실행 중 + Elastic IP 연결: **무료**
> - ❌ 인스턴스 중지 상태 + Elastic IP 할당만 됨: **시간당 요금 발생**
> - 💡 사용하지 않는 Elastic IP는 반드시 릴리스(해제)하세요!

### 3.4 EC2 접속 테스트 (Windows)

EC2 인스턴스에 SSH로 접속하는 방법은 3가지가 있습니다. 편한 방법을 선택하세요.

#### 방법 1: PuTTY 사용 (권장 - .ppk 파일)

1. **PuTTY 다운로드 및 설치**
   - [PuTTY 다운로드](https://www.putty.org/) 페이지에서 설치 파일 다운로드
   - 설치 완료 후 PuTTY 실행

2. **PuTTY 설정**
   - **Session** 탭:
     - Host Name: `ubuntu@3.35.123.456` (본인의 Elastic IP 입력)
     - Port: `22`
     - Connection type: **SSH**

   - **Connection → SSH → Auth → Credentials** 탭:
     - "Private key file for authentication" 클릭
     - `C:\Users\사용자명\.ssh\library-app-key.ppk` 파일 선택

   - **Session** 탭으로 돌아가서:
     - Saved Sessions에 `library-app-server` 입력
     - **Save** 클릭 (다음부터 저장된 세션 사용 가능)

3. **접속**
   - **Open** 클릭
   - 보안 경고 창이 뜨면 **"예"** 클릭
   - 로그인 성공!

#### 방법 2: Windows PowerShell/CMD (Windows 10 1809+ 또는 Windows 11)

Windows 10(1809 이상) 및 Windows 11에는 OpenSSH 클라이언트가 기본 포함되어 있습니다.

```powershell
# PowerShell 또는 CMD에서 실행

# Elastic IP로 접속 (.pem 파일 사용)
ssh -i %USERPROFILE%\.ssh\library-app-key.pem ubuntu@3.35.123.456

# 또는 경로 직접 입력
ssh -i C:\Users\사용자명\.ssh\library-app-key.pem ubuntu@3.35.123.456

# 처음 접속 시 fingerprint 확인 메시지
# "yes" 입력
```

> 💡 **OpenSSH가 설치되지 않은 경우**:
> - Windows 설정 → 앱 → 선택적 기능 → 기능 추가
> - "OpenSSH 클라이언트" 검색하여 설치

#### 방법 3: Git Bash 사용

Git for Windows를 설치한 경우 Git Bash를 사용할 수 있습니다.

```bash
# Git Bash에서 실행

# Elastic IP로 접속
ssh -i ~/.ssh/library-app-key.pem ubuntu@3.35.123.456

# 처음 접속 시 fingerprint 확인
# "yes" 입력
```

#### 접속 확인

접속에 성공하면 다음과 같이 확인합니다:

```bash
# 환영 메시지 확인
ubuntu@ip-172-31-x-x:~$

# 초기화 완료 확인
cat init-complete.txt
# 출력: EC2 initialization completed

# Docker 설치 확인
docker --version
# Docker version 24.x.x

docker compose version
# Docker Compose version v2.x.x
```

> 📝 **접속 문제 해결**:
> - PuTTY 사용 시 "Network error: Connection refused"
>   → EC2 보안 그룹에서 본인 IP가 SSH 허용되어 있는지 확인
> - "Permission denied (publickey)"
>   → .ppk 또는 .pem 파일 경로 확인
> - PowerShell에서 권한 오류
>   → .pem 파일을 사용하고 파일 경로에 공백이 없는지 확인

### 3.5 RDS 보안 그룹 업데이트

이제 EC2에서만 RDS에 접근할 수 있도록 보안 그룹을 업데이트합니다.

1. **EC2 보안 그룹 ID 확인**
   - EC2 대시보드 → Instances → `library-app-server` 선택
   - "Security" 탭 → Security groups의 **sg-xxxxxxxxx** 복사

2. **RDS 보안 그룹 업데이트**
   - EC2 대시보드 → "Security Groups"
   - `library-rds-sg` 선택
   - "Inbound rules" → "Edit inbound rules"
   - MySQL/Aurora 규칙 수정:
     ```
     Type: MySQL/Aurora
     Protocol: TCP
     Port: 3306
     Source: Custom → EC2 보안 그룹 ID (sg-xxxxxxxxx) 입력
     Description: Allow from EC2 app server
     ```
   - "Save rules"

3. **연결 테스트 (EC2에서)**
   ```bash
   # EC2에 SSH 접속 후
   sudo apt-get install -y mysql-client

   # RDS 연결 테스트
   mysql -h library-db.xxxxxx.ap-northeast-2.rds.amazonaws.com \
     -P 3306 \
     -u admin \
     -p

   # 암호 입력: LibraryAdmin2024!

   # 연결 성공 시
   mysql> SHOW DATABASES;
   +--------------------+
   | Database           |
   +--------------------+
   | information_schema |
   | librarydb          |
   | mysql              |
   | performance_schema |
   | sys                |
   +--------------------+

   mysql> USE librarydb;
   mysql> exit;
   ```

---

## 4단계: Docker 및 애플리케이션 배포

### 4.1 환경 변수 설정

1. **EC2에 SSH 접속**
   ```bash
   ssh -i ~/.ssh/library-app-key.pem ubuntu@<YOUR-ELASTIC-IP>
   ```

2. **환경 변수 파일 생성**
   ```bash
   cd /home/ubuntu/app
   nano .env
   ```

3. **환경 변수 입력**
   ```bash
   # Spring Profile
   SPRING_PROFILES_ACTIVE=prod

   # Database Configuration
   DB_URL=jdbc:mysql://library-db.xxxxxx.ap-northeast-2.rds.amazonaws.com:3306/librarydb?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul&characterEncoding=UTF-8
   DB_USERNAME=admin
   DB_PASSWORD=LibraryAdmin2024!

   # File Upload
   FILE_UPLOAD_DIR=/home/ubuntu/app/uploads

   # Application Port
   SERVER_PORT=8081
   ```

   - Ctrl+O (저장), Enter, Ctrl+X (종료)

4. **환경 변수 권한 설정**
   ```bash
   chmod 600 .env
   ```

### 4.2 Docker Compose 파일 생성 (프로덕션용)

1. **docker-compose.prod.yml 생성**
   ```bash
   nano docker-compose.prod.yml
   ```

2. **내용 입력**
   ```yaml
   version: "3.8"

   services:
     app:
       image: <YOUR-DOCKER-HUB-USERNAME>/library-management-system:latest
       container_name: library-app
       env_file:
         - .env
       environment:
         - SPRING_PROFILES_ACTIVE=${SPRING_PROFILES_ACTIVE}
         - DB_URL=${DB_URL}
         - DB_USERNAME=${DB_USERNAME}
         - DB_PASSWORD=${DB_PASSWORD}
         - FILE_UPLOAD_DIR=/app/uploads
       ports:
         - "8081:8081"
       volumes:
         - ./uploads:/app/uploads
         - ./logs:/app/logs
       restart: unless-stopped
       healthcheck:
         test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8081/actuator/health"]
         interval: 30s
         timeout: 10s
         retries: 3
         start_period: 60s
   ```

### 4.3 수동 배포 (첫 배포)

1. **로컬에서 Docker 이미지 빌드**
   ```bash
   # 로컬 개발 환경에서
   cd library-management-system-39

   # Docker 이미지 빌드
   docker build -t library-management-system:latest .

   # 이미지 확인
   docker images | grep library
   ```

2. **Docker Hub에 푸시** (또는 GitHub Container Registry)
   ```bash
   # Docker Hub 로그인
   docker login
   # Username: <your-username>
   # Password: <your-password>

   # 이미지 태그
   docker tag library-management-system:latest <your-username>/library-management-system:latest

   # 푸시
   docker push <your-username>/library-management-system:latest
   ```

3. **EC2에서 이미지 다운로드 및 실행**
   ```bash
   # EC2에 SSH 접속
   cd /home/ubuntu/app

   # Docker 이미지 다운로드
   docker pull <your-username>/library-management-system:latest

   # 애플리케이션 실행
   docker compose -f docker-compose.prod.yml up -d

   # 로그 확인
   docker compose logs -f app

   # Ctrl+C로 로그 보기 종료
   ```

4. **애플리케이션 확인**
   ```bash
   # 컨테이너 상태 확인
   docker ps

   # Health check 확인
   curl http://localhost:8081/actuator/health
   # {"status":"UP"}

   # 브라우저에서 접속
   # http://<YOUR-ELASTIC-IP>:8081
   ```

### 4.4 배포 스크립트 작성

향후 배포를 위한 자동화 스크립트를 작성합니다.

1. **배포 스크립트 생성**
   ```bash
   nano deploy.sh
   ```

2. **스크립트 내용**
   ```bash
   #!/bin/bash

   # 배포 스크립트
   set -e

   echo "=========================================="
   echo "Library Management System Deployment"
   echo "=========================================="

   # 변수 설정
   APP_DIR="/home/ubuntu/app"
   DOCKER_IMAGE="<your-username>/library-management-system:latest"
   COMPOSE_FILE="docker-compose.prod.yml"

   cd $APP_DIR

   echo "[1/5] Pulling latest Docker image..."
   docker pull $DOCKER_IMAGE

   echo "[2/5] Stopping current application..."
   docker compose -f $COMPOSE_FILE down || true

   echo "[3/5] Removing old containers and images..."
   docker container prune -f
   docker image prune -f

   echo "[4/5] Starting new application..."
   docker compose -f $COMPOSE_FILE up -d

   echo "[5/5] Waiting for application to be healthy..."
   sleep 30

   # Health check
   for i in {1..10}; do
     if curl -f http://localhost:8081/actuator/health > /dev/null 2>&1; then
       echo "✅ Application is healthy!"
       docker compose -f $COMPOSE_FILE ps
       echo ""
       echo "=========================================="
       echo "Deployment completed successfully!"
       echo "=========================================="
       exit 0
     fi
     echo "Waiting for application... ($i/10)"
     sleep 10
   done

   echo "❌ Application health check failed!"
   echo "Checking logs..."
   docker compose -f $COMPOSE_FILE logs --tail=50
   exit 1
   ```

3. **실행 권한 부여**
   ```bash
   chmod +x deploy.sh
   ```

4. **테스트**
   ```bash
   ./deploy.sh
   ```

---

## 5단계: GitHub Actions CI/CD 설정

### 5.1 GitHub Secrets 설정

1. **GitHub 저장소 접속**
   - https://github.com/<your-username>/library-management-system-39

2. **Settings → Secrets and variables → Actions**
   - "New repository secret" 클릭

3. **필요한 Secrets 추가**

   | Secret 이름 | 값 | 설명 |
   |-------------|-----|------|
   | `DOCKERHUB_USERNAME` | your-dockerhub-username | Docker Hub 사용자명 |
   | `DOCKERHUB_TOKEN` | your-dockerhub-token | Docker Hub 액세스 토큰 |
   | `EC2_HOST` | 3.35.123.456 | EC2 Elastic IP |
   | `EC2_USERNAME` | ubuntu | EC2 사용자명 |
   | `EC2_SSH_KEY` | (pem 파일 내용 전체) | EC2 SSH 프라이빗 키 |
   | `DB_URL` | jdbc:mysql://... | RDS 엔드포인트 URL |
   | `DB_USERNAME` | admin | RDS 사용자명 |
   | `DB_PASSWORD` | LibraryAdmin2024! | RDS 비밀번호 |

4. **Docker Hub Access Token 생성**
   - https://hub.docker.com/settings/security
   - "New Access Token" 클릭
   - 설명: "GitHub Actions CI/CD"
   - 생성된 토큰 복사 → GitHub Secret에 추가

5. **SSH Key 복사**
   ```bash
   # Mac/Linux
   cat ~/.ssh/library-app-key.pem

   # 전체 내용 복사 (-----BEGIN ... END----- 포함)
   ```

### 5.2 GitHub Actions 워크플로우 파일 생성

이 섹션은 다음 작업에서 실제 파일로 생성됩니다.

---

## 운영 및 모니터링

### 로그 확인

```bash
# 실시간 로그 확인
docker compose -f docker-compose.prod.yml logs -f app

# 최근 100줄 로그 확인
docker compose -f docker-compose.prod.yml logs --tail=100 app

# 애플리케이션 로그 파일 확인
tail -f /home/ubuntu/app/logs/library-system.log
```

### 애플리케이션 재시작

```bash
# 재시작
docker compose -f docker-compose.prod.yml restart app

# 중지 후 시작
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

### 데이터베이스 백업

```bash
# EC2에서 실행
mysqldump -h library-db.xxxxxx.ap-northeast-2.rds.amazonaws.com \
  -u admin \
  -p librarydb > backup_$(date +%Y%m%d_%H%M%S).sql

# 백업 파일 확인
ls -lh backup_*.sql
```

### 모니터링

1. **CloudWatch 대시보드**
   - EC2 CPU, 네트워크, 디스크 사용량
   - RDS CPU, 연결 수, 스토리지

2. **애플리케이션 Health Check**
   ```bash
   curl http://localhost:8081/actuator/health
   ```

3. **디스크 사용량 확인**
   ```bash
   df -h
   ```

---

## 비용 절감 팁

### 1. 프리티어 사용량 모니터링
- AWS Billing Dashboard에서 일일 확인
- Free Tier Usage 대시보드 활용

### 2. 불필요한 리소스 정리
```bash
# Docker 정리
docker system prune -a -f

# 오래된 로그 삭제
find /home/ubuntu/app/logs -name "*.log" -mtime +7 -delete
```

### 3. EC2 인스턴스 최적화
- Swap 메모리 설정 (t2.micro 1GB RAM 부족 시)
  ```bash
  sudo fallocate -l 1G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  ```

### 4. RDS 백업 관리
- 7일 보존 기간으로 설정 (프리티어 20GB 범위 내)
- 불필요한 스냅샷 삭제

### 5. 사용하지 않을 때 중지
- ⚠️ EC2 중지 시 Elastic IP 비용 발생 주의
- 개발/테스트 환경에서만 사용

---

## 문제 해결

### 1. 애플리케이션이 시작되지 않음

```bash
# 로그 확인
docker compose logs app

# 일반적인 원인:
# - RDS 연결 실패: 보안 그룹 확인
# - 환경 변수 오류: .env 파일 확인
# - 메모리 부족: docker stats 확인
```

### 2. RDS 연결 실패

```bash
# 연결 테스트
mysql -h <RDS-ENDPOINT> -u admin -p

# 보안 그룹 확인
# - RDS 보안 그룹 인바운드 규칙에 EC2 보안 그룹 ID 추가됐는지 확인
# - EC2와 RDS가 같은 VPC에 있는지 확인
```

### 3. 메모리 부족

```bash
# 메모리 사용량 확인
free -h
docker stats

# Swap 메모리 추가 (위 "비용 절감 팁" 참조)
```

### 4. 포트 접속 불가

```bash
# 방화벽 확인
sudo ufw status

# 보안 그룹 확인
# - EC2 보안 그룹 인바운드 규칙에 8081 포트 추가됐는지 확인

# 컨테이너 포트 확인
docker port library-app
```

### 5. 디스크 공간 부족

```bash
# 디스크 사용량 확인
df -h

# Docker 정리
docker system prune -a --volumes -f

# 오래된 로그 삭제
sudo find /var/log -name "*.log" -mtime +7 -delete
```

### 6. GitHub Actions 배포 실패

- **SSH 연결 실패**: `EC2_SSH_KEY` Secret 확인 (전체 내용 포함)
- **Docker 이미지 빌드 실패**: Dockerfile 문법 확인
- **권한 오류**: EC2에서 `ubuntu` 사용자가 `docker` 그룹에 속해 있는지 확인

---

## 다음 단계

### 성능 최적화
1. Nginx 리버스 프록시 설정
2. SSL/TLS 인증서 설정 (Let's Encrypt)
3. CloudFront CDN 연동 (정적 파일 제공)

### 보안 강화
1. AWS Systems Manager Session Manager 사용 (SSH 대신)
2. RDS SSL 연결 활성화
3. 환경 변수를 AWS Secrets Manager로 이관

### 고가용성
1. RDS Multi-AZ 배포 (프리티어 이후)
2. EC2 Auto Scaling Group 설정
3. Application Load Balancer 추가

---

## 참고 자료

- [AWS 프리티어 가이드](https://aws.amazon.com/ko/free/)
- [AWS EC2 문서](https://docs.aws.amazon.com/ec2/)
- [AWS RDS 문서](https://docs.aws.amazon.com/rds/)
- [Docker 공식 문서](https://docs.docker.com/)
- [Spring Boot 배포 가이드](https://spring.io/guides/gs/spring-boot-docker/)

---

**작성일**: 2025-11-13
**버전**: 1.0.0
**유지보수**: 정기적으로 업데이트됩니다.
