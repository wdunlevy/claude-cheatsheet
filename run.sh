#!/bin/bash
# Claude Code Cheatsheet — daily launchd runner
# Architecture: Claude handles content (PDF + git), claude-notify handles OS comms.
# This separation ensures TCC permissions are granted to a stable binary, not the
# ever-updating Claude Code binary.
exec >> ~/.claude/cheatsheet/launchd-stdout.log 2>> ~/.claude/cheatsheet/launchd-stderr.log
echo "=== START $(date) ==="

NOTIFY="$HOME/.claude/tools/claude-notify/claude-notify"
RESULT="$HOME/.claude/cheatsheet/last-run.json"
CHEATSHEET_DIR="$HOME/.claude/cheatsheet"
IMSG_ACCOUNT="E465ECCE-1582-4246-9FAF-11B3326C5196"
IMSG_TO="wdunlevy@gmail.com"

# Clean up any stale result file
rm -f "$RESULT"

# Step 1: Claude generates the cheatsheet (PDF, git commit/push — no OS comms)
/Users/wdunlevy/.local/bin/claude --dangerously-skip-permissions -p \
  "Run the /cheatsheet skill. Follow the instructions in ~/.claude/skills/cheatsheet/SKILL.md exactly.

IMPORTANT — after the skill completes (whether or not a new PDF was generated), write a JSON result file to $RESULT with this exact structure:
{
  \"generated\": true/false,
  \"version\": \"1.x\",
  \"changes\": \"summary of what changed (or 'none')\",
  \"message\": \"The full notification message to send\"
}

For the message field:
- If changes: \"Cheatsheet v{VERSION} — {N} changes: {list}. https://wdunlevy.github.io/claude-cheatsheet/latest.pdf\"
- If no changes: \"Cheatsheet — no changes today (v{VERSION} current).\"

Do NOT send iMessage or copy files to Desktop — that is handled externally." 2>&1

CLAUDE_EXIT=$?
echo "--- claude exit code: $CLAUDE_EXIT ---"

# Step 2: Read result and dispatch OS operations via stable binary
if [ ! -f "$RESULT" ]; then
  echo "WARN: Claude did not write $RESULT — sending fallback notification"
  "$NOTIFY" imessage \
    --account-id "$IMSG_ACCOUNT" \
    --to "$IMSG_TO" \
    --message "Cheatsheet run completed (exit $CLAUDE_EXIT) but no result file was written. Check logs."
  echo "=== END $(date) ==="
  exit 1
fi

GENERATED=$(jq -r .generated "$RESULT")
VERSION=$(jq -r .version "$RESULT")
MSG=$(jq -r .message "$RESULT")

echo "Result: generated=$GENERATED version=$VERSION"

# Copy PDF to Desktop if new version was generated
if [ "$GENERATED" = "true" ]; then
  PDF="$CHEATSHEET_DIR/Claude Code Reference v${VERSION}.pdf"
  if [ -f "$PDF" ]; then
    "$NOTIFY" copy "$PDF" "$HOME/Desktop/Claude Code Reference v${VERSION}.pdf"
  else
    echo "WARN: expected PDF not found: $PDF"
  fi
fi

# Send iMessage notification (always — even for "no changes" runs)
"$NOTIFY" imessage \
  --account-id "$IMSG_ACCOUNT" \
  --to "$IMSG_TO" \
  --message "$MSG"

echo "--- notify exit code: $? ---"
echo "=== END $(date) ==="
