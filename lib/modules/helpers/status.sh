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

  gf_preview_shortcuts_header_with_inspect

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

# Full-screen pager view of a file's diff, invoked from the inspect keybind.
gf_helper_status_inspect_pager() {
  gf_helper_inspect_pager
}

gf_helper_status_diff_renderer() {
  gf_helper_inspect_diff_renderer
}

gf_helper_status_diff() {
  STATUS_CODE="$1"
  FILE_PATH="$2"
  RENAMED_FILE_PATH="$3"

  # Trap Ctrl-C so it returns to fzf instead of killing git-fuzzy
  trap 'exit 0' INT

  if [ "??" = "$STATUS_CODE" ]; then
    # new files/dirs
    if [ -d "$FILE_PATH" ]; then
      # shellcheck disable=2086
      $GF_STATUS_DIRECTORY_PREVIEW_COMMAND "$FILE_PATH" | gf_helper_status_inspect_pager
    else
      # shellcheck disable=2086
      $GF_STATUS_FILE_PREVIEW_COMMAND "$FILE_PATH" | gf_helper_status_inspect_pager
    fi
  elif [ ! -e "$FILE_PATH" ] && [ -n "$RENAMED_FILE_PATH" ]; then
    git --no-pager -c color.ui=always \
      diff HEAD -M -- "$FILE_PATH" "$RENAMED_FILE_PATH" |
      gf_helper_status_diff_renderer |
      gf_helper_status_inspect_pager
  else
    git --no-pager -c color.ui=always \
      diff HEAD -M -- "$FILE_PATH" |
      gf_helper_status_diff_renderer |
      gf_helper_status_inspect_pager
  fi
}

gf_helper_status_menu_content() {
  gf_git_command_with_header 2 status --short
}

gf_helper_status_valid_port() {
  case "$1" in
    ''|*[!0-9]*)
      return 1
      ;;
  esac
}

gf_helper_status_fzf_post() {
  local port="$1"
  local action="$2"

  gf_helper_status_valid_port "$port" || return
  curl -fsS -XPOST "localhost:$port" --data-binary "$action" > /dev/null 2>&1
}

gf_helper_status_add() {
  local paths
  paths=$(echo "$@" | sed 's/[^ ]* -> //g')
  gf_command_logged git add -- $paths
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
  local paths
  paths=$(echo "$@" | sed 's/[^ ]* -> //g')
  gf_command_logged git reset -- $paths
}

gf_helper_status_discard() {
  if [ "$#" = 0 ]; then
    gf_log_error 'tried to CHECKOUT in status with no file(s)'
  else
    local paths
    paths=$(echo "$@" | sed 's/[^ ]* -> //g')
    if git ls-files --error-unmatch "${paths%% *}" > /dev/null 2>&1; then
      gf_command_logged git checkout HEAD -- $paths
    else
      gf_command_logged rm -rf $paths
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

gf_helper_status_watch() {
  local port="$1"
  local debounce="${GF_STATUS_WATCH_DEBOUNCE:-0.5}"
  local git_root
  git_root="$(git rev-parse --show-toplevel)"

  if [ "${GF_STATUS_WATCH}" = "0" ]; then
    return
  fi

  local reload_action="reload-sync(git fuzzy helper status_menu_content)"

  # Self-terminates when fzf exits: curl fails → break → pipe closes → SIGPIPE kills watcher
  if type fswatch > /dev/null 2>&1; then
    {
      fswatch --latency "$debounce" --exclude '/\.git/' -r "$git_root" &
      fswatch --latency "$debounce" --exclude '.*' --include '/index$' --include '/HEAD$' --include '/refs/' -r "$git_root/.git" &
      wait
    } | while read -r _; do
      while read -r -t 0.05 _; do :; done
      gf_helper_status_fzf_post "$port" "$reload_action" || break
    done
  elif type inotifywait > /dev/null 2>&1; then
    # inotifywait lacks include-before-exclude, so run focused watchers and merge their output.
    {
      inotifywait -m -r -q --exclude '\.git/' -e modify,create,delete,move "$git_root" &
      inotifywait -m -q -e create,move "$git_root/.git" &
      if [ -e "$git_root/.git/index" ]; then
        inotifywait -m -q -e modify "$git_root/.git/index" &
      fi
      inotifywait -m -q -e modify "$git_root/.git/HEAD" &
      inotifywait -m -r -q -e modify,create,delete,move "$git_root/.git/refs" &
      wait
    } | while read -r _; do
      while read -r -t "$debounce" _; do :; done
      gf_helper_status_fzf_post "$port" "$reload_action" || break
    done
  fi
}
