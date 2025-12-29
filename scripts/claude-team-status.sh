#!/usr/bin/env bash
set -euo pipefail
ROOT="${LIBYACHAIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
LOG_DIR="$ROOT/logs/claude"

echo "=== Claude Team Status ==="
echo

# Check tmux session
if command -v tmux >/dev/null 2>&1; then
  if tmux has-session -t libyachain-claude 2>/dev/null; then
    echo "✅ Tmux session: libyachain-claude (active)"
    echo "   Attach with: tmux attach -t libyachain-claude"
  else
    echo "❌ Tmux session: not found"
  fi
else
  echo "⚠️  Tmux: not installed"
fi
echo

# Check background processes
for pidfile in .claude_launcher.bg.pid .claude_dashboard.bg.pid .claude_team.pid; do
  if [ -f "$ROOT/$pidfile" ]; then
    pid=$(cat "$ROOT/$pidfile" 2>/dev/null || true)
    if [ -n "$pid" ] && ps -p "$pid" >/dev/null 2>&1; then
      echo "✅ Process $pidfile: running (PID $pid)"
    else
      echo "❌ Process $pidfile: not running (stale PID file)"
    fi
  fi
done
echo

# Check dashboard ports
echo "=== Dashboard Ports ==="
for port in 8790 8791 8792 8793 8794; do
  if lsof -ti tcp:$port >/dev/null 2>&1; then
    pid=$(lsof -ti tcp:$port)
    echo "✅ Port $port: in use (PID $pid)"
  fi
done
echo

# Check recent log activity
echo "=== Recent Agent Activity ==="
if [ -d "$LOG_DIR" ]; then
  for log in $(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -5); do
    name=$(basename "$log")
    size=$(du -h "$log" | cut -f1)
    mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$log" 2>/dev/null || stat -c "%y" "$log" 2>/dev/null | cut -d. -f1)
    echo "$name: $size (modified: $mtime)"
  done
else
  echo "No logs found at $LOG_DIR"
fi
echo

# Check for STATUS lines in recent logs
echo "=== Recent STATUS Updates ==="
if [ -d "$LOG_DIR" ]; then
  grep -h "^STATUS" "$LOG_DIR"/*.log 2>/dev/null | tail -10 || echo "No STATUS lines found"
else
  echo "No logs directory found"
fi