#!/usr/bin/env bash

gf_fzf_log_line_interpreter() {
  cat - | awk '{ print $1 }'
}

gf_helper_valid_fzf_port() {
  case "$1" in
    ''|*[!0-9]*)
      return 1
      ;;
  esac
}

gf_helper_reload_token_path() {
  local port="$1"
  local kind="$2"
  local temp_dir="${TMPDIR:-/tmp}"
  local user_id="${UID:-$(id -u)}"
  local runtime_dir="${temp_dir%/}/git-fuzzy-$user_id"

  case "$kind" in
    ''|*[!abcdefghijklmnopqrstuvwxyz0123456789_]*)
      return 1
      ;;
  esac
  case "$kind" in
    *_menu_content) ;;
    *) return 1 ;;
  esac

  mkdir -p "$runtime_dir" || return
  chmod 700 "$runtime_dir" || return
  printf '%s/reload-%s-%s' "$runtime_dir" "$port" "$kind"
}

gf_helper_reload_is_current() {
  local token_path="$1"
  local token="$2"

  [ -f "$token_path" ] && [ "$(cat "$token_path")" = "$token" ]
}

gf_helper_fzf_post() {
  local port="$1"
  local action="$2"

  gf_helper_valid_fzf_port "$port" || return
  curl -fsS -XPOST "localhost:$port" --data-binary "$action" > /dev/null 2>&1
}

gf_helper_debounced_reload() {
  local port="$1"
  local debounce="$2"
  local action_prefix="$3"
  local menu_helper="$4"
  local query="$5"
  shift 5

  gf_helper_valid_fzf_port "$port" || return

  case "$action_prefix" in
    reload-sync|track-current+reload-sync)
      ;;
    *)
      return 1
      ;;
  esac

  case "$menu_helper" in
    ''|*[!abcdefghijklmnopqrstuvwxyz0123456789_]*)
      return 1
      ;;
  esac
  case "$menu_helper" in
    *_menu_content) ;;
    *) return 1 ;;
  esac

  local token_path
  local token
  local action

  token_path="$(gf_helper_reload_token_path "$port" "$menu_helper")" || return
  token="$$-${RANDOM:-0}-$(date +%s)"
  printf '%s' "$token" > "$token_path" || return

  sleep "$debounce" || return
  gf_helper_reload_is_current "$token_path" "$token" || return

  action="$action_prefix(git fuzzy helper $menu_helper $(quote_params "$query" "$@"))"
  local post_status
  gf_helper_fzf_post "$port" "$action"
  post_status=$?

  gf_helper_reload_is_current "$token_path" "$token" && rm -f "$token_path"
  return "$post_status"
}
