#!/usr/bin/env bash

# shellcheck disable=2016
GF_DIFF_HEADER='
Type to filter. '"${WHITE}Enter${NORMAL} to ${GREEN}ACCEPT${NORMAL}."'

  '"${GREEN}mark${NORMAL}  ${WHITE}Tab${NORMAL}"'

'

GF_DIFF_PREVIEW='
  [ {1} != "nothing" ] &&
    git fuzzy helper diff_preview_content {2} ||
    echo "nothing to show"
'

gf_fzf_diff_select() {
  gf_fzf -m 2 \
    --with-nth=2.. \
    --header "$GF_DIFF_HEADER" \
    --preview "$GF_DIFF_PREVIEW" \
    --bind 'enter:execute([ {1} != "nothing" ] && git fuzzy helper diff_select {+2})'
}

gf_diff() {
  if [ $# -gt 0 ]; then
    gf_diff_direct "$@"
  else
    git fuzzy helper diff_menu_content | gf_fzf_diff_select
  fi
}
