# CareLink MVP - AI 노인돌봄 플랫폼

## 프로젝트 구조

```
carelink/
├── backend/          # Node.js API 서버
│   ├── src/
│   │   ├── routes/   # API 라우트
│   │   ├── models/   # DB 모델 (Prisma)
│   │   ├── services/ # 비즈니스 로직
│   │   ├── middleware/# 인증, 에러 핸들링
│   │   └── config/   # 환경설정
│   └── scripts/      # DB 시딩, 마이그레이션
├── flutter_app/      # Flutter 듀얼 앱 (부모님 + 자녀)
│   └── lib/
│       ├── screens/  # 화면별 위젯
│       ├── services/ # API, AI, 센서 서비스
│       ├── models/   # 데이터 모델
│       └── widgets/  # 공용 위젯
├── admin_web/        # 관리자 웹 대시보드
└── docs/             # API 문서, 설계 문서
```

## 기술 스택

| 영역 | 기술 |
|------|------|
| 모바일 앱 | Flutter 3.x (Dart) |
| 백엔드 | Node.js + Express + TypeScript |
| 데이터베이스 | PostgreSQL + Prisma ORM |
| 캐시/큐 | Redis |
| AI 대화 | Claude API (Anthropic) |
| 음성 | Whisper (STT) + Edge TTS |
| 푸시 알림 | Firebase Cloud Messaging |
| 클라우드 | AWS (Seoul Region) |
| 관리자 | React (Vite) |

## 빠른 시작

### 1. 백엔드
```bash
cd backend
npm install
cp .env.example .env  # 환경변수 설정
npx prisma migrate dev
npm run seed
npm run dev
```

### 2. Flutter 앱
```bash
cd flutter_app
flutter pub get
flutter run
```

### 3. 관리자 웹
```bash
cd admin_web
npm install
npm run dev
```

## MVP 기능 범위

### 부모님 앱
- [x] AI 말벗 대화 (Claude API + 음성)
- [x] 걸음수 추적 (가속도계)
- [x] 약 복용 알림 및 확인
- [x] 긴급 SOS 버튼
- [x] 초간단 대형 UI

### 자녀 앱
- [x] 실시간 건강 대시보드
- [x] AI 주간 리포트
- [x] 이상 징후 푸시 알림
- [x] 부모님 영상통화
- [x] 약 복용 현황 확인

### 백엔드
- [x] JWT 인증 (자녀 회원가입/로그인)
- [x] 부모님-자녀 연결 (초대 코드)
- [x] AI 대화 API (Claude 연동)
- [x] 건강 데이터 수집/분석 API
- [x] 푸시 알림 (FCM)
- [x] 주간 리포트 자동 생성

## 환경 변수

```env
DATABASE_URL=postgresql://user:pass@localhost:5432/carelink
REDIS_URL=redis://localhost:6379
ANTHROPIC_API_KEY=sk-ant-xxx
FCM_SERVER_KEY=xxx
JWT_SECRET=xxx
```
