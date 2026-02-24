@echo off
chcp 65001 >nul
echo.
echo 🏥 ==============================
echo    CareLink MVP 시작합니다!
echo    ==============================
echo.

REM 1단계: 필수 도구 확인
echo 📋 1단계: 필수 도구 확인 중...
echo.

where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   ❌ Node.js가 설치되어 있지 않습니다!
    echo      👉 https://nodejs.org 에서 설치하세요
    pause
    exit /b 1
)
echo   ✅ Node.js 설치됨

where docker >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   ❌ Docker가 설치되어 있지 않습니다!
    echo      👉 https://docker.com 에서 Docker Desktop을 설치하세요
    pause
    exit /b 1
)
echo   ✅ Docker 설치됨

echo.

REM 2단계: 데이터베이스 시작
echo 📋 2단계: 데이터베이스 시작 중... (처음이면 1~2분 걸립니다)
echo.
docker compose up -d
echo.
echo   ⏳ 데이터베이스 준비 대기 중...
timeout /t 8 /nobreak >nul
echo   ✅ 데이터베이스 시작됨
echo.

REM 3단계: 백엔드 설치 및 실행
echo 📋 3단계: 백엔드 서버 준비 중...
echo.
cd backend

if not exist "node_modules" (
    echo   📦 패키지 설치 중... (처음이면 1~2분 걸립니다)
    call npm install
) else (
    echo   📦 패키지가 이미 설치되어 있습니다.
)

echo.
echo   🗄️ 데이터베이스 테이블 생성 중...
call npx prisma generate
call npx prisma migrate dev --name init --skip-generate

echo.
echo   🌱 테스트 데이터 삽입 중...
call npx tsx scripts/seed.ts

echo.
echo ============================================
echo   🚀 CareLink 서버가 시작됩니다!
echo ============================================
echo.
echo   🌐 API 서버:  http://localhost:3000
echo   🏥 헬스체크:  http://localhost:3000/health
echo.
echo   📋 테스트 계정:
echo     이메일: kim.minjun@example.com
echo     비밀번호: test1234
echo.
echo   🛑 종료하려면: Ctrl+C
echo.

call npm run dev
pause
