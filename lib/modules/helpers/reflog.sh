#!/usr/bin/env bash

# get the first token by `|`
gf_helper_reflog_log_query() {
  echo "$1" | cut -d'|' -f1
}

# get the _last_ token by `|`
# NB: this supports using the same query for both chunks
gf_helper_reflog_diff_query() {
  echo "$1" | rev | cut -d'|' -f1 | rev
}

# TODO faithfully pass `reflog` params to `reflog_menu_contents`
gf_helper_reflog_menu_content() {
  QUERY="$(git fuzzy helper reflog_log_query "$1")"
  shift
  if [ -n "$QUERY" ]; then
    # shellcheck disable=2086
    gf_git_command_with_header_default_parameters 2 "$GF_REFLOG_MENU_PARAMS" reflog $QUERY "$@"
  else
    gf_git_command_with_header_default_parameters 2 "$GF_REFLOG_MENU_PARAMS" reflog "$@"
  fi
}

gf_helper_reflog_preview_content() {
  if [ -z "$1" ]; then
    echo "nothing to show"
  else
    REF="$(extract_commit_hash_from_first_line "$1")"
    QUERY="$(git fuzzy helper reflog_diff_query "$2")"
    BASE="$(extract_commit_hash_from_first_line "$3")"

    if [ "$BASE" == "$REF" ]; then
      MERGE_BASE="$(git merge-base "$GF_BASE_BRANCH" "$REF")"
      if [ "$(particularly_small_screen)" = '0' ]; then
        # shellcheck disable=2086
        gf_git_command log $GF_LOG_MENU_PARAMS "$MERGE_BASE..$REF"
        echo
      fi
      # shellcheck disable=2086
      gf_git_command_with_header_default_parameters 1 "$GF_DIFF_COMMIT_RANGE_PREVIEW_DEFAULTS" diff "$MERGE_BASE..$REF" $QUERY | gf_diff_renderer
    else
      # shellcheck disable=2086
      gf_git_command_with_header_default_parameters 1 "$GF_DIFF_COMMIT_RANGE_PREVIEW_DEFAULTS" diff "$BASE" "$REF" $QUERY | gf_diff_renderer
    fi
  fi
}
