#!/usr/bin/env bash

GF_STATUS_DIRECTORY_PREVIEW_COMMAND='ls -l --color=always'
if type eza >/dev/null 2>&1; then
  GF_STATUS_DIRECTORY_PREVIEW_COMMAND='eza -l --color=always'
elif type exa >/dev/null 2>&1; then
  GF_STATUS_DIRECTORY_PREVIEW_COMMAND='exa -l --color=always'
elif type lsd >/dev/null 2>&1; then
  GF_STATUS_DIRECTORY_PREVIEW_COMMAND='lsd -l --color=always'
fi

GF_STATUS_FILE_PREVIEW_COMMAND='cat'
if type bat >/dev/null 2>&1; then
  GF_STATUS_FILE_PREVIEW_COMMAND='bat --color=always'
fi

gf_helper_status_preview_content() {
  STATUS_CODE="$1"
  FILE_PATH="$2"
  RENAMED_FILE_PATH="$3"

  # NB: git status will quote paths with whitespace. currently that's not supported

  if [ "??" = "$STATUS_CODE" ]; then
    # new files/dirs get special treatment since `git diff` won't handle them
    if [ -d "$FILE_PATH" ]; then
      # shellcheck disable=2086
      gf_command_with_header 2 $GF_STATUS_DIRECTORY_PREVIEW_COMMAND "$FILE_PATH"
    else
      # shellcheck disable=2086
      gf_command_with_header 2 $GF_STATUS_FILE_PREVIEW_COMMAND "$FILE_PATH"
    fi
  elif [ ! -e "$FILE_PATH" ] && [ -n "$RENAMED_FILE_PATH" ]; then
    gf_git_command_with_header 1 diff HEAD -M -- "$FILE_PATH" "$RENAMED_FILE_PATH" | gf_diff_renderer
  else
    gf_git_command_with_header 1 diff HEAD -M -- "$FILE_PATH" | gf_diff_renderer
  fi
}

gf_helper_status_menu_content() {
  gf_git_command_with_header 2 status --short
}

gf_helper_status_add() {
  gf_command_logged git add -- "$@"
}

gf_helper_status_amend() {
  gf_command_logged git commit --amend --reuse-message=HEAD
}

gf_helper_status_add_patch() {
  if [ "$#" = 0 ]; then
    gf_log_error 'tried to git add --patch with no file(s)'
  else
    gf_interactive_command_logged git add --patch -- "$@" < /dev/tty
  fi

  # if there's more to commit, loop right back into the status view
  if [ -n "$(git status -s)" ]; then
    gf_interactive_command_logged git fuzzy status
  fi
}

gf_helper_status_reset() {
  gf_command_logged git reset -- "$@"
}

gf_helper_status_discard() {
  if [ "$#" = 0 ]; then
    gf_log_error 'tried to CHECKOUT in status with no file(s)'
  else
    if git ls-files --error-unmatch "$1" > /dev/null 2>&1; then
      gf_command_logged git checkout HEAD -- "$@"
    else
      gf_command_logged rm -rf "$@"
    fi
  fi
}

gf_helper_status_edit() {
  if [ "$#" = 0 ]; then
    gf_log_error 'tried to EDIT in status with no file(s)'
  else
    # shellcheck disable=2086
    gf_interactive_command_logged "$EDITOR" $GF_EDITOR_ARGS "$@" < /dev/tty
  fi
}

gf_helper_status_commit() {
  # shellcheck disable=2086
  gf_interactive_command_logged git commit

  # if there's more to commit, loop right back into the status view
  if [ -n "$(git status -s)" ]; then
    gf_interactive_command_logged git fuzzy status
  fi
}
