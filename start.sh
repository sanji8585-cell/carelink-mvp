#!/bin/bash
# ============================================
#  CareLink MVP 원클릭 실행 스크립트
#  사용법: bash start.sh
# ============================================

set -e

echo ""
echo "🏥 =============================="
echo "   CareLink MVP 시작합니다!"
echo "   =============================="
echo ""

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1단계: 필수 도구 확인
echo "📋 1단계: 필수 도구 확인 중..."
echo ""

check_tool() {
  if command -v $1 &> /dev/null; then
    echo -e "  ✅ $1 설치됨: $($1 --version 2>&1 | head -1)"
    return 0
  else
    echo -e "  ${RED}❌ $1 가 설치되어 있지 않습니다!${NC}"
    echo "     👉 $2"
    return 1
  fi
}

MISSING=0
check_tool "node" "https://nodejs.org 에서 설치하세요" || MISSING=1
check_tool "npm" "Node.js 설치 시 함께 설치됩니다" || MISSING=1
check_tool "docker" "https://docker.com 에서 Docker Desktop을 설치하세요" || MISSING=1

echo ""

if [ $MISSING -eq 1 ]; then
  echo -e "${RED}❌ 위의 도구를 먼저 설치한 후 다시 실행해주세요.${NC}"
  exit 1
fi

# Docker 실행 중인지 확인
if ! docker info &> /dev/null; then
  echo -e "${RED}❌ Docker Desktop이 실행 중이 아닙니다!${NC}"
  echo "   👉 Docker Desktop 앱을 먼저 실행해주세요."
  echo "   👉 실행 후 30초 정도 기다린 다음 이 스크립트를 다시 실행하세요."
  exit 1
fi

echo -e "${GREEN}✅ 모든 도구가 준비되었습니다!${NC}"
echo ""

# 2단계: 데이터베이스 시작
echo "📋 2단계: 데이터베이스 시작 중... (처음이면 1~2분 걸립니다)"
echo ""

docker compose up -d

echo ""
echo "  ⏳ 데이터베이스가 준비될 때까지 기다리는 중..."
sleep 5

# DB 준비 확인
for i in {1..20}; do
  if docker compose exec -T db pg_isready -U carelink &> /dev/null; then
    echo -e "  ${GREEN}✅ 데이터베이스 준비 완료!${NC}"
    break
  fi
  if [ $i -eq 20 ]; then
    echo -e "  ${RED}❌ 데이터베이스 시작 실패. Docker Desktop이 실행 중인지 확인하세요.${NC}"
    exit 1
  fi
  sleep 2
done

echo ""

# 3단계: 백엔드 설치 및 실행
echo "📋 3단계: 백엔드 서버 준비 중..."
echo ""

cd backend

# npm 패키지 설치
if [ ! -d "node_modules" ]; then
  echo "  📦 패키지 설치 중... (처음이면 1~2분 걸립니다)"
  npm install 2>&1 | tail -1
else
  echo "  📦 패키지가 이미 설치되어 있습니다."
fi

echo ""

# Prisma 클라이언트 생성 + 마이그레이션
echo "  🗄️ 데이터베이스 테이블 생성 중..."
npx prisma generate 2>&1 | tail -1
npx prisma migrate dev --name init --skip-generate 2>&1 | tail -3

echo ""

# 시드 데이터
echo "  🌱 테스트 데이터 삽입 중..."
npx tsx scripts/seed.ts 2>&1

echo ""

# 서버 시작
echo "📋 4단계: 서버를 시작합니다!"
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  🚀 CareLink 서버가 시작됩니다!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  🌐 API 서버:  http://localhost:3000"
echo "  🏥 헬스체크:  http://localhost:3000/health"
echo ""
echo "  📋 테스트 계정:"
echo "    이메일: kim.minjun@example.com"
echo "    비밀번호: test1234"
echo ""
echo "  🛑 종료하려면: Ctrl+C"
echo ""

npm run dev
