# Fundit 2.1 환경 설정 및 실행 가이드

## 1. 가상환경 설정

### 1.1 가상환경 생성 및 활성화

```bash
# 프로젝트 루트 디렉토리에서 실행

# 1. LLM 모듈용 가상환경 (.llm_env)
python -m venv .llm_env
source .llm_env/bin/activate  # Linux/Mac
# 또는
.\.llm_env\Scripts\activate  # Windows

# 2. 백엔드용 가상환경 (.venv)
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# 또는
.\.venv\Scripts\activate  # Windows
```

### 1.2 필요한 라이브러리 설치

#### LLM 모듈 (.llm_env)

```bash
# .llm_env 활성화 상태에서
pip install -U pip
pip install langchain openai faiss-cpu python-dotenv fastapi uvicorn httpx pandas numpy scikit-learn

# 현재 환경의 패키지 목록을 requirements.txt로 저장
pip freeze > requirements.txt
```

### 1.3 requirements.txt를 이용한 환경 설정

이미 requirements.txt 파일이 있는 경우, 다음 명령어로 필요한 모든 패키지를 한 번에 설치할 수 있습니다:

```bash
# 가상환경 활성화 상태에서
pip install -r requirements.txt
```

#### 백엔드 (.venv)

```bash
# .venv 활성화 상태에서
pip install -U pip
pip install fastapi uvicorn sqlalchemy psycopg2-binary python-dotenv httpx openai
```

## 2. 환경 변수 설정

프로젝트 루트에 `.env` 파일을 생성하고 다음 내용을 추가:

```
# OpenAI API 키
OPENAI_API_KEY=your_openai_api_key_here

# 데이터베이스 설정
DATABASE_URL=postgresql://username:password@localhost:5432/fundit

# RAG API 설정
RAG_API_URL=http://localhost:8001
```

## 3. 프론트엔드 환경 설정

### 3.1 Node.js 및 npm 설치 (NVM 사용)

프로젝트에 필요한 버전:
- Node.js: v23.7.0
- npm: 10.9.2

```bash
# NVM 설치
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

# 셸 설정 다시 로드
source ~/.bashrc  # 또는 source ~/.zshrc

# 특정 Node.js 버전 설치
nvm install 23.7.0

# 설치된 버전 사용하도록 설정
nvm use 23.7.0

# 설치 확인
node -v  # v23.7.0 출력 확인
npm -v   # 10.9.2 출력 확인
```

### 3.2 프론트엔드 프로젝트 설정

```bash
# 프로젝트 디렉토리로 이동
cd frontend

# 의존성 패키지 설치
npm install

# 개발 서버 실행 (브라우저 자동 열기 없이)
BROWSER=none npm start
```

> **참고**: Node.js v23.7.0은 최신 버전이므로 설치에 문제가 있을 경우 `nvm ls-remote` 명령어로 사용 가능한 버전을 확인하고, 가장 가까운 버전(예: `nvm install 23` 또는 `nvm install 23.6.0`)을 선택할 수 있습니다.

## 4. 서버 실행 방법

### 4.1 RAG API 서버 실행

```bash
# LLM 가상환경 활성화
source .llm_env/bin/activate  # Linux/Mac
# 또는
.\.llm_env\Scripts\activate  # Windows

# RAG API 서버 실행
cd LLM/rag
chmod +x run_api_server.sh  # 실행 권한 부여 (Linux/Mac만 해당)
./run_api_server.sh  # Linux/Mac
# 또는
sh run_api_server.sh  # Windows
```

RAG API 서버는 `http://localhost:8001`에서 실행됩니다.

### 4.2 백엔드 서버 실행

```bash
# 백엔드 가상환경 활성화
source .venv/bin/activate  # Linux/Mac
# 또는
.\.venv\Scripts\activate  # Windows

# 백엔드 서버 실행
cd backend
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

백엔드 서버는 `http://localhost:8000`에서 실행됩니다.

## 5. 주요 모듈 구조

### 5.1 RAG 시스템 구조

```
LLM/
└── rag/
    ├── api.py            # RAG API 서버
    ├── main.py           # RAG 시스템 메인 로직
    ├── processors.py     # 데이터 처리 로직
    └── run_api_server.sh # 서버 실행 스크립트
```

### 5.2 백엔드 구조

```
backend/
├── app/
│   ├── api/              # API 엔드포인트
│   │   ├── chat.py       # 채팅 관련 API
│   │   └── ...
│   ├── services/         # 서비스 모듈
│   │   ├── rag_service.py # RAG 연동 서비스
│   │   └── ...
│   ├── core/             # 핵심 설정
│   ├── models/           # 데이터베이스 모델
│   └── schemas/          # Pydantic 스키마
└── ...
```

## 6. 문제 해결

### 6.1 RAG API 서버 문제

- **500 Internal Server Error**: main.py에서 반환 타입과 api.py에서 기대하는 타입이 일치하는지 확인
- **토큰 제한 초과**: chat.py에서 RAG 결과 개수를 제한하여 토큰 사용량 감소

### 6.2 가상환경 문제

- 가상환경을 찾을 수 없는 경우: 정확한 경로에 가상환경이 있는지 확인
- 라이브러리 충돌: 가상환경을 새로 생성하고 필요한 라이브러리만 설치

## 7. 컴포넌트 간 통신 흐름

1. 클라이언트 → 백엔드 API (8000포트)
2. 백엔드 → RAG API (8001포트)
3. RAG API → 벡터 저장소 (FAISS)
4. RAG API → 백엔드 → LLM (OpenAI/OpenChat)
5. 백엔드 → 클라이언트 (응답 반환) 


엘리스 포트포워딩

elicer@cdced32c66eb:~/Fundit_2.1$ ssh -L 3000:localhost:3000 -i "/Users/jejinan/Downloads/elice-cloud-ondemand-fd1e0d34-838b-4f37-9513-565485d8b788.pem" -p 44171 elicer@14.35.173.14