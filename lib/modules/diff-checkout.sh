#!/usr/bin/env bash

# shellcheck disable=2016
GF_DIFF_CHECKOUT_HEADER='
  Query above is with these args '"'${MAGENTA}${GF_DIFF_SEARCH_DEFAULTS} query${NORMAL}'"'
  Press '"${WHITE}Enter${NORMAL}"' to checkout selected file(s)

  '"${GRAY}-- (files will not disappear) --${NORMAL}"'

'

gf_fzf_diff_checkout() {
  # shellcheck disable=2016
  RELOAD_COMMAND="git fuzzy helper diff_direct_menu_content {q} '$1' '$2'"
  PREVIEW_COMMAND="git fuzzy helper diff_direct_preview_content {q} {} '$1'"

  gf_fzf -m --phony \
    --header-lines=2 \
    --header "$GF_DIFF_CHECKOUT_HEADER" \
    --preview "$PREVIEW_COMMAND" \
    --bind "change:reload($RELOAD_COMMAND)" \
    --bind "enter:execute-silent(git fuzzy helper diff_checkout_file '$1' {+})+down"
}

gf_diff_checkout() {
  gf_snapshot "diff-checkout"
  MERGE_BASE="$(gf_merge_base "$1")"
  git fuzzy helper diff_direct_menu_content '' "$1" "$MERGE_BASE" | gf_fzf_diff_checkout "$1" "$MERGE_BASE"
}
