# Lecture Note — 课程录音自动整理

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.9+-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" />
  <img src="https://img.shields.io/badge/Status-Active-brightgreen?style=flat-square" />
</p>

上课录音一键转 Obsidian 结构化笔记。**录音 → Whisper 转录 → LLM 智能整理 → 结构化 Markdown**，自动按课程分类入 Obsidian 知识库。

---

## Pipeline

```
🎤 录音文件 (MP3/WAV)
    ↓
🗣️ OpenAI Whisper 自动语音识别 (ASR)
    ↓
🤖 LLM 润色 + 摘要 + 知识点提取
    ↓
📓 Obsidian Markdown (含 Wikilink、LaTeX 公式)
```

---

## 安装

```bash
# 1. 克隆仓库
git clone https://github.com/zack59309-maker/lecture-note.git
cd lecture-note

# 2. 安装 Python 依赖
pip install -r requirements.txt

# 3. 安装 ffmpeg (音频处理依赖)
# Windows: winget install ffmpeg  或  scoop install ffmpeg
# macOS:   brew install ffmpeg
# Linux:   sudo apt install ffmpeg

# 4. 配置 LLM API Key
export OPENAI_API_KEY="sk-xxx"    # 用于 LLM 整理
```

---

## 使用

```bash
# 转录单条录音并整理
./lecture-note.sh ~/录音/高等代数_第六章.mp3

# 批量处理整个文件夹（自动跳过已处理文件）
./lecture-note.sh ~/录音/

# 仅转录（不调用 LLM 整理）
./lecture-note.sh --transcribe-only ~/录音/复变函数.mp3

# 对已有笔记进行二次润色
./enrich-note.sh ~/笔记/高等代数/第六章.md
```

---

## 输出示例

转录 + 整理后生成以下结构到 Obsidian：

```markdown
# 高等代数 — 第六章 特征值与特征向量

## 录音摘要
本节课讲解了特征值与特征向量的定义、计算方法及几何意义...

## 知识点清单
1. **特征值**：满足 Av = λv 的标量 λ
2. **特征向量**：满足 Av = λv 的非零向量 v
3. **特征多项式**：det(A - λI) = 0

## 笔记正文
（完整转录+润色后的课堂笔记）

## 待办
- [ ] 完成第六章习题 1-5
- [ ] 复习相似对角化条件
```

---

## 文件说明

| 文件 | 用途 |
|------|------|
| `lecture-note.sh` | 主入口脚本：转录 + LLM 整理 + 输出全流程 |
| `enrich-note.sh` | 对已有笔记进行润色和结构化增强 |
| `detect_subject.py` | 根据录音内容自动识别课程科目并分类 |
| `skill` | 与 Hermes Agent 的 skill 集成配置 |

---

## 依赖

- `openai-whisper` — 语音识别（支持多语言，含中文）
- `torch` — PyTorch 推理加速
- `ffmpeg` — 音频格式转换
- Python 3.9+
- LLM API (OpenAI-compatible)

---

## 输出路径

默认输出到 Obsidian vault（需配置 `OBSIDIAN_VAULT` 环境变量），按课程分类：

```
Your Obsidian/
├── 高等代数/
│   ├── 01-线性方程组.md
│   ├── 02-矩阵运算.md
│   └── ...
├── 复变函数/
├── 数学建模/
└── ...
```

---

## License

MIT © 2024 zack59309-maker
