---
name: lecture-note
description: 上课录音 → Whisper 转录 → DeepSeek 整理笔记 → 自动存到 Obsidian，按学科分类
---

# Lecture Note: 录音整理笔记流水线

把 桌面\课程录音 文件夹里的录音文件一键转成结构化课堂笔记，自动识别学科，存到 Obsidian 仓库。

## 触发

用户说"整理录音"或"整理XX课的录音"

## 步骤

1. **检查录音文件**
   - 如果用户指定了学科（如"整理复变函数的录音"），用 clarify 确认录音文件或直接用 D:\\临时下载\\ 里的最新音频
   - 如果用户只说"整理录音"，找 D:\\临时下载\\ 里最新的音频文件（.mp3/.m4a/.wav/.mp4/.amr/.aac）
   - 如果没有文件，告知用户把录音放到 D:\\临时下载\\

2. **运行脚本**
   ```bash
   cd ~/noteking-pro && ./lecture-note.sh [文件路径] [学科]
   ```
   - 不传学科则自动用 LLM 识别
   - 不传文件路径则自动选 D:\\临时下载\\ 里最新的

3. **确认结果**
   - 告诉用户笔记保存在 Obsidian 的什么位置
   - Obsidian 路径: `/mnt/d/obsidian/zack的数学知识库/课程笔记/{学科}/{日期}_{文件名}.md`

## 注意

- 依赖 NoteKing Pro 项目，部署在 `~/noteking-pro/`
- Python venv 在 `~/noteking-pro/venv/`
- 需要 ffmpeg、faster-whisper
- 配置在 `~/.noteking/config.json`（DeepSeek API key）
- 转录耗时长（45min 课约 5-10min），用户不需要看到实时进度条，后台跑完通知即可
