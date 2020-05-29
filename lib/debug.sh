#!/usr/bin/env bash
# shellcheck disable=2129

gf_emit_log_and_reset() {
  >&2 cat "$GF_LOG_LOCATION"
}

if [ -z "$GF_LOG_LOCATION" ]; then
  if [ -d "$TMPDIR" ]; then
    # NB: TMPDIR on macOS has a trailing slash
    GF_LOG_LOCATION="${TMPDIR%/}/git-fuzzy-log"
  else
    GF_LOG_LOCATION="$HOME/.git-fuzzy-log"
  fi
  export GF_LOG_LOCATION

  rm -f "$GF_LOG_LOCATION"
  touch "$GF_LOG_LOCATION"

  trap gf_emit_log_and_reset EXIT
fi

gf_log_warning() {
  printf "[%s%sWRN%s]" "$YELLOW" "$BOLD" "$NORMAL" >> "$GF_LOG_LOCATION"
  printf " %s" "$@" >> "$GF_LOG_LOCATION"
  echo >> "$GF_LOG_LOCATION"
}

gf_log_error() {
  printf "[%s%sERR%s]" "$RED" "$BOLD" "$NORMAL" >> "$GF_LOG_LOCATION"
  printf " %s" "$@" >> "$GF_LOG_LOCATION"
  echo >> "$GF_LOG_LOCATION"
}

gf_log_debug() {
  if [ -n "$GF_DEBUG_MODE" ]; then
    printf "[%s%sDBG%s]" "$GRAY" "$BOLD" "$NORMAL" >> "$GF_LOG_LOCATION"
    printf " %s" "$@" >> "$GF_LOG_LOCATION"
    echo >> "$GF_LOG_LOCATION"
  fi
}

gf_log_command() {
  if [ -n "$GF_COMMAND_DEBUG_MODE" ]; then
    if [ "$#" -gt 0 ]; then
      printf "[%s%sCMD%s]" "$GREEN" "$BOLD" "$NORMAL" >> "$GF_LOG_LOCATION"
      printf '%s%s%s%s' "$GRAY" "$BOLD" ' $ ' "$NORMAL" >> "$GF_LOG_LOCATION"
      printf '%s%s%s%s' "$CYAN" "$BOLD" "$(quote_single_param "$1")" "$NORMAL" >> "$GF_LOG_LOCATION"
      shift
      printf '%s' "$GREEN" >> "$GF_LOG_LOCATION"
      printf ' %s' "$(quote_params "$@")" >> "$GF_LOG_LOCATION"
      printf '%s' "$NORMAL" >> "$GF_LOG_LOCATION"
      echo >> "$GF_LOG_LOCATION"
    else
      # shellcheck disable=2016
      error_exit '`gf_log_command` requires an actual command'
    fi
  fi
}

gf_log_command_string() {
  if [ -n "$GF_COMMAND_DEBUG_MODE" ]; then
    if [ "$#" -gt 0 ]; then
      printf "[%s%sCMD%s]" "$GREEN" "$BOLD" "$NORMAL" >> "$GF_LOG_LOCATION"
      printf '%s%s%s%s' "$GRAY" "$BOLD" ' $ ' "$NORMAL" >> "$GF_LOG_LOCATION"
      printf '%s%s%s' "$CYAN" "$1" "$NORMAL" >> "$GF_LOG_LOCATION"
      echo >> "$GF_LOG_LOCATION"
    else
      # shellcheck disable=2016
      error_exit '`gf_log_command` requires an actual command'
    fi
  fi
}

gf_log_internal() {
  if [ -n "$GF_INTERNAL_COMMAND_DEBUG_MODE" ]; then
    if [ "$#" -gt 0 ]; then
      printf "[%s%sCMD%s] (internal)" "$GRAY" "$BOLD" "$NORMAL" >> "$GF_LOG_LOCATION"
      printf '%s%s%s%s' "$GRAY" "$BOLD" ' $ ' "$NORMAL" >> "$GF_LOG_LOCATION"
      printf '%s%s%s%s' "$CYAN" "$BOLD" "$(quote_single_param "$1")" "$NORMAL" >> "$GF_LOG_LOCATION"
      shift
      printf '%s' "$GREEN" >> "$GF_LOG_LOCATION"
      printf ' %s' "$(quote_params "$@")" >> "$GF_LOG_LOCATION"
      printf '%s' "$NORMAL" >> "$GF_LOG_LOCATION"
      echo >> "$GF_LOG_LOCATION"
    else
      # shellcheck disable=2016
      error_exit '`gf_log_internal` requires an actual command'
    fi
  fi
}
