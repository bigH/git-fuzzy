#!/usr/bin/env bash

gf_helper_diff_direct_menu_content() {
  QUERY="$1"
  shift
  if [ -z "$QUERY" ]; then
    gf_git_command_with_header 2 diff --name-only "$@"
  else
    # shellcheck disable=2086
    gf_git_command_with_header 2 diff $GF_DIFF_SEARCH_DEFAULTS "$QUERY" --name-only "$@"
  fi
}

gf_helper_diff_direct_preview_content() {
  QUERY="$1"
  shift

  FILE_PATH="$1"
  shift

  if [ -z "$FILE_PATH" ]; then
    echo "nothing to show"
  elif [ -z "$QUERY" ]; then
    # shellcheck disable=2086,2090
    gf_git_command_with_header_hidden_parameters 1 "$GF_DIFF_FILE_PREVIEW_DEFAULTS" diff "$@" -- "$FILE_PATH" | gf_diff_renderer
  else
    # shellcheck disable=2086,2090
    gf_git_command_with_header_hidden_parameters 1 "$GF_DIFF_FILE_PREVIEW_DEFAULTS" diff "$@" -- "$FILE_PATH" | gf_diff_renderer | grep --color=always -E "$QUERY|$"
  fi
}
