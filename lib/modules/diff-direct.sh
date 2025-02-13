#!/usr/bin/env bash

# shellcheck disable=2016
GF_DIFF_DIRECT_HEADER='
  Query above is with these args '"'${MAGENTA}${GF_DIFF_SEARCH_DEFAULTS} query${NORMAL}'"'

'

if [ "$(particularly_small_screen)" = '1' ]; then
  GF_DIFF_DIRECT_HEADER=''
fi

gf_fzf_diff_direct() {
  PARAMETERS_QUOTED="$(quote_params "$@")"

  # shellcheck disable=2016
  RELOAD_COMMAND="git fuzzy helper diff_direct_menu_content {q} $PARAMETERS_QUOTED"
  PREVIEW_COMMAND="git fuzzy helper diff_direct_preview_content {q} {} $PARAMETERS_QUOTED"

  gf_fzf -m --phony \
    --header-lines=2 \
    --header "$GF_DIFF_DIRECT_HEADER" \
    --preview "$PREVIEW_COMMAND" \
    --bind "click-header:reload(git fuzzy helper diff_direct_menu_content {q} $PARAMETERS_QUOTED)" \
    --bind "backward-eof:reload(git fuzzy helper diff_direct_menu_content {q} $PARAMETERS_QUOTED)" \
    --bind "change:reload($RELOAD_COMMAND)"
}

gf_diff_direct() {
  gf_go_to_git_root_directory
  if ! git diff --quiet "$@"; then
    git fuzzy helper diff_direct_menu_content '' "$@" | gf_fzf_diff_direct "$@"
  else
    gf_log_debug "empty diff"
    exit 1
  fi
}
