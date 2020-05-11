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

gf_helper_reflog_menu_content() {
  if [ -n "$1" ]; then
    QUERY="$(git fuzzy helper reflog_log_query "$1")"
    # shellcheck disable=2086
    gf_git_command_with_header_hidden_parameters 2 "$GF_REFLOG_MENU_PARAMS" reflog "$@" $QUERY
  else
    gf_git_command_with_header_hidden_parameters 2 "$GF_REFLOG_MENU_PARAMS" reflog "$@"
  fi
}

gf_helper_reflog_preview_content() {
  if [ -z "$1" ]; then
    echo "nothing to show"
  else
    REF="$1"
    QUERY="$(git fuzzy helper reflog_diff_query "$2")"

    # shellcheck disable=2086
    gf_git_command_with_header_hidden_parameters 1 "$GF_DIFF_COMMIT_RANGE_PREVIEW_DEFAULTS" diff "$(git merge-base "$GF_BASE_BRANCH" "$REF")" "$REF" $QUERY | gf_diff_renderer
  fi
}
