#!/usr/bin/env bash
set -euo pipefail
ROOT="${LIBYACHAIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

echo "[stop] Stopping Claude team..."

# Kill tmux session if exists
if command -v tmux >/dev/null 2>&1; then
  if tmux has-session -t libyachain-claude 2>/dev/null; then
    echo "[stop] Killing tmux session libyachain-claude"
    tmux kill-session -t libyachain-claude || true
  fi
fi

# Kill background processes via PID files
for pidfile in .claude_launcher.bg.pid .claude_dashboard.bg.pid .claude_team.pid; do
  if [ -f "$ROOT/$pidfile" ]; then
    pid=$(cat "$ROOT/$pidfile" 2>/dev/null || true)
    if [ -n "$pid" ]; then
      echo "[stop] Killing process $pid from $pidfile"
      kill "$pid" 2>/dev/null || true
      sleep 1
      kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$ROOT/$pidfile"
  fi
done

# Kill any remaining Claude team processes
pkill -f "claude_team_launcher.py" 2>/dev/null || true
pkill -f "claude_live_dashboard.py" 2>/dev/null || true

# Kill dashboard on known ports
for port in 8790 8791 8792 8793 8794; do
  pid=$(lsof -ti tcp:$port 2>/dev/null || true)
  if [ -n "$pid" ]; then
    echo "[stop] Killing dashboard on port $port (PID $pid)"
    kill $pid 2>/dev/null || true
  fi
done

echo "[stop] Claude team stopped"