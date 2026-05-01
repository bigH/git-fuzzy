#!/usr/bin/env bash

# `*` means use both parts, otherwise `log` gets only the first part
gf_helper_log_log_query() {
  if [ "${1:0:1}" = '*' ]; then
    echo "$(query_part_one "$1") $(query_part_two "$1")"
  else
    query_part_one "$1"
  fi
}

# `#` means use both parts, otherwise `show`/`diff` gets only the second part
gf_helper_log_diff_query() {
  if [ "${1:0:1}" = '#' ]; then
    echo "$(query_part_one "$1") $(query_part_two "$1")"
  else
    query_part_two "$1"
  fi
}

query_part_one() {
  echo "$1" | sed -E 's/[#*]?([^|]*)([|](.*))?/\1/'
}

query_part_two() {
  echo "$1" | sed -E 's/[#*]?(([^|]*)[|])?(.*)/\3/'
}

# TODO faithfully pass `log` params to `log_menu_content` (e.g. branch name)
gf_helper_log_menu_content() {
  QUERY="$(git fuzzy helper log_log_query "$1")"
  shift
  if [ -n "$QUERY" ]; then
    # shellcheck disable=2086
    gf_git_command_with_header_default_parameters 2 "$GF_LOG_MENU_PARAMS" log $QUERY "$@"
  else
    gf_git_command_with_header_default_parameters 2 "$GF_LOG_MENU_PARAMS" log "$@"
  fi
}

gf_helper_log_preview_content() {
  if [ -z "$1" ]; then
    gf_preview_shortcuts_header
    echo "nothing to show (empty line)"
  else
    REF="$(extract_commit_hash_from_first_line "$1")"
    if [ -n "$REF" ]; then
      gf_preview_shortcuts_header_with_inspect

      QUERY="$(git fuzzy helper log_diff_query "$2")"
      BASE="$(extract_commit_hash_from_first_line "$3")"

      if [ "$BASE" == "$REF" ]; then
        # shellcheck disable=2086
        gf_git_command_with_header_default_parameters 1 "$GF_DIFF_COMMIT_PREVIEW_DEFAULTS" show --first-parent "$REF" $QUERY | gf_diff_renderer
      else
        # shellcheck disable=2086
        gf_git_command_with_header_default_parameters 1 "$GF_DIFF_COMMIT_PREVIEW_DEFAULTS" diff "$BASE" "$REF" $QUERY | gf_diff_renderer
      fi
    else
      gf_preview_shortcuts_header
      echo "nothing to show (no commit found on line)"
    fi
  fi
}

gf_helper_log_inspect() {
  [ -z "$1" ] && return

  REF="$(extract_commit_hash_from_first_line "$1")"
  [ -z "$REF" ] && return

  trap 'exit 0' INT

  QUERY="$(git fuzzy helper log_diff_query "$2")"
  BASE="$(extract_commit_hash_from_first_line "$3")"

  if [ "$BASE" == "$REF" ]; then
    # shellcheck disable=2086
    gf_git_command_with_header_default_parameters 1 "$GF_DIFF_COMMIT_PREVIEW_DEFAULTS" show --first-parent "$REF" $QUERY |
      gf_helper_inspect_diff_renderer |
      gf_helper_inspect_pager
  else
    # shellcheck disable=2086
    gf_git_command_with_header_default_parameters 1 "$GF_DIFF_COMMIT_PREVIEW_DEFAULTS" diff "$BASE" "$REF" $QUERY |
      gf_helper_inspect_diff_renderer |
      gf_helper_inspect_pager
  fi
}

gf_helper_log_open_diff() {
  if [ -z "$1" ]; then
    echo "nothing to show (no mode selected)"
  else
    MODE="$1"
    shift
    if [ -z "$1" ]; then
      echo "nothing to show (empty line)"
    else
      REF="$(extract_commit_hash_from_first_line "$1")"
      if [ -n "$REF" ]; then
        case "$MODE" in
          commit)
            git fuzzy show "$REF"
            ;;
          working_copy)
            git fuzzy diff "$REF"
            ;;
          merge_base)
            git fuzzy diff "$(git merge-base "$GF_BASE_BRANCH" "$REF")" "$REF"
            ;;
          *)
            log_error "mode unknown: $MODE"
            ;;
        esac
      else
        echo "nothing to show (no commit found on line)"
      fi
    fi
  fi
}
