#!/usr/bin/env bash

export FZF_DEFAULT_OPTS="\
  --border \
  --layout=reverse \
  --bind 'ctrl-space:toggle-preview' \
  --bind 'ctrl-j:down' \
  --bind 'ctrl-k:up' \
  --bind 'ctrl-d:half-page-down' \
  --bind 'ctrl-u:half-page-up' \
  --bind 'ctrl-s:toggle-sort' \
  --bind 'ctrl-e:preview-down' \
  --bind 'ctrl-y:preview-up' \
  --bind 'change:top' \
  --no-height"

export GF_BC_STL='
define min(a, b) { if (a < b) return a else return b }
define max(a, b) { if (a > b) return a else return b }
'

preview_window_settings() {
  IS_VERTICAL="$(run_bc_program "__WIDTH__ / __HEIGHT__ < $GF_VERTICAL_THRESHOLD")"

  if [ "$IS_VERTICAL" = '1' ]; then
    PREVIEW_DIRECTION="$GF_VERTICAL_PREVIEW_LOCATION"
    PREVIEW_SIZE="$(run_bc_program "$GF_VERTICAL_PREVIEW_PERCENT_CALCULATION")"
  else
    PREVIEW_DIRECTION="$GF_HORIZONTAL_PREVIEW_LOCATION"
    PREVIEW_SIZE="$(run_bc_program "$GF_HORIZONTAL_PREVIEW_PERCENT_CALCULATION")"
  fi

  # NB: round the `bc -l` result
  echo "--preview-window=$PREVIEW_DIRECTION:${PREVIEW_SIZE%%.*}%"
}

run_bc_program() {
  WIDTH="$(tput cols)"
  HEIGHT="$(tput lines)"

  WIDTH_SUBSTITUTED="${1//__WIDTH__/$WIDTH}"
  echo "${GF_BC_STL} ${GF_BC_LIB} ${WIDTH_SUBSTITUTED//__HEIGHT__/$HEIGHT}" | bc -l
}

hidden_preview_window_settings() {
  echo "$(preview_window_settings):hidden"
}

join_lines_quoted() {
  paste -s -d"%" - | sed "s/%/' '/g" | sed "s/^/'/" | sed "s/$/'/"
}

gf_is_in_git_repo() {
  git rev-parse HEAD > /dev/null 2>&1
}

gf_merge_base(){
  if [ "$#" -eq 1 ]; then
    git merge-base HEAD "$1"
  else
    git merge-base HEAD "$@"
  fi
}

gf_diff_renderer() {
  if [ -n "$GF_PREFERRED_PAGER" ]; then
    if [ -n "$FZF_PREVIEW_COLUMNS" ]; then
      cat - | ${GF_PREFERRED_PAGER//__WIDTH__/$FZF_PREVIEW_COLUMNS}
    else
      cat - | $GF_PREFERRED_PAGER
    fi
  elif type delta >/dev/null 2>&1; then
    if [ -n "$FZF_PREVIEW_COLUMNS" ]; then
      cat - | delta --width "$FZF_PREVIEW_COLUMNS"
    else
      cat - | delta
    fi
  elif type diff-so-fancy >/dev/null 2>&1; then
    cat - | diff-so-fancy
  else
    cat -
  fi
}

gf_command_logged() {
  gf_log_command "$@"
  if [ -n "$GF_COMMAND_LOG_OUTPUT" ]; then
    "$@" >> "$GF_LOG_LOCATION" 2>&1
  else
    "$@" >/dev/null 2>&1
  fi
}

gf_interactive_command_logged() {
  gf_log_command "$@"
  "$@"
}

gf_fzf() {
  if [ -n "$GF_COMMAND_FZF_DEBUG_MODE" ]; then
    gf_log_command "fzf --ansi --no-sort --no-info \
            $FZF_DEFAULT_OPTS_MULTI \
            $(preview_window_settings) \
            $(quote_params "$@")"
  fi
  eval "fzf --ansi --no-sort --no-info \
          $FZF_DEFAULT_OPTS_MULTI \
          $(preview_window_settings) \
          $(quote_params "$@")"
}

gf_fzf_one() {
  if [ -n "$GF_COMMAND_FZF_DEBUG_MODE" ]; then
    gf_log_command "fzf +m --ansi --no-sort --no-info \
            $(preview_window_settings) \
            $(quote_params "$@")"
  fi
  eval "fzf +m --ansi --no-sort --no-info \
          $(preview_window_settings) \
          $(quote_params "$@")"
}

gf_command_with_header() {
  NUM="$1"
  shift
  printf "%s" "$GRAY" "$BOLD" '$ ' "$CYAN" "$BOLD"
  # shellcheck disable=2046
  printf "%s " $(quote_params "$@")
  printf "%s" "$NORMAL"
  # shellcheck disable=2034
  for i in $(seq 1 "$NUM"); do
    echo
  done
  "$@"
}

gf_git_command() {
  "$GIT_CMD" -c color.ui=always "$@"
}

gf_git_command_with_header() {
  NUM="$1"
  shift
  printf "%s" "$GRAY" "$BOLD" '$ ' "$CYAN" "$BOLD"
  # shellcheck disable=2046
  printf "$GIT_CMD "
  printf "%s" "$(quote_params "$@")"
  printf "%s" "$NORMAL"
  # shellcheck disable=2034
  for i in $(seq 1 "$NUM"); do
    echo
  done
  "$GIT_CMD" -c color.ui=always "$@"
}

gf_git_command_with_header_hidden_parameters() {
  NUM="$1"
  shift
  HIDDEN_PARAMETERS="$1"
  shift
  SUB_COMMAND="$1"
  shift
  printf "%s" "$GRAY" "$BOLD" '$ ' "$CYAN" "$BOLD"
  # shellcheck disable=2046
  printf "%s " "$GIT_CMD"
  printf "%s" "$SUB_COMMAND " "$(quote_params "$@")"
  printf "%s" "$NORMAL"
  # shellcheck disable=2034
  for i in $(seq 1 "$NUM"); do
    echo
  done
  # shellcheck disable=2086
  gf_log_command_string "$GIT_CMD  -c color.ui=always '$SUB_COMMAND' $HIDDEN_PARAMETERS $(quote_params "$@")"
  eval "$GIT_CMD  -c color.ui=always '$SUB_COMMAND' $HIDDEN_PARAMETERS $(quote_params "$@")"
}

gf_quit() {
  gf_log_debug "exiting"
  exit 0
}
