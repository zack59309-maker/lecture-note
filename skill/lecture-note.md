---
name: lecture-note
description: 上课录音 → Whisper 转录 → DeepSeek 整理笔记 → 自动补充知识点 → 存到 Obsidian，按学科分类
---

# Lecture Note: 录音整理笔记流水线

把桌面「课程录音」文件夹里的录音文件一键转成结构化课堂笔记，自动识别学科、自动补充老师没讲透的知识点，存到 Obsidian 仓库。

## 触发

用户说"整理录音"或"整理XX课的录音"

## 步骤

1. **确认录音文件**
   - 如果用户指定学科（如"整理复变函数的录音"），传学科参数，脚本自动选最新录音
   - 如果只说"整理录音"，自动选桌面 `课程录音\` 里最新的音频
   - 支持格式：mp3 / m4a / wav / mp4 / amr / aac
   - 如果该文件夹为空，告知用户先把录音放进去

2. **运行脚本**
   ```bash
   cd ~/noteking-pro && ./lecture-note.sh [文件路径] [学科]
   ```
   - 不传学科 → 自动用 LLM 从转录文本前 3000 字识别学科
   - 不传文件路径 → 自动选 `桌面\课程录音\` 里最新的
   - 只传学科不传文件：`./lecture-note.sh "" "复变函数"`

3. **后台处理（较耗时，直接通知结果）**
   - 转录：faster-whisper 转文字（CPU int8，45min 课约 5-10min）
   - 整理：DeepSeek 生成结构化笔记
   - 补充：自动分析笔记中讲得浅/缺失的知识点，补充完整
   - 输出：存到 Obsidian + 更新学科索引

4. **告知结果**
   - 笔记路径和学科分类
   - 共补充了多少知识点

## 输出结构

```
Obsidian 仓库/
└── 课程笔记/
    ├── 复变函数/
    │   ├── 2026-06-04_xxx.md        ← 笔记 + 知识点补充
    │   └── ...
    ├── 线性代数/
    └── _索引.md
```

每篇笔记含：
- YAML frontmatter（title、subject、date、source）
- 正文（LLM 结构化整理）
- 📖 知识补充区块（自动追加在末尾）

## 知识补充（enrich-note）

脚本自动执行的知识补充流程：

1. **分析** — LLM 识别笔记中"讲得浅""缺失""可补充"三类知识点
2. **补充** — 每个知识点生成 200-300 字（定义 + 核心要点 + 例子）
3. **写入** — 以「📖 知识补充」区块追加到笔记末尾
4. **幂等** — 重复处理同篇笔记会替换旧补充内容，不重复累积

可单独触发：`./enrich-note.sh --auto` 或对我说"补充笔记"

## 依赖

| 组件 | 位置 |
|------|------|
| NoteKing Pro | ~/noteking-pro/ |
| Python venv | ~/noteking-pro/venv/ |
| LLM 配置 | ~/.noteking/config.json（DeepSeek） |
| 录音来源 | 桌面\课程录音\ |
| Obsidian vault | D:\obsidian\zack的数学知识库\ |
| 脚本 | ~/noteking-pro/lecture-note.sh, enrich-note.sh |

## GitHub

`github.com/zack59309-maker/lecture-note` — 包含脚本、README、Hermes skill 文件。
