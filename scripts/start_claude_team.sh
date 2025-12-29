#!/usr/bin/env bash
set -euo pipefail

ROOT="${LIBYACHAIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
export LIBYACHAIN_ROOT="$ROOT"

# Create log directory
mkdir -p "$ROOT/logs/claude"

# Resource limits for MacBook Pro M4 16GB (STRICT)
export CLAUDE_MAX_CONCURRENT="${CLAUDE_MAX_CONCURRENT:-3}"  # Manager + Reviewer + 1 Dev
export CLAUDE_MAX_DEVS="${CLAUDE_MAX_DEVS:-2}"  # Can scale to 2 if memory allows
export CLAUDE_MAX_REVIEWERS="${CLAUDE_MAX_REVIEWERS:-1}"

# Claude CLI settings
export CLAUDE_BIN="${CLAUDE_BIN:-claude}"

echo "========================================"
echo "Claude Agent Team - Resource Optimized"
echo "========================================"
echo "Root: $ROOT"
echo "Max concurrent: $CLAUDE_MAX_CONCURRENT"
echo "Max developers: $CLAUDE_MAX_DEVS"
echo "Max reviewers: $CLAUDE_MAX_REVIEWERS"
echo "========================================"

# Check if Claude CLI is installed
if ! command -v "$CLAUDE_BIN" &> /dev/null; then
    echo "❌ Claude CLI not found. Please install it first."
    echo ""
    echo "This team uses 'claude' CLI from Anthropic's Claude Code."
    echo "Requires Claude Max subscription and SSO authentication."
    echo ""
    echo "Installation: Follow https://claude.com/claude-code"
    exit 1
fi

echo "✅ Claude CLI found: $(which $CLAUDE_BIN)"

# Check authentication
if ! "$CLAUDE_BIN" auth status &> /dev/null; then
    echo "🔐 Claude CLI not authenticated. Starting SSO flow..."
    "$CLAUDE_BIN" auth login

    if ! "$CLAUDE_BIN" auth status &> /dev/null; then
        echo "❌ Authentication failed"
        exit 1
    fi
fi

echo "✅ Claude CLI authenticated"

# Kill any existing instances
if [ -f "$ROOT/.claude_team.pid" ]; then
    OLD_PID=$(cat "$ROOT/.claude_team.pid")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "Stopping existing team (PID $OLD_PID)..."
        kill "$OLD_PID" 2>/dev/null || true
        sleep 2
        kill -9 "$OLD_PID" 2>/dev/null || true
    fi
    rm -f "$ROOT/.claude_team.pid"
fi

# Start the team
echo "🚀 Starting Claude Agent Team..."
cd "$ROOT"
python3 scripts/claude_team_launcher.py > logs/claude/launcher.stdout 2>&1 &
LAUNCHER_PID=$!
echo $LAUNCHER_PID > "$ROOT/.claude_team.pid"

sleep 3

if ps -p $LAUNCHER_PID > /dev/null 2>&1; then
    echo "✅ Claude Agent Team started"
    echo "   PID: $LAUNCHER_PID"
    echo "   Logs: logs/claude/"
    echo ""
    echo "Commands:"
    echo "  make claude-team-status  - Show team status"
    echo "  make claude-team-stop    - Stop team"
    echo "  tail -f logs/claude/launcher.log  - View logs"
else
    echo "❌ Failed to start team"
    echo ""
    echo "Error log:"
    cat logs/claude/launcher.stdout
    exit 1
fi