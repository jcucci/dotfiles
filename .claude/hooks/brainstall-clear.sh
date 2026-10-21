#!/bin/bash
# Brainstall cleanup - removes state file when user resumes or session ends.

INPUT=$(cat)

echo "$INPUT" | /usr/bin/python3 /Users/joe.cucci/.claude/hooks/brainstall-clear.py
