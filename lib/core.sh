#!/usr/bin/env bash

GIT_FUZZY_SELECT_ALL_KEY="${GIT_FUZZY_SELECT_ALL_KEY:-Alt-A}"
GIT_FUZZY_SELECT_NONE_KEY="${GIT_FUZZY_SELECT_NONE_KEY:-Alt-D}"
GIT_FUZZY_PREVIEW_WRAP_KEY="${GIT_FUZZY_PREVIEW_WRAP_KEY:-Alt-W}"
GIT_FUZZY_PREVIEW_SIZE_INCREASE_KEY="${GIT_FUZZY_PREVIEW_SIZE_INCREASE_KEY:-Alt-=}"
GIT_FUZZY_PREVIEW_SIZE_DECREASE_KEY="${GIT_FUZZY_PREVIEW_SIZE_DECREASE_KEY:-Alt--}"
GIT_FUZZY_INSPECT_KEY="${GIT_FUZZY_INSPECT_KEY:-${GIT_FUZZY_STATUS_DIFF_KEY:-Alt-I}}"

GF_PREVIEW_HEADER_MIN_LINES="${GF_PREVIEW_HEADER_MIN_LINES:-8}"
GF_PREVIEW_HEADER_MIN_COLUMNS="${GF_PREVIEW_HEADER_MIN_COLUMNS:-50}"
GF_PREVIEW_RESIZE_HORIZONTAL_STEP="${GF_PREVIEW_RESIZE_HORIZONTAL_STEP:-${GF_PREVIEW_RESIZE_SIZE_STEP:-${GF_PREVIEW_RESIZE_PERCENT_STEP:-5}}}"
GF_PREVIEW_RESIZE_VERTICAL_STEP="${GF_PREVIEW_RESIZE_VERTICAL_STEP:-${GF_PREVIEW_RESIZE_SIZE_STEP:-${GF_PREVIEW_RESIZE_PERCENT_STEP:-2}}}"

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

# Prevent background read-only git operations (like git status in the preview) from
# taking optional locks and conflicting with explicit operations like git add.
export GIT_OPTIONAL_LOCKS=0

GF_BC_STL='
define min(a, b) { if (a < b) return a else return b }
define max(a, b) { if (a > b) return a else return b }
'

WIDTH="$(tput cols)"
HEIGHT="$(tput lines)"

# Memoized geometry: WIDTH/HEIGHT are fixed at source time, so these pure
# functions are computed once per process (empty = not-yet-computed).
__GF_IS_VERTICAL=""
__GF_SMALL_SCREEN=""

run_bc_program() {
  WIDTH_SUBSTITUTED="${1//__WIDTH__/$WIDTH}"
  echo "${GF_BC_STL} ${GF_BC_LIB} ${WIDTH_SUBSTITUTED//__HEIGHT__/$HEIGHT}" | bc -l
}

is_vertical() {
  if [ -z "$__GF_IS_VERTICAL" ]; then
    __GF_IS_VERTICAL="$(run_bc_program "__WIDTH__ / __HEIGHT__ < $GF_VERTICAL_THRESHOLD")"
  fi
  printf '%s' "$__GF_IS_VERTICAL"
}

particularly_small_screen() {
  if [ -z "$__GF_SMALL_SCREEN" ]; then
    if [ "$(is_vertical)" = '1' ]; then
      __GF_SMALL_SCREEN="$(run_bc_program "$GF_VERTICAL_SMALL_SCREEN_CALCULATION")"
    else
      __GF_SMALL_SCREEN="$(run_bc_program "$GF_HORIZONTAL_SMALL_SCREEN_CALCULATION")"
    fi
  fi
  printf '%s' "$__GF_SMALL_SCREEN"
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

preview_window_dimension() {
  case "$1" in
    up|down|top|bottom)
      echo "lines"
      ;;
    *)
      echo "columns"
      ;;
  esac
}

preview_window_resize_dimension() {
  local line_gap
  local column_gap

  if gf_is_positive_integer "$FZF_LINES" &&
    gf_is_positive_integer "$FZF_COLUMNS" &&
    gf_is_positive_integer "$FZF_PREVIEW_LINES" &&
    gf_is_positive_integer "$FZF_PREVIEW_COLUMNS"; then
    line_gap="$((FZF_LINES - FZF_PREVIEW_LINES))"
    column_gap="$((FZF_COLUMNS - FZF_PREVIEW_COLUMNS))"

    if [ "$column_gap" -le "$line_gap" ]; then
      echo "lines"
    else
      echo "columns"
    fi
    return
  fi

  if [ "$(is_vertical)" = '1' ]; then
    preview_window_dimension "$GF_VERTICAL_PREVIEW_LOCATION"
  else
    preview_window_dimension "$GF_HORIZONTAL_PREVIEW_LOCATION"
  fi
}

preview_window_settings() {
  echo "$(preview_window_size_and_direction):nohidden"
}

hidden_preview_window_settings() {
  echo "$(preview_window_size_and_direction):hidden"
}

gf_is_positive_integer() {
  case "$1" in
    ''|*[!0-9]*)
      return 1
      ;;
    *)
      [ "$1" -gt 0 ]
      ;;
  esac
}

gf_preview_header_is_hidden() {
  local min_lines="$GF_PREVIEW_HEADER_MIN_LINES"
  local min_columns="$GF_PREVIEW_HEADER_MIN_COLUMNS"

  gf_is_positive_integer "$FZF_PREVIEW_LINES" || return 0
  gf_is_positive_integer "$FZF_PREVIEW_COLUMNS" || return 0
  gf_is_positive_integer "$min_lines" || min_lines=8
  gf_is_positive_integer "$min_columns" || min_columns=50

  [ "$FZF_PREVIEW_LINES" -lt "$min_lines" ] ||
    [ "$FZF_PREVIEW_COLUMNS" -lt "$min_columns" ]
}

gf_preview_shortcuts_header() {
  gf_preview_header_is_hidden && return

  printf "%s%s %s%s  %s%-5s%s     %s%-7s %s%s  %s%s%s\n" \
    "$GREEN" "wrap" "↩" "$NORMAL" \
    "$WHITE" "$GIT_FUZZY_PREVIEW_WRAP_KEY" "$NORMAL" \
    "$GREEN" "bigger" "↗" "$NORMAL" \
    "$WHITE" "$GIT_FUZZY_PREVIEW_SIZE_INCREASE_KEY" "$NORMAL"
  printf "%18s%s%-7s %s%s  %s%s%s" "" \
    "$GREEN" "smaller" "↙" "$NORMAL" \
    "$WHITE" "$GIT_FUZZY_PREVIEW_SIZE_DECREASE_KEY" "$NORMAL"
  echo
  echo
}

gf_preview_shortcuts_header_with_inspect() {
  gf_preview_header_is_hidden && return

  printf "   %s%s %s%s  %s%-5s%s     %s%7s %s%s  %s%s%s\n" \
    "$GREEN" "wrap" "↩ " "$NORMAL" \
    "$WHITE" "$GIT_FUZZY_PREVIEW_WRAP_KEY" "$NORMAL" \
    "$GREEN" "bigger" "↗" "$NORMAL" \
    "$WHITE" "$GIT_FUZZY_PREVIEW_SIZE_INCREASE_KEY" "$NORMAL"
  printf "%s%-7s %s%s  %s%s%s     %s%7s %s%s  %s%s%s" \
    "$GREEN" "inspect" "🔍" "$NORMAL" \
    "$WHITE" "$GIT_FUZZY_INSPECT_KEY" "$NORMAL" \
    "$GREEN" "smaller" "↙" "$NORMAL" \
    "$WHITE" "$GIT_FUZZY_PREVIEW_SIZE_DECREASE_KEY" "$NORMAL"
  echo
  echo
}

gf_helper_preview_shortcuts_header() {
  gf_preview_shortcuts_header
}

gf_helper_preview_shortcuts_header_with_inspect() {
  gf_preview_shortcuts_header_with_inspect
}

gf_helper_preview_resize() {
  local action="$1"
  local current_size
  local dimension
  local total_size
  local next_size
  local step

  dimension="$(preview_window_resize_dimension)"
  if [ "$dimension" = "lines" ]; then
    current_size="$FZF_PREVIEW_LINES"
    total_size="$FZF_LINES"
    step="$GF_PREVIEW_RESIZE_VERTICAL_STEP"
  else
    current_size="$FZF_PREVIEW_COLUMNS"
    total_size="$FZF_COLUMNS"
    step="$GF_PREVIEW_RESIZE_HORIZONTAL_STEP"
  fi

  gf_is_positive_integer "$current_size" || return
  gf_is_positive_integer "$total_size" || return
  gf_is_positive_integer "$step" || step=5

  case "$action" in
    increase)
      next_size="$((current_size + step))"
      ;;
    decrease)
      next_size="$((current_size - step))"
      ;;
    *)
      return
      ;;
  esac

  [ "$next_size" -lt 1 ] && next_size=1
  [ "$next_size" -gt "$total_size" ] && next_size="$total_size"

  printf 'change-preview-window:%s\n' "$next_size"
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
      cat - | delta --paging=never --width "$FZF_PREVIEW_COLUMNS"
    else
      cat - | delta --paging=never
    fi
  elif type diff-so-fancy >/dev/null 2>&1; then
    cat - | diff-so-fancy
  else
    cat -
  fi
}

gf_inspect_binding() {
  local helper="$1"
  local arg
  shift

  printf '%s:execute(git fuzzy helper %s' "$(lowercase "$GIT_FUZZY_INSPECT_KEY")" "$helper"
  for arg in "$@"; do
    [ -n "$arg" ] && printf ' %s' "$arg"
  done
  printf ')'
}

gf_helper_inspect_pager() {
  less -R -K -+F
}

gf_helper_inspect_diff_renderer() {
  PAGER=cat DELTA_PAGER=cat BAT_PAGER=cat gf_diff_renderer
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
    --bind \"$(lowercase "$GIT_FUZZY_PREVIEW_WRAP_KEY"):toggle-preview-wrap\" \
    --bind \"$(lowercase "$GIT_FUZZY_PREVIEW_SIZE_INCREASE_KEY"):transform(git fuzzy helper preview_resize increase)\" \
    --bind \"$(lowercase "$GIT_FUZZY_PREVIEW_SIZE_DECREASE_KEY"):transform(git fuzzy helper preview_resize decrease)\" \
    $(quote_params "$@")"

  if [ -n "$GF_COMMAND_FZF_DEBUG_MODE" ]; then
    gf_log_command_string "$gf_command"
  fi

  eval "$gf_command"
}

gf_fzf_one() {
  local gf_command="fzf +m --ansi --no-sort --no-info \
            $(preview_window_settings) \
            --bind \"$(lowercase "$GIT_FUZZY_PREVIEW_WRAP_KEY"):toggle-preview-wrap\" \
            --bind \"$(lowercase "$GIT_FUZZY_PREVIEW_SIZE_INCREASE_KEY"):transform(git fuzzy helper preview_resize increase)\" \
            --bind \"$(lowercase "$GIT_FUZZY_PREVIEW_SIZE_DECREASE_KEY"):transform(git fuzzy helper preview_resize decrease)\" \
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
  git -c color.ui=always "$@"
}

gf_git_command_with_header() {
  NUM="$1"
  shift
  printf "%s" "$GRAY" "$BOLD" '$ ' "$CYAN" "$BOLD" "git $(quote_params "$@")" "$NORMAL"
  # shellcheck disable=2034
  for i in $(seq 1 "$NUM"); do
    echo
  done
  git -c color.ui=always "$@"
}

gf_git_command_with_header_default_parameters() {
  NUM="$1"
  shift
  DEFAULT_SUBCOMMAND_PARAMETERS="$1"
  shift
  SUB_COMMAND="$1"
  shift
  printf "%s" "$GRAY" "$BOLD" '$ ' "$CYAN" "$BOLD" "git $SUB_COMMAND $(quote_params "$@")" "$NORMAL"
  # shellcheck disable=2034
  for i in $(seq 0 "$NUM"); do
    [ "$i" -gt 0 ] && echo
  done
  gf_log_command_string "git -c color.ui=always '$SUB_COMMAND' $DEFAULT_SUBCOMMAND_PARAMETERS $(quote_params "$@")"
  eval "git -c color.ui=always '$SUB_COMMAND' $DEFAULT_SUBCOMMAND_PARAMETERS $(quote_params "$@")"
}

gf_quit() {
  gf_log_debug "exiting"
  exit 0
}
