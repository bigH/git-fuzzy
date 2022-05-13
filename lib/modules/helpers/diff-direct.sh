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

  FOUND=
  for INDEX_OF_ARG in $(seq 0 $#); do
    VALUE="${!INDEX_OF_ARG}"
    if [ "$VALUE" = '--' ]; then
      FOUND=yes
      break
    fi
  done

  ARGS_TO_PASS=("$@")
  if [ -n "$FOUND" ]; then
    ARGS_TO_PASS=("${@:1:$((INDEX_OF_ARG - 1))}")
  fi

  if [ -z "$FILE_PATH" ]; then
    echo "nothing to show"
  elif [ -z "$QUERY" ]; then
    # shellcheck disable=2086,2090
    gf_git_command_with_header_default_parameters 1 "$GF_DIFF_FILE_PREVIEW_DEFAULTS" diff "${ARGS_TO_PASS[@]}" -- "$FILE_PATH" | gf_diff_renderer
  else
    # shellcheck disable=2086,2090
    gf_git_command_with_header_default_parameters 1 "$GF_DIFF_FILE_PREVIEW_DEFAULTS" diff "${ARGS_TO_PASS[@]}" -- "$FILE_PATH" | gf_diff_renderer | grep --color=always -E "$QUERY|$"
  fi
}
