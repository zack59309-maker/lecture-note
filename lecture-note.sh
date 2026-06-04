#!/usr/bin/env bash
# lecture-note - 录音文件 → Obsidian 笔记
# 用法: ./lecture-note.sh <录音文件> [学科名称]
# 若不传学科，自动用 LLM 识别

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV="$SCRIPT_DIR/venv"
OBSIDIAN_VAULT="/mnt/d/obsidian/zack的数学知识库"
NOTES_DIR="$OBSIDIAN_VAULT/课程笔记"
TEMP_DOWNLOAD="/mnt/c/Users/10181/Desktop/课程录音"

AUDIO_FILE="${1:-}"
SUBJECT="${2:-}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [ -z "$AUDIO_FILE" ]; then
  # 找 D:\临时下载\ 里最新的音频文件
  LATEST=$(find "$TEMP_DOWNLOAD" -maxdepth 1 \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.wav' -o -iname '*.mp4' -o -iname '*.amr' -o -iname '*.aac' \) -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  if [ -z "$LATEST" ]; then
    echo "❌ 未指定录音文件，且 桌面\\课程录音 中没有音频文件"
    exit 1
  fi
  AUDIO_FILE="$LATEST"
  echo "📁 自动选择: $AUDIO_FILE"
fi

if [ ! -f "$AUDIO_FILE" ]; then
  echo "❌ 文件不存在: $AUDIO_FILE"
  exit 1
fi

BASENAME=$(basename "$AUDIO_FILE")
STEM="${BASENAME%.*}"

echo "═══════════════════════════════════════"
echo "  录音 → Obsidian 笔记"
echo "  文件: $BASENAME"
echo "  日期: $DATE"
echo "═══════════════════════════════════════"

source "$VENV/bin/activate"

# 第一步：转录
echo ""
echo "📝 [1/3] 转录中 ..."
TRANSCRIPT_DIR="$SCRIPT_DIR/output/$TIMESTAMP"
mkdir -p "$TRANSCRIPT_DIR"
python -m cli transcribe "$AUDIO_FILE" -o "$TRANSCRIPT_DIR" 2>&1

# 第二步：如果没传学科，用 LLM 自动识别
if [ -z "$SUBJECT" ]; then
  echo ""
  echo "🔍 [2/3] 自动识别学科 ..."
  TRANSCRIPT_FILE=$(ls "$TRANSCRIPT_DIR"/*_transcript.txt 2>/dev/null | head -1)
  if [ -n "$TRANSCRIPT_FILE" ]; then
    SUBJECT=$(cd "$SCRIPT_DIR" && source venv/bin/activate && python3 detect_subject.py "$TRANSCRIPT_FILE")
    echo "  识别为: $SUBJECT"
  else
    SUBJECT="未分类"
  fi
fi

# 第三步：生成笔记并输出到 Obsidian
echo ""
echo "📄 [3/4] 生成笔记 → Obsidian ..."
SUBJECT_DIR="$NOTES_DIR/$SUBJECT"
mkdir -p "$SUBJECT_DIR"

OUTPUT_NAME="${DATE}_${STEM}"
NOTE_FILE="$SUBJECT_DIR/${OUTPUT_NAME}.md"

python -m cli process "$AUDIO_FILE" \
  -t lecture_notes \
  -c "$SUBJECT" \
  -o "$SUBJECT_DIR" \
  --format markdown 2>&1

# 重命名生成的笔记文件（CLI 可能生成默认名字）
GENERATED=$(ls -t "$SUBJECT_DIR"/*.md 2>/dev/null | head -1)
if [ -n "$GENERATED" ] && [ "$GENERATED" != "$NOTE_FILE" ]; then
  mv "$GENERATED" "$NOTE_FILE"
fi

# 添加 YAML frontmatter
if [ -f "$NOTE_FILE" ]; then
  CONTENT=$(cat "$NOTE_FILE")
  cat > "$NOTE_FILE" << NOTEEND
---
title: ${STEM}
subject: ${SUBJECT}
date: ${DATE}
source: ${BASENAME}
---

${CONTENT}
NOTEEND
  echo "  ✅ 笔记已保存: $NOTE_FILE"
else
  echo "  ⚠️  笔记文件未生成，检查 above 输出"
fi

# 更新学科索引
INDEX_FILE="$NOTES_DIR/_索引.md"
if [ ! -f "$INDEX_FILE" ]; then
  cat > "$INDEX_FILE" << 'INDEXHEAD'
# 📚 课程笔记索引

| 学科 | 笔记数 | 最后更新 |
|------|--------|----------|
INDEXHEAD
fi

COUNT=$(find "$SUBJECT_DIR" -name '*.md' ! -name '_*' | wc -l)
if grep -q "^| $SUBJECT |" "$INDEX_FILE" 2>/dev/null; then
  sed -i "s/^| $SUBJECT |.*/| $SUBJECT | $COUNT | $DATE |/" "$INDEX_FILE"
else
  echo "| $SUBJECT | $COUNT | $DATE |" >> "$INDEX_FILE"
fi

# 第四步：自动补充知识点
echo ""
echo "📖 [4/4] 自动补充知识点 ..."
if [ -f "$NOTE_FILE" ]; then
  bash "$SCRIPT_DIR/enrich-note.sh" "$NOTE_FILE" 2>&1 | grep -v "^$"
fi

echo ""
echo "═══════════════════════════════════════"
echo "  ✅ 全部完成！"
echo "   学科: $SUBJECT"
echo "   笔记: $NOTE_FILE"
echo "   索引: $INDEX_FILE"
