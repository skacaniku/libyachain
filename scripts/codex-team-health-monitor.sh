#!/usr/bin/env bash
set -euo pipefail

# Periodically run `make codex-team-status` and record outcomes for the Codex manager.

ROOT="${LIBYACHAIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
LOG_DIR="$ROOT/logs/codex"
LOG_FILE="$LOG_DIR/codex_team_status.log"
STATE_FILE="$LOG_DIR/codex_team_status.status"
INTERVAL_SECONDS="${CODEX_HEALTH_INTERVAL_SECONDS:-120}"

mkdir -p "$LOG_DIR"

run_once() {
  local start_ts end_ts duration status tmp_file
  start_ts="$(date -u +"%FT%TZ")"
  local start_epoch="$(date +%s)"
  tmp_file="$(mktemp)"

  if GOCACHE="$ROOT/.gocache" GOMODCACHE="$ROOT/.gomodcache" \
     make -C "$ROOT" codex-team-status >"$tmp_file" 2>&1; then
    status="OK"
  else
    status="FAIL"
  fi

  end_ts="$(date -u +"%FT%TZ")"
  local end_epoch="$(date +%s)"
  duration=$(( end_epoch - start_epoch ))

  {
    printf '%s | status=%s | duration=%ss\n' "$start_ts" "$status" "$duration"
    printf 'output:\n'
    cat "$tmp_file"
    printf '\n----\n'
  } >>"$LOG_FILE"

  {
    printf 'timestamp=%s\n' "$start_ts"
    printf 'status=%s\n' "$status"
    printf 'duration_seconds=%s\n' "$duration"
  } >"$STATE_FILE"

  rm -f "$tmp_file"
}

while true; do
  run_once
  sleep "$INTERVAL_SECONDS"
done
