#!/usr/bin/env bash

# shellcheck disable=2016
GF_SHOW_HEADER='
  Query above is with these args '"'${MAGENTA}${GF_DIFF_SEARCH_DEFAULTS} query${NORMAL}'"'

'

if [ "$(particularly_small_screen)" = '1' ]; then
  GF_SHOW_HEADER=''
fi

gf_fzf_show() {
  PARAMETERS_QUOTED="$(quote_params "$@")"
  RELOAD_DEBOUNCE="$(quote_params "$GF_RELOAD_DEBOUNCE")"

  # shellcheck disable=2016
  PREVIEW_COMMAND="git fuzzy helper show_preview_content {q} {} $PARAMETERS_QUOTED"

  gf_fzf -m --phony \
    --listen \
    --track \
    --id-nth=2.. \
    --with-nth=2.. \
    --header-lines=2 \
    --header "$GF_SHOW_HEADER" \
    --preview "$PREVIEW_COMMAND" \
    --bind "click-header:track-current+reload-sync(git fuzzy helper show_menu_content {q} $PARAMETERS_QUOTED)" \
    --bind "backward-eof:track-current+reload-sync(git fuzzy helper show_menu_content {q} $PARAMETERS_QUOTED)" \
    --bind "$(gf_inspect_binding show_inspect '{q}' '{}' "$PARAMETERS_QUOTED")" \
    --bind "change:execute-silent(git fuzzy helper debounced_reload \$FZF_PORT $RELOAD_DEBOUNCE track-current+reload-sync show_menu_content {q} $PARAMETERS_QUOTED >/dev/null 2>&1 &)"
}

gf_show() {
  gf_go_to_git_root_directory
  gf_show_parse_args "$@" || return

  git fuzzy helper show_menu_content '' "$@" | gf_fzf_show "$@"
}
