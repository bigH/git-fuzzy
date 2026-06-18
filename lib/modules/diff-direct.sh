#!/usr/bin/env bash

# shellcheck disable=2016
GF_DIFF_DIRECT_HEADER='
  Query above is with these args '"'${MAGENTA}${GF_DIFF_SEARCH_DEFAULTS} query${NORMAL}'"'

'

gf_fzf_diff_direct() {
  if [ "$(particularly_small_screen)" = '1' ]; then
    GF_DIFF_DIRECT_HEADER=''
  fi

  PARAMETERS_QUOTED="$(quote_params "$@")"
  RELOAD_DEBOUNCE="$(quote_params "$GF_RELOAD_DEBOUNCE")"

  # shellcheck disable=2016
  PREVIEW_COMMAND="git fuzzy helper diff_direct_preview_content {q} {} $PARAMETERS_QUOTED"

  gf_fzf -m --phony \
    --listen \
    --track \
    --id-nth=.. \
    --header-lines=2 \
    --header "$GF_DIFF_DIRECT_HEADER" \
    --preview "$PREVIEW_COMMAND" \
    --bind "click-header:track-current+reload-sync(git fuzzy helper diff_direct_menu_content {q} $PARAMETERS_QUOTED)" \
    --bind "backward-eof:track-current+reload-sync(git fuzzy helper diff_direct_menu_content {q} $PARAMETERS_QUOTED)" \
    --bind "$(gf_inspect_binding diff_direct_inspect '{q}' '{}' "$PARAMETERS_QUOTED")" \
    --bind "change:execute-silent(git fuzzy helper debounced_reload \$FZF_PORT $RELOAD_DEBOUNCE track-current+reload-sync diff_direct_menu_content {q} $PARAMETERS_QUOTED >/dev/null 2>&1 &)"
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
