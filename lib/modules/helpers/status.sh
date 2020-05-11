#!/usr/bin/env bash

GF_STATUS_DIRECTORY_PREVIEW_COMMAND='ls -l --color=always'
if type exa >/dev/null 2>&1; then
  GF_STATUS_DIRECTORY_PREVIEW_COMMAND='exa -l --color=always'
fi

GF_STATUS_FILE_PREVIEW_COMMAND='cat'
if type bat >/dev/null 2>&1; then
  GF_STATUS_FILE_PREVIEW_COMMAND='bat --color=always'
fi

gf_helper_status_preview_content() {
  STATUS_CODE="$1"
  FILE_PATH="$2"

  # NB: git status will quote paths with whitespace. currently that's not supported

  if [ "??" = "$STATUS_CODE" ]; then
    if [ -d "$FILE_PATH" ]; then
      # shellcheck disable=2086
      gf_command_with_header 2 $GF_STATUS_DIRECTORY_PREVIEW_COMMAND "$FILE_PATH"
    else
      # shellcheck disable=2086
      gf_command_with_header 2 $GF_STATUS_FILE_PREVIEW_COMMAND "$FILE_PATH"
    fi
  elif [ ! -e "$FILE_PATH" ]; then
    echo "\`${CYAN}${FILE_PATH}${NORMAL}\` ${RED}${BOLD}Deleted${NORMAL}"
  else
    # TODO this doesn't work for renames
    gf_git_command_with_header 1 diff HEAD -- "$FILE_PATH" | gf_diff_renderer
  fi
}

gf_helper_status_menu_content() {
  gf_git_command_with_header 2 status --short
}

gf_helper_status_add() {
  gf_command_logged git add -- "$@"
}

gf_helper_status_reset() {
  gf_command_logged git reset -- "$@"
}

gf_helper_status_discard() {
  if [ "$#" = 0 ]; then
    gf_log_error 'tried to CHECKOUT in status with no file(s)'
  else
    while [ "$#" -gt 0 ]; do
      if git ls-files --error-unmatch "$1" > /dev/null 2>&1; then
        gf_command_logged git checkout HEAD -- "$1"
      else
        gf_command_logged rm -rf "$1"
      fi
      shift
    done
  fi
}

gf_helper_status_edit() {
  if [ "$#" = 0 ]; then
    gf_log_error 'tried to EDIT in status with no file(s)'
  else
    # shellcheck disable=2086
    gf_interactive_command_logged "$EDITOR" $GF_EDITOR_ARGS "$@"
  fi
}

gf_helper_status_commit() {
  # shellcheck disable=2086
  gf_interactive_command_logged git commit
}
