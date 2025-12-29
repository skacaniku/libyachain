#!/usr/bin/env bash
set -euo pipefail

ROOT="${LIBYACHAIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
LOG_DIR="$ROOT/logs/codex"
RESTART_DELAY="${CODEX_LAUNCHER_RESTART_DELAY:-10}"
MAX_RESTARTS="${CODEX_LAUNCHER_MAX_RESTARTS:-0}"
mkdir -p "$LOG_DIR"
WRAPPER_LOG="$LOG_DIR/wrapper.log"

restarts=0
child_pid=""

log() {
  local stamp
  stamp="$(date -u +%FT%T)"
  echo "[wrapper ${stamp}] $*" >>"$WRAPPER_LOG"
}

detect_quota_exhaustion() {
  # Detect unrecoverable quota/rate limit failures to avoid restart storms
  local pattern="usage limit|insufficient quota|rate limit reached"
  local log
  while IFS= read -r log; do
    [[ -z "$log" ]] && continue
    if grep -qiE "$pattern" "$log" 2>/dev/null; then
      return 0
    fi
  done < <(find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' -mmin -5 2>/dev/null)
  return 1
}

cleanup() {
  if [[ -n "$child_pid" ]]; then
    kill -TERM "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
    child_pid=""
  fi
  log "wrapper exiting"
  exit 0
}

trap cleanup TERM INT HUP

while true; do
  export THINK_MANAGER="${THINK_MANAGER:-1}"
  export REASONING_EFFORT_MANAGER="${REASONING_EFFORT_MANAGER:-high}"
  export THINK_REVIEWERS="${THINK_REVIEWERS:-1}"
  export REASONING_EFFORT_REVIEWER="${REASONING_EFFORT_REVIEWER:-medium}"
  export THINK_DEVELOPERS="${THINK_DEVELOPERS:-1}"
  export REASONING_EFFORT_DEV="${REASONING_EFFORT_DEV:-medium}"
  ( cd "$ROOT" && python3 codex_team_launcher.py ) &
  child_pid=$!
  set +e
  wait "$child_pid"
  exit_code=$?
  set -e
  log "launcher exited with code $exit_code"
  if [[ $exit_code -eq 0 ]]; then
    break
  fi
  if detect_quota_exhaustion; then
    log "quota or rate limit exhaustion detected; not restarting"
    break
  fi
  ((restarts++))
  if [[ "$MAX_RESTARTS" != "0" && $restarts -ge "$MAX_RESTARTS" ]]; then
    log "max restarts ($MAX_RESTARTS) reached; stopping"
    break
  fi
  log "sleeping $RESTART_DELAY seconds before restart ($restarts)"
  sleep "$RESTART_DELAY"
  child_pid=""
done

trap - TERM INT HUP
cleanup
