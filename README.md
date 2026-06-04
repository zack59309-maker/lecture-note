# Lecture Note

上课录音 → Whisper 转录 → LLM 整理 → 自动补充知识点 → Obsidian 结构化笔记

将课堂录音自动转录、整理成结构化笔记，自动识别学科并补充老师没讲透的知识点，存入 Obsidian。

## 完整流程

```
手机录音 → 桌面\课程录音\ → lecture-note.sh
                                    │
                            [1/4] 转录（faster-whisper）
                                    │
                            [2/4] 自动识别学科（DeepSeek）
                                    │
                            [3/4] 结构化笔记 + 存到 Obsidian
                                    │
                            [4/4] 自动补充知识点（enrich-note）
                                    │
                                    ▼
                            Obsidian 数学知识库/
                              └── 课程笔记/
                                  ├── 复变函数/
                                  │   ├── 2026-06-04_xxx.md  ← 笔记 + 补充
                                  │   └── ...
                                  ├── 线性代数/
                                  └── _索引.md
```

## 依赖

- Python 3.11+
- ffmpeg
- [NoteKing Pro](https://github.com/bcefghj/noteking-pro)（自动安装 faster-whisper、openai 等）
- LLM API Key（DeepSeek / OpenAI / MiniMax）

## 安装

```bash
# 1. 克隆 NoteKing Pro 并安装
git clone https://github.com/bcefghj/noteking-pro.git
cd noteking-pro
python3 -m venv venv
source venv/bin/activate
pip install -e ".[meeting,asr]"
pip install uvicorn fastapi python-multipart aiofiles

# 2. 配置 LLM API
python -m cli setup --api-key "sk-xxx" --base-url "https://api.deepseek.com" --model "deepseek-chat"

# 3. 把本仓库的脚本放到项目目录
cp lecture-note.sh enrich-note.sh ./
chmod +x lecture-note.sh enrich-note.sh
```

## 使用

```bash
# 自动处理最新录音（自动识别学科）
./lecture-note.sh

# 指定文件+学科
./lecture-note.sh ~/temp/lecture.mp3 "复变函数"

# 只指定学科（自动选最新文件）
./lecture-note.sh "" "复变函数"
```

不传学科时自动用 LLM 识别课堂内容所属学科。

## 知识补充

`enrich-note.sh` 可单独使用，分析笔记中讲得浅/缺失的知识点并补充：

```bash
# 补充最新笔记
./enrich-note.sh --auto

# 补充指定笔记
./enrich-note.sh "课程笔记/复变函数/2026-06-04_xxx.md"
```

补充的内容以「📖 知识补充」区块追加到笔记末尾，包含定义、要点和例子。重复运行同篇笔记会替换旧内容，不重复累积。

## 配置

编辑 `lecture-note.sh` 顶部的变量：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `OBSIDIAN_VAULT` | `/mnt/d/obsidian/zack的数学知识库` | Obsidian 仓库路径 |
| `TEMP_DOWNLOAD` | `/mnt/c/Users/10181/Desktop/课程录音` | 录音来源文件夹 |

## 作为 Hermes Skill 使用

`skill/lecture-note.md` 和 `skill/enrich-note.md` 可导入 Hermes Agent。之后在 CLI 或 QQ 上说：
- "整理录音" — 全流程：转录 → 笔记 → 补充
- "补充笔记" — 仅补充最新笔记的知识点

## 许可证

MIT
