#!/bin/bash

# 압축 파일 이름
ARCHIVE_NAME="Fundit_2.4.1_$(date +%Y%m%d).tar.gz"

# 현재 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "프로젝트 압축 시작..."
echo "제외 항목: OpenChat 모델(.gguf 파일), 가상환경(.llm_env)"

# tar 명령어로 압축하면서 특정 파일/디렉토리 제외
tar --exclude="Fundit_2.1/LLM/*.gguf" \
    --exclude="Fundit_2.1/LLM/.llm_env" \
    --exclude="Fundit_2.1/.llm_env" \
    --exclude="Fundit_2.1/__pycache__" \
    --exclude="Fundit_2.1/**/__pycache__" \
    --exclude="Fundit_2.1/logs" \
    --exclude="Fundit_2.1/**/logs" \
    --exclude="*.log" \
    --exclude="*.pid" \
    -czf "$ARCHIVE_NAME" Fundit_2.1

echo "압축 완료: $ARCHIVE_NAME ($(du -h "$ARCHIVE_NAME" | cut -f1))"
echo "압축 파일 위치: $(pwd)/$ARCHIVE_NAME"

# 압축 내용물 간략히 보기
echo ""
echo "압축 파일 내용 (상위 디렉토리만):"
tar -tf "$ARCHIVE_NAME" | grep -v "/" | sort | uniq
echo "..."
tar -tf "$ARCHIVE_NAME" | grep -E "^Fundit_2.1/[^/]+/$" | sort | uniq 