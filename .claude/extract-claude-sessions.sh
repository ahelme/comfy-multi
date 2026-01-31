#!/bin/bash
# save as: ~/extract-claude-sessions.sh

CLAUDE_DIR="$HOME/.claude/projects"

echo "🔍 Scanning Claude sessions (newest first)..."
echo ""

# Find all session files, sort by modification time (newest first)
find "$CLAUDE_DIR" -name "*.jsonl" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | cut -d' ' -f2- | while read -r file; do
  SESSION_ID=$(basename "$file" .jsonl)
  MSG_COUNT=$(wc -l < "$file")
  MODIFIED=$(stat -c %y "$file" 2>/dev/null | cut -d. -f1)
  FIRST_PROMPT=$(grep -m1 '"type":"user"' "$file" | jq -r '
    if .message.content | type == "string" then .message.content[:80]
    elif .message.content | type == "array" then (.message.content[0].text // "")[:80]
    else "?" end
  ' 2>/dev/null)
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📁 $file"
  echo "🆔 $SESSION_ID"
  echo "📊 $MSG_COUNT messages | Modified: $MODIFIED"
  echo "💬 ${FIRST_PROMPT:-(no prompt)}"
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To extract a session, run:"
echo "  ~/extract-session.sh <SESSION_ID>"
