#!/usr/bin/env bash
set -euo pipefail

ROOT="${LIBYACHAIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
APPDIR="${AUTOGEN_STUDIO_APPDIR:-$ROOT/.autogenstudio}"
PORT="${AUTOGEN_STUDIO_PORT:-8081}"
HOST="${AUTOGEN_STUDIO_HOST:-127.0.0.1}"
EXTRA_ARGS_STR="${AUTOGEN_STUDIO_EXTRA_ARGS:-}"
if [ -n "$EXTRA_ARGS_STR" ]; then
  IFS=' ' read -r -a EXTRA_ARGS <<< "$EXTRA_ARGS_STR"
else
  EXTRA_ARGS=()
fi

if ! command -v autogenstudio >/dev/null 2>&1; then
  cat <<'MSG' >&2
[autogen] Missing 'autogenstudio' CLI.
Install via: pipx install autogenstudio
Or use: pip install autogenstudio --user
MSG
  exit 1
fi

mkdir -p "$APPDIR"

LOG_DIR="$ROOT/logs/autogenstudio"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/ui.log"

# Reuse Codex SSO token if no explicit API key provided
if [ -z "${OPENAI_API_KEY:-}" ]; then
  PROFILE="${CODEX_SSO_PROFILE:-default}"
  TOKEN_PATH="$HOME/.libyachain/codex_sso/tokens-${PROFILE}.json"
  if [ -f "$TOKEN_PATH" ]; then
    TOKEN=$(PROFILE="$PROFILE" TOKEN_PATH="$TOKEN_PATH" python3 - <<'PY'
import json, os
from pathlib import Path
profile = os.environ.get('PROFILE')
path = Path(os.environ.get('TOKEN_PATH', ''))
if not path.exists():
    raise SystemExit
data = json.loads(path.read_text())
token = data.get('access_token')
if token:
    print(token)
PY
    )
    if [ -n "$TOKEN" ] && [ "$TOKEN" != "mock-access-token" ]; then
      export OPENAI_API_KEY="$TOKEN"
      echo "[autogen] OPENAI_API_KEY sourced from Codex SSO profile '$PROFILE'"
    else
      echo "[autogen] Codex SSO token file present but no usable access token (profile $PROFILE)" >&2
    fi
  fi
fi

echo "[autogen] Starting AutoGen Studio on http://$HOST:$PORT (appdir=$APPDIR)"
CMD=(autogenstudio ui --host "$HOST" --port "$PORT" --appdir "$APPDIR")
if [ -n "$EXTRA_ARGS_STR" ]; then
  CMD+=("${EXTRA_ARGS[@]}")
fi
if [ $# -gt 0 ]; then
  CMD+=("$@")
fi
set -x
exec "${CMD[@]}" >>"$LOGFILE" 2>&1
