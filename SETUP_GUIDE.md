# 🏥 CareLink MVP 설치 가이드 (완전 초보용)

> 컴퓨터를 잘 모르셔도 괜찮습니다. 아래 순서대로만 따라하시면 됩니다!

---

## 📌 시작하기 전에: 이 4가지가 설치되어 있어야 합니다

| 프로그램 | 왜 필요한가요? | 다운로드 링크 |
|---------|--------------|-------------|
| **Node.js** | 서버를 실행하는 프로그램 | https://nodejs.org (LTS 버전 다운로드) |
| **Docker Desktop** | 데이터베이스를 쉽게 실행 | https://www.docker.com/products/docker-desktop/ |
| **Git** | 코드 관리 도구 | https://git-scm.com |
| **VS Code** (선택) | 코드를 보고 편집하는 프로그램 | https://code.visualstudio.com |

> 💡 Flutter는 나중에 앱을 만들 때 필요합니다. 지금은 백엔드(서버)부터 실행해볼 거예요.

설치 확인 방법은 아래 [부록 A]를 참고하세요.

---

## 🚀 실행 방법 (5단계)

### 1단계: zip 파일 압축 풀기

1. 다운로드 받은 `carelink_mvp_project.zip` 파일을 찾습니다
2. 바탕화면이나 원하는 폴더에 압축을 풉니다
3. `carelink` 폴더가 생깁니다

---

### 2단계: 터미널(명령 프롬프트) 열기

**Windows:**
- `carelink` 폴더를 열고
- 폴더 안의 빈 공간에서 **마우스 오른쪽 클릭**
- **"터미널에서 열기"** 또는 **"여기서 PowerShell 열기"** 클릭

**Mac:**
- `carelink` 폴더를 찾고
- 폴더를 **오른쪽 클릭** → **"폴더에서 터미널 열기"**
- 또는: Finder에서 폴더 열기 → 상단 메뉴 **"서비스"** → **"폴더에서 터미널 열기"**

> 💡 VS Code를 쓰시면 더 쉽습니다:
> 1. VS Code 실행
> 2. 파일 → 폴더 열기 → `carelink` 폴더 선택
> 3. 상단 메뉴에서 **터미널 → 새 터미널** 클릭

---

### 3단계: Docker Desktop 실행하기

1. **Docker Desktop** 앱을 실행합니다 (시작 메뉴 또는 앱 목록에서)
2. Docker Desktop이 완전히 로딩될 때까지 기다립니다 (30초~1분)
3. 화면 왼쪽 하단에 **초록색 "Engine running"** 이 보이면 준비 완료!

> ⚠️ Docker Desktop이 실행 중이 아니면 다음 단계가 실패합니다!

---

### 4단계: 원클릭 실행!

터미널에 아래 명령어를 **복사해서 붙여넣기** 하세요:

**Windows (PowerShell):**
```
.\start.bat
```

**Mac / Linux:**
```
bash start.sh
```

> 💡 처음 실행할 때는 2~3분 걸립니다. (필요한 파일들을 다운로드하기 때문)

---

### 5단계: 작동 확인!

터미널에 아래와 비슷한 메시지가 나오면 성공입니다:

```
🚀 CareLink API server running on port 3000
```

**이제 웹 브라우저(크롬 등)를 열고 주소창에 입력하세요:**

```
http://localhost:3000/health
```

아래와 비슷한 내용이 보이면 성공입니다! 🎉

```json
{"status":"ok","timestamp":"2026-02-24T...","version":"0.1.0"}
```

---

## 🧪 API 테스트하기

서버가 실행되면, 아래 주소들을 브라우저에 입력하거나 터미널에서 테스트할 수 있습니다.

### 방법 1: 브라우저에서 확인 (가장 쉬움)

```
http://localhost:3000/health
```
→ 서버가 살아있는지 확인

### 방법 2: 터미널에서 API 테스트

**새 터미널 탭을 열고** (기존 서버는 그대로 두세요!) 아래 명령어를 실행합니다:

**로그인 테스트:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"kim.minjun@example.com","password":"test1234"}'
```

성공하면 이런 응답이 옵니다:
```json
{
  "token": "eyJhbG...(긴 문자열)",
  "user": {"id":"...", "email":"kim.minjun@example.com", "name":"김민준"}
}
```

> 💡 Windows PowerShell에서는 curl 대신 이렇게 입력하세요:
> ```powershell
> Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/auth/login" -ContentType "application/json" -Body '{"email":"kim.minjun@example.com","password":"test1234"}'
> ```

---

## 🛑 서버 끄는 법

터미널에서 **Ctrl + C** 를 누르면 서버가 종료됩니다.

데이터베이스도 끄려면:
```bash
docker compose down
```

다시 시작할 때는 **4단계**부터 다시 하면 됩니다.
(두 번째부터는 훨씬 빠릅니다!)

---

## ❓ 자주 나오는 에러와 해결법

### "docker: command not found"
→ Docker Desktop이 설치되지 않았거나, 설치 후 터미널을 새로 열지 않았습니다.
→ **해결:** Docker Desktop 설치 → 터미널 닫고 다시 열기

### "Cannot connect to the Docker daemon"
→ Docker Desktop 앱이 실행 중이 아닙니다.
→ **해결:** Docker Desktop 앱을 실행하고 30초 기다린 후 다시 시도

### "ECONNREFUSED 127.0.0.1:5432"
→ 데이터베이스가 아직 준비되지 않았습니다.
→ **해결:** 10초 기다린 후 다시 시도. 안 되면 `docker compose up -d` 실행

### "npm ERR! code ENOENT"
→ 현재 위치가 `carelink` 폴더가 아닙니다.
→ **해결:** `cd carelink` 입력 후 다시 시도

### "prisma migrate dev" 에러
→ 데이터베이스 연결 문제입니다.
→ **해결:** `docker compose down` 후 `docker compose up -d` 실행. 10초 기다린 후 다시 시도

### 포트 3000이 이미 사용 중
→ 다른 프로그램이 3000번 포트를 쓰고 있습니다.
→ **해결:** `.env` 파일에서 `PORT=3001`로 변경

---

## 📎 부록 A: 설치 확인 방법

터미널을 열고 아래 명령어를 하나씩 입력하세요:

```bash
node --version
```
→ `v20.x.x` 같은 버전이 나오면 OK

```bash
npm --version
```
→ `10.x.x` 같은 버전이 나오면 OK

```bash
docker --version
```
→ `Docker version 27.x.x` 같은 버전이 나오면 OK

```bash
git --version
```
→ `git version 2.x.x` 같은 버전이 나오면 OK

---

## 📎 부록 B: Claude API 키 설정 (AI 대화 기능용)

AI 대화 기능을 쓰려면 Anthropic API 키가 필요합니다.

1. https://console.anthropic.com 에 가입
2. API Keys 메뉴에서 새 키 생성
3. `backend/.env` 파일을 열고 아래 줄을 수정:
```
ANTHROPIC_API_KEY=sk-ant-여기에-발급받은-키를-넣으세요
```
4. 서버 재시작 (Ctrl+C로 끄고 다시 `npm run dev`)

> API 키가 없어도 나머지 기능(걸음수, 복약, SOS, 대시보드)은 모두 작동합니다!

---

## 📎 부록 C: 다음 단계

서버가 잘 돌아가면, 다음으로 할 수 있는 것들:

1. **Flutter 앱 실행** - 실제 모바일 앱 화면 확인
2. **관리자 웹 대시보드** 추가
3. **API 테스트 도구(Postman)** 로 모든 API 테스트
4. **Claude Code**로 기능 추가/수정

궁금한 점이 있으면 언제든 물어보세요! 🙂
