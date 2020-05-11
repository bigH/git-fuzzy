#!/usr/bin/env bash

# get the first token by `|`
gf_helper_log_log_query() {
  echo "$1" | cut -d'|' -f1
}

# get the _last_ token by `|`
# NB: this supports using the same query for both chunks
gf_helper_log_diff_query() {
  echo "$1" | rev | cut -d'|' -f1 | rev
}

gf_helper_log_menu_content() {
  if [ -n "$1" ]; then
    QUERY="$(git fuzzy helper log_log_query "$1")"
    shift
    # shellcheck disable=2086
    gf_git_command_with_header_hidden_parameters 2 "$GF_LOG_MENU_PARAMS" log "$@" $QUERY
  else
    shift
    gf_git_command_with_header_hidden_parameters 2 "$GF_LOG_MENU_PARAMS" log "$@"
  fi
}

gf_helper_log_preview_content() {
  if [ -z "$1" ]; then
    echo "nothing to show"
  else
    REF="$1"
    QUERY="$(git fuzzy helper log_diff_query "$2")"

    # gf_git_command_with_header diff --stat="$FZF_PREVIEW_COLUMNS" "$REF^" "$REF"
    # echo

    # NB: `fold` is not aware of color codes; however, folding over whitespace seems fine
    gf_git_command show --decorate --no-patch "$REF" | fold -s -w "$FZF_PREVIEW_COLUMNS"
    echo

    # shellcheck disable=2086
    gf_git_command_with_header_hidden_parameters 1 "$GF_DIFF_COMMIT_PREVIEW_DEFAULTS" diff "$REF^" "$REF" $QUERY | gf_diff_renderer
  fi
}
