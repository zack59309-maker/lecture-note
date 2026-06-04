#!/usr/bin/env python3
"""Detect subject from transcript text."""
import json, sys
from openai import OpenAI
from pathlib import Path

config_path = Path.home() / ".noteking" / "config.json"
config = json.loads(config_path.read_text())

client = OpenAI(
    api_key=config["llm"]["api_key"],
    base_url=config["llm"]["base_url"]
)

transcript = Path(sys.argv[1]).read_text()[:3000]
resp = client.chat.completions.create(
    model=config["llm"]["model"],
    messages=[{
        "role": "user",
        "content": f"以下是一段课堂录音的转录文本开头，请用2-4个字概括这是什么学科（如：复变函数、线性代数、英语、物理化学）。只回复学科名称，不要其他内容。\n\n{transcript}"
    }],
    temperature=0.1
)
print(resp.choices[0].message.content.strip())
