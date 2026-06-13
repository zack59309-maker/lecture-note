"""Tests for detect_subject.py."""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))


def test_detect_subject_importable():
    """detect_subject should be importable."""
    import detect_subject
    assert hasattr(detect_subject, "__doc__")
    assert "Detect subject" in (detect_subject.__doc__ or "")


def test_detect_subject_has_required_imports():
    """Ensure detect_subject imports openai, json, sys, pathlib."""
    import detect_subject
    import inspect
    source = inspect.getsource(detect_subject)
    assert "from openai import OpenAI" in source
    assert "from pathlib import Path" in source
    assert "import json" in source
