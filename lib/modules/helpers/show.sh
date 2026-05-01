#!/usr/bin/env bash

gf_show_usage() {
  gf_log_error 'usage: git fuzzy show <commit> [-- <pathspec>...]'
}

gf_show_parse_args() {
  GF_SHOW_REF=''
  GF_SHOW_PATHS=()

  if [ "$#" -lt 1 ]; then
    gf_show_usage
    return 1
  fi

  GF_SHOW_REF="$1"
  shift

  case "$GF_SHOW_REF" in
    *..*)
      gf_log_error "show accepts exactly one commit-ish, not a range: $GF_SHOW_REF"
      return 1
      ;;
  esac

  if [ "$#" -gt 0 ]; then
    if [ "$1" != '--' ]; then
      gf_show_usage
      return 1
    fi

    shift
    GF_SHOW_PATHS=("$@")
  fi

  if ! git rev-parse --verify --quiet "$GF_SHOW_REF^{commit}" >/dev/null; then
    gf_log_error "not a commit: $GF_SHOW_REF"
    return 1
  fi
}

gf_helper_show_empty_text() {
  QUERY="$1"

  if [ "${#GF_SHOW_PATHS[@]}" -gt 0 ] && [ -n "$QUERY" ]; then
    echo 'no files match pathspec and query'
  elif [ "${#GF_SHOW_PATHS[@]}" -gt 0 ]; then
    echo 'no files match pathspec'
  elif [ -n "$QUERY" ]; then
    echo 'no files match query'
  else
    echo 'no files changed'
  fi
}

gf_helper_show_menu_content() {
  QUERY="$1"
  shift

  gf_show_parse_args "$@" || return
  EMPTY_TEXT="$(gf_helper_show_empty_text "$QUERY")"

  if [ -z "$QUERY" ]; then
    gf_git_command_with_header_default_parameters 2 "--format=" show --first-parent --name-only "$GF_SHOW_REF" -- "${GF_SHOW_PATHS[@]}"
  else
    # shellcheck disable=2086
    gf_git_command_with_header_default_parameters 2 "--format=" show --first-parent "$GF_SHOW_REF" $GF_DIFF_SEARCH_DEFAULTS "$QUERY" --name-only -- "${GF_SHOW_PATHS[@]}"
  fi | awk -v empty_text="$EMPTY_TEXT" '
    NR <= 2 { print; next }
    NF && !seen[$0]++ { print "file " $0; found = 1 }
    END { if (!found) print "nothing " empty_text }
  '
}

gf_helper_show_empty_content() {
  QUERY="$1"

  gf_git_command_with_header 1 show --first-parent --no-patch "$GF_SHOW_REF"
  gf_helper_show_empty_text "$QUERY"
}

gf_helper_show_selected_file() {
  case "$1" in
    file\ *)
      printf '%s\n' "${1#file }"
      ;;
  esac
}

gf_helper_show_preview_content() {
  QUERY="$1"
  shift

  SELECTION="$1"
  shift

  gf_show_parse_args "$@" || return

  FILE_PATH="$(gf_helper_show_selected_file "$SELECTION")"

  if [ -z "$FILE_PATH" ]; then
    gf_preview_shortcuts_header_with_inspect
    gf_helper_show_empty_content "$QUERY"
  elif [ -z "$QUERY" ]; then
    gf_preview_shortcuts_header_with_inspect
    gf_git_command_with_header_default_parameters 1 "$GF_DIFF_FILE_PREVIEW_DEFAULTS" show --first-parent "$GF_SHOW_REF" -- "$FILE_PATH" |
      gf_diff_renderer
  else
    gf_preview_shortcuts_header_with_inspect
    gf_git_command_with_header_default_parameters 1 "$GF_DIFF_FILE_PREVIEW_DEFAULTS" show --first-parent "$GF_SHOW_REF" -- "$FILE_PATH" |
      gf_diff_renderer |
      grep --color=always -E "$QUERY|$"
  fi
}

gf_helper_show_inspect() {
  QUERY="$1"
  shift

  SELECTION="$1"
  shift

  gf_show_parse_args "$@" || return

  FILE_PATH="$(gf_helper_show_selected_file "$SELECTION")"

  trap 'exit 0' INT

  if [ -z "$FILE_PATH" ]; then
    gf_helper_show_empty_content "$QUERY" | gf_helper_inspect_pager
  elif [ -z "$QUERY" ]; then
    gf_git_command_with_header_default_parameters 1 "$GF_DIFF_FILE_PREVIEW_DEFAULTS" show --first-parent "$GF_SHOW_REF" -- "$FILE_PATH" |
      gf_helper_inspect_diff_renderer |
      gf_helper_inspect_pager
  else
    gf_git_command_with_header_default_parameters 1 "$GF_DIFF_FILE_PREVIEW_DEFAULTS" show --first-parent "$GF_SHOW_REF" -- "$FILE_PATH" |
      gf_helper_inspect_diff_renderer |
      grep --color=always -E "$QUERY|$" |
      gf_helper_inspect_pager
  fi
}
