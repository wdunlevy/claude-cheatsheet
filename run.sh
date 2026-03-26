#!/bin/bash
# Claude Code Cheatsheet — daily launchd runner
# Generates reference PDF, pushes to GitHub, sends iMessage notification
exec >> ~/.claude/cheatsheet/launchd-stdout.log 2>> ~/.claude/cheatsheet/launchd-stderr.log
echo "=== START $(date) ==="

/Users/wdunlevy/.local/bin/claude --dangerously-skip-permissions -p \
  "Run the /cheatsheet skill. Follow the instructions in ~/.claude/skills/cheatsheet/SKILL.md exactly. After generating (or determining no changes), send an iMessage notification using this AppleScript:

tell application \"Messages\"
  set iMsgAccount to account id \"E465ECCE-1582-4246-9FAF-11B3326C5196\"
  set targetBuddy to participant \"wdunlevy@gmail.com\" of iMsgAccount
  send \"{MESSAGE}\" to targetBuddy
end tell

If changes: MESSAGE = \"Cheatsheet v{VERSION} — {N} changes: {list}. https://wdunlevy.github.io/claude-cheatsheet/latest.pdf\"
If no changes: MESSAGE = \"Cheatsheet — no changes today (v{VERSION} current).\"" 2>&1

echo "--- exit code: $? ---"
echo "=== END $(date) ==="
