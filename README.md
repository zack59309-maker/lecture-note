# Lecture Note

上课录音 → Whisper 转录 → LLM 整理 → Obsidian 结构化笔记

将手机/录音笔的课堂录音，自动转录、整理成结构化笔记，按学科分类存入 Obsidian。

## 流程

```
手机录音 → 桌面\课程录音\ → lecture-note.sh → Obsidian 数学知识库/
                                                     └── 课程笔记/
                                                         ├── 复变函数/
                                                         │   ├── 2026-06-04_xxx.md
                                                         │   └── ...
                                                         ├── 线性代数/
                                                         │   └── ...
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

# 3. 把 lecture-note.sh 放到项目目录
cp /path/to/lecture-note.sh ./
chmod +x lecture-note.sh
```

## 使用

```bash
# 自动处理桌面\课程录音\里的最新录音
./lecture-note.sh

# 指定文件+学科
./lecture-note.sh ~/temp/lecture.mp3 "复变函数"

# 只指定学科（自动选最新文件）
./lecture-note.sh "" "线性代数"
```

不传学科时自动用 LLM 识别课堂内容所属学科。

## 配置

编辑脚本顶部的变量：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `OBSIDIAN_VAULT` | `/mnt/d/obsidian/zack的数学知识库` | Obsidian 仓库路径 |
| `TEMP_DOWNLOAD` | `/mnt/c/Users/10181/Desktop/课程录音` | 录音来源文件夹 |

## 作为 Hermes Skill 使用

`skill/lecture-note/SKILL.md` 可导入 Hermes Agent。之后在 CLI 或 QQ 上说"整理录音"即可自动触发。

## 许可证

MIT

---

## 笔记知识补充

`enrich-note.sh` 自动分析笔记中讲得浅/缺失的知识点，用 LLM 补充完整内容：

```bash
# 补充最新笔记
./enrich-note.sh --auto

# 补充指定笔记
./enrich-note.sh "复变函数/2026-06-04_xxx.md"
```

补充的内容以「📖 知识补充」区块追加到笔记末尾，包含定义、要点和例子。
