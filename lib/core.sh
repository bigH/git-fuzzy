#!/usr/bin/env bash

GIT_FUZZY_SELECT_ALL_KEY="${GIT_FUZZY_SELECT_ALL_KEY:-Alt-A}"
GIT_FUZZY_SELECT_NONE_KEY="${GIT_FUZZY_SELECT_NONE_KEY:-Alt-D}"

if [ -z "$GF_FZF_DEFAULTS_SET" ]; then
  export GF_FZF_DEFAULTS_SET="YES"

  # override the default global fzf configuration options to fit the git-fuzzy use case
  # allow the user to override the global fzf defaults by setting GIT_FUZZY_FZF_DEFAULT_OPTS

  if [ -z "$GIT_FUZZY_FZF_DEFAULT_OPTS" ]; then
    export FZF_DEFAULT_OPTS="\
      $FZF_DEFAULT_OPTS \
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
  else
    export FZF_DEFAULT_OPTS="\
      $FZF_DEFAULT_OPTS \
      $GIT_FUZZY_FZF_DEFAULT_OPTS"
  fi

  export FZF_DEFAULT_OPTS_MULTI="\
    $FZF_DEFAULT_OPTS_MULTI \
    --bind \"$(lowercase "$GIT_FUZZY_SELECT_NONE_KEY"):deselect-all\" \
    --bind \"$(lowercase "$GIT_FUZZY_SELECT_ALL_KEY"):select-all\""
fi


GF_BC_STL='
define min(a, b) { if (a < b) return a else return b }
define max(a, b) { if (a > b) return a else return b }
'

WIDTH="$(tput cols)"
HEIGHT="$(tput lines)"

run_bc_program() {
  WIDTH_SUBSTITUTED="${1//__WIDTH__/$WIDTH}"
  echo "${GF_BC_STL} ${GF_BC_LIB} ${WIDTH_SUBSTITUTED//__HEIGHT__/$HEIGHT}" | bc -l
}

is_vertical() {
  run_bc_program "__WIDTH__ / __HEIGHT__ < $GF_VERTICAL_THRESHOLD"
}

particularly_small_screen() {
  if [ "$(is_vertical)" = '1' ]; then
    run_bc_program "$GF_VERTICAL_SMALL_SCREEN_CALCULATION"
  else
    run_bc_program "$GF_HORIZONTAL_SMALL_SCREEN_CALCULATION"
  fi
}

preview_window_size_and_direction() {
  if [ "$(is_vertical)" = '1' ]; then
    PREVIEW_DIRECTION="$GF_VERTICAL_PREVIEW_LOCATION"
    PREVIEW_SIZE="$(run_bc_program "$GF_VERTICAL_PREVIEW_PERCENT_CALCULATION")"
  else
    PREVIEW_DIRECTION="$GF_HORIZONTAL_PREVIEW_LOCATION"
    PREVIEW_SIZE="$(run_bc_program "$GF_HORIZONTAL_PREVIEW_PERCENT_CALCULATION")"
  fi

  # NB: round the `bc -l` result
  echo "--preview-window=$PREVIEW_DIRECTION:${PREVIEW_SIZE%%.*}%"
}

preview_window_settings() {
  echo "$(preview_window_size_and_direction):nohidden"
}

hidden_preview_window_settings() {
  echo "$(preview_window_size_and_direction):hidden"
}

gf_is_in_git_repo() {
  git -C . rev-parse > /dev/null 2>&1
}

gf_merge_base(){
  git merge-base HEAD "$@"
}

gf_git_root_directory() {
  git rev-parse --show-toplevel
}

gf_go_to_git_root_directory() {
  local git_root_directory
  git_root_directory="$(gf_git_root_directory)"
  gf_log_debug "going to git root at ${git_root_directory} from $(pwd)"
  cd "${git_root_directory}"
}

gf_diff_renderer() {
  if [ -n "$GF_PREFERRED_PAGER" ]; then
    if [ -n "$FZF_PREVIEW_COLUMNS" ]; then
      cat - | ${GF_PREFERRED_PAGER//__WIDTH__/$FZF_PREVIEW_COLUMNS}
    else
      cat - | ${GF_PREFERRED_PAGER//__WIDTH__/$WIDTH}
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
  local gf_command="fzf --ansi --no-sort --no-info --multi \
    $FZF_DEFAULT_OPTS_MULTI \
    $(preview_window_settings) \
    $(quote_params "$@")"

  if [ -n "$GF_COMMAND_FZF_DEBUG_MODE" ]; then
    gf_log_command_string "$gf_command"
  fi

  eval "$gf_command"
}

gf_fzf_one() {
  local gf_command="fzf +m --ansi --no-sort --no-info \
            $(preview_window_settings) \
            $(quote_params "$@")"
  if [ -n "$GF_COMMAND_FZF_DEBUG_MODE" ]; then
    gf_log_command_string "$gf_command"
  fi
  eval "$gf_command"
}

gf_command_with_header() {
  NUM="$1"
  shift
  printf "%s" "$GRAY" "$BOLD" '$ ' "$CYAN" "$BOLD"
  # shellcheck disable=2046
  printf "%s " $(printf '%q ' "$@")
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
  printf "%s" "$GRAY" "$BOLD" '$ ' "$CYAN" "$BOLD" "$GIT_CMD $(quote_params "$@")" "$NORMAL"
  # shellcheck disable=2034
  for i in $(seq 1 "$NUM"); do
    echo
  done
  "$GIT_CMD" -c color.ui=always "$@"
}

gf_git_command_with_header_default_parameters() {
  NUM="$1"
  shift
  DEFAULT_SUBCOMMAND_PARAMETERS="$1"
  shift
  SUB_COMMAND="$1"
  shift
  printf "%s" "$GRAY" "$BOLD" '$ ' "$CYAN" "$BOLD" "$GIT_CMD $SUB_COMMAND $(quote_params "$@")" "$NORMAL"
  # shellcheck disable=2034
  for i in $(seq 0 "$NUM"); do
    [ "$i" -gt 0 ] && echo
  done
  gf_log_command_string "$GIT_CMD -c color.ui=always '$SUB_COMMAND' $DEFAULT_SUBCOMMAND_PARAMETERS $(quote_params "$@")"
  eval "$GIT_CMD -c color.ui=always '$SUB_COMMAND' $DEFAULT_SUBCOMMAND_PARAMETERS $(quote_params "$@")"
}

gf_quit() {
  gf_log_debug "exiting"
  exit 0
}
