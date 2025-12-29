#!/usr/bin/env bash
set -euo pipefail
ROOT="${LIBYACHAIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Dashboard adapted for Claude agents (uses same codebase as codex dashboard with different log dir)
export CLAUDE_DASHBOARD_PORT="${CLAUDE_DASHBOARD_PORT:-8790}"
export LIBYACHAIN_ROOT="$ROOT"

cd "$ROOT"

# Use the enhanced dashboard with Claude-specific log directory
python3 claude_live_dashboard.py