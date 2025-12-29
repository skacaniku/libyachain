#!/usr/bin/env bash
set -euo pipefail

ROOT="${LIBYACHAIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DASHBOARD_PORT="${CODEX_DASHBOARD_PORT:-7777}"

cd "$ROOT"

echo "Starting Enhanced Codex Dashboard on port $DASHBOARD_PORT..."

VENV_DIR="$ROOT/.codex-dashboard-venv"

ensure_venv() {
    if [ ! -d "$VENV_DIR" ]; then
        echo "[dashboard] Creating virtual environment at $VENV_DIR"
        python3 -m venv "$VENV_DIR"
    fi
}

install_deps() {
    local py
    py="$1"
    "$py" -m pip install --quiet --upgrade pip setuptools wheel
    "$py" -m pip install --quiet aiohttp websockets
}

ensure_venv

PYTHON="$VENV_DIR/bin/python3"
if [ ! -x "$PYTHON" ]; then
    PYTHON="$VENV_DIR/bin/python"
fi

if [ ! -x "$PYTHON" ]; then
    echo "Failed to locate python executable in $VENV_DIR"
    exit 1
fi

if ! "$PYTHON" -c "import aiohttp, websockets" >/dev/null 2>&1; then
    echo "[dashboard] Installing Python dependencies inside dashboard venv"
    install_deps "$PYTHON"
fi

export CODEX_DASHBOARD_PORT="$DASHBOARD_PORT"
export VIRTUAL_ENV="$VENV_DIR"
export PATH="$VENV_DIR/bin:$PATH"

exec "$PYTHON" codex_enhanced_dashboard.py
