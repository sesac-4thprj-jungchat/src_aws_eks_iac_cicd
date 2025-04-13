<<<<<<< HEAD
# front
=======
# final_project
>>>>>>> 18e86af ("feat 회원가입 창 메인 화면창, 마이페이지 구현2")

# Fundit_2.1 프로젝트

## 프로젝트 압축 및 재구성 방법

프로젝트를 압축할 때는 OpenChat 모델과 가상환경을 제외하여 용량을 크게 줄일 수 있습니다. 

### 프로젝트 압축

1. 제공된 `compress_project.sh` 스크립트를 실행합니다:
```bash
./compress_project.sh
```

이 스크립트는 다음 항목들을 제외하고 압축합니다:
- LLM 모델 파일 (*.gguf)
- OpenChat 관련 모델 파일
- 가상환경 디렉토리 (.llm_env)
- 캐시 파일 (__pycache__)
- 로그 파일 및 디렉토리

### 프로젝트 재구성

압축 해제 후 프로젝트를 실행하려면 다음 단계를 따르세요:

1. 압축 파일 해제:
```bash
tar -xzf Fundit_2.1_YYYYMMDD.tar.gz
```

2. OpenChat 모델 다운로드 (필요한 경우):
```bash
cd Fundit_2.1/LLM
wget https://huggingface.co/TheBloke/OpenChat-3.5-7B-Mixtral-v2.0-GGUF/resolve/main/openchat-3.5-7b-mixtral-v2.0.i1-q4_k_m.gguf -O OpenChat-3.5-7B-Mixtral-v2.0.i1-Q4_K_M.gguf
```

3. 가상환경 설정:
```bash
cd Fundit_2.1
python -m venv .llm_env
source .llm_env/bin/activate
pip install -r requirements.txt  # requirements.txt가 있는 경우
```

4. 서비스 실행:
```bash
cd LLM
./run_llm_service.sh  # GPU 모드 (기본값)
# 또는
./run_llm_service.sh --cpu  # CPU 모드
```

# ‼️💡 Commit Convention
`Feat`	새로운 기능을 추가

`Fix`	버그 수정

`Design`	CSS 등 사용자 UI 디자인 변경

`!BREAKING CHANGE`	커다란 API 변경의 경우

`!HOTFIX`	급하게 치명적인 버그를 고쳐야하는 경우

`Style`	코드 포맷 변경, 세미 콜론 누락, 코드 수정이 없는 경우

`Refactor`	프로덕션 코드 리팩토링

`Comment`	필요한 주석 추가 및 변경

`Docs`	문서 수정

`Test`	테스트 코드, 리펙토링 테스트 코드 추가, Production Code(실제로 사용하는 코드) 변경 없음

`Chore`	빌드 업무 수정, 패키지 매니저 수정, 패키지 관리자 구성 등 업데이트, Production Code 변경 없음

`Rename`	파일 혹은 폴더명을 수정하거나 옮기는 작업만인 경우

`Remove`	파일을 삭제하는 작업만 수행한 경우
