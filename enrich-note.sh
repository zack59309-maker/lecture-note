#!/usr/bin/env bash
# enrich-note - 自动补充笔记中不完整的知识点
# 用法: ./enrich-note.sh <笔记文件.md>
# 或: ./enrich-note.sh --auto  处理 Obsidian 里最新的笔记

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV="$SCRIPT_DIR/venv"
OBSIDIAN_VAULT="/mnt/d/obsidian/zack的数学知识库"
NOTES_DIR="$OBSIDIAN_VAULT/课程笔记"

NOTE_FILE="${1:-}"

if [ "$NOTE_FILE" = "--auto" ]; then
  NOTE_FILE=$(find "$NOTES_DIR" -name '*.md' ! -name '_*' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  if [ -z "$NOTE_FILE" ]; then
    echo "❌ 未找到笔记"
    exit 1
  fi
  echo "📄 最新笔记: $NOTE_FILE"
fi

if [ ! -f "$NOTE_FILE" ]; then
  echo "❌ 文件不存在: $NOTE_FILE"
  exit 1
fi

source "$VENV/bin/activate"

echo "═══════════════════════════════════════"
echo "  📖 笔记知识补充"
echo "  文件: $(basename "$NOTE_FILE")"
echo "═══════════════════════════════════════"

python3 << 'PYEOF'
import json, sys, os, re
from pathlib import Path
from openai import OpenAI

# 读取配置
config_path = Path.home() / ".noteking" / "config.json"
config = json.loads(config_path.read_text())

client = OpenAI(
    api_key=config["llm"]["api_key"],
    base_url=config["llm"]["base_url"]
)

note_path = sys.argv[1]
subject_dir = Path(note_path).parent
subject = subject_dir.name
note_name = Path(note_path).stem

original = Path(note_path).read_text(encoding="utf-8")

# 提取正文（去掉 YAML frontmatter）
body = original
if original.startswith("---"):
    parts = original.split("---", 2)
    if len(parts) >= 3:
        body = parts[2].strip()

print(f"\n📚 学科: {subject}")
print(f"📝 原文长度: {len(body)} 字")
print("🔍 分析知识点覆盖情况...\n")

# 第一步：让 LLM 分析笔记中哪些知识点讲得浅/缺失
analysis_prompt = """你是一位精通{subject}的大学教授。请分析下面这份课堂笔记，找出：

1. **讲得浅的概念** — 老师只提了名字或简单带过，但没有详细解释的
2. **应讲但缺失的概念** — 和本课相关、通常应该涉及但笔记中完全没提到的
3. **可补充的内容** — 典型例题、常见错误、直观理解、实际应用等

每个发现请给出：
- 概念名称
- 当前笔记中的覆盖情况（一句话）
- 建议补充什么

笔记内容：
---
{body}
---

请以JSON格式回复，格式：
[{{"concept": "...", "issue": "讲得浅/缺失/可补充", "detail": "...", "suggestion": "建议补充..."}}]
"""

resp = client.chat.completions.create(
    model=config["llm"]["model"],
    messages=[{"role": "user", "content": analysis_prompt.format(
        subject=subject, body=body[:8000]
    )}],
    temperature=0.2,
    response_format={"type": "json_object"}
)

try:
    import json as _json
    gaps = _json.loads(resp.choices[0].message.content)
    if isinstance(gaps, dict):
        # 可能是 {"gaps": [...]} 或 {"concepts": [...]}
        for k in ["gaps", "concepts", "items", "results"]:
            if k in gaps:
                gaps = gaps[k]
                break
        else:
            gaps = [gaps]
except:
    gaps = []

if not gaps or not isinstance(gaps, list):
    print("⚠️  未能识别需要补充的知识点")
    sys.exit(0)

print(f"📌 发现 {len(gaps)} 个可补充的知识点:\n")
for i, g in enumerate(gaps, 1):
    icon = {"讲得浅": "🟡", "缺失": "🔴", "可补充": "🟢"}.get(g.get("issue", ""[:3]), "⚪")
    print(f"  {icon} [{i}] {g.get('concept', '?')}")
    print(f"     问题: {g.get('detail', '')[:80]}")

print("\n📖 正在补充知识点...\n")

# 第二步：逐条补充
supplements = []
for i, g in enumerate(gaps, 1):
    concept = g.get("concept", "")
    issue_type = g.get("issue", "")
    suggestion = g.get("suggestion", "")

    print(f"  [{i}/{len(gaps)}] {concept}...")

    if issue_type == "缺失":
        prompt = f"""你是一位精通{subject}的大学教授。学生的课堂笔记中完全没有涉及「{concept}」这个知识点。
请撰写一段约200-300字的补充内容，包括：
1. 这个概念的准确定义
2. 核心要点
3. 一个简单例子

语言简洁清晰，适合复习用。"""
    elif issue_type == "讲得浅":
        prompt = f"""你是一位精通{subject}的大学教授。学生笔记中提到了「{concept}」但讲得很浅。
建议补充方向：{suggestion}
请撰写一段约200-300字的补充内容，讲清楚这个知识点。"""
    else:
        prompt = f"""你是一位精通{subject}的大学教授。学生笔记中涉及了「{concept}」。
{suggestion}
请撰写一段约200-300字的补充内容，帮助加深理解。"""

    resp = client.chat.completions.create(
        model=config["llm"]["model"],
        messages=[{"role": "user", "content": prompt.format(subject=subject)}],
        temperature=0.3
    )
    content = resp.choices[0].message.content.strip()
    supplements.append({"concept": concept, "content": content})
    print(f"    ✅ 已补充 ({len(content)} 字)")

# 第三步：写入补充内容到笔记末尾
print("\n💾 写入补充内容...")

enriched_section = "\n\n---\n## 📖 知识补充\n\n> 以下内容由 AI 自动补充，基于课堂笔记中未讲透或缺失的知识点。\n\n"

for s in supplements:
    enriched_section += f"### {s['concept']}\n\n{s['content']}\n\n"

# 如果笔记已有补充区块，替换它；否则追加
if "## 📖 知识补充" in original:
    enriched = re.sub(
        r"\n\n---\n## 📖 知识补充\n\n>.*?(?=\n\n## |\n\n---|\Z)",
        enriched_section,
        original,
        flags=re.DOTALL
    )
else:
    enriched = original + enriched_section

Path(note_path).write_text(enriched, encoding="utf-8")
print(f"✅ 补充完成！共补充 {len(supplements)} 个知识点")
print(f"   保存至: {note_path}")
PYEOF
" "$NOTE_FILE"
