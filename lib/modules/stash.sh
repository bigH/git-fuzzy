#!/usr/bin/env bash

GIT_FUZZY_DROP_KEY="${GIT_FUZZY_DROP_KEY:-Alt-D}"

# shellcheck disable=2016
GF_STASH_HEADER='
'"${WHITE}Enter${NORMAL} to ${GREEN}QUIT${NORMAL}"'

    '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}drop${NORMAL}  ${WHITE}$GIT_FUZZY_DROP_KEY${NORMAL}     ${GRAY}-- drop the selected stash${NORMAL}"'

'

gf_fzf_stash() {
  gf_fzf_one -m \
    --header-lines=2 \
    --header "$GF_STASH_HEADER" \
    --preview 'git fuzzy helper stash_preview_content {1}' \
    --bind "$GIT_FUZZY_DROP_KEY:execute(git fuzzy helper stash_drop {1})+reload(git fuzzy helper stash_menu_content)"
}

gf_stash() {
  # NB: first parameter is the "query", which is empty right now
  git fuzzy helper stash_menu_content "$@" | gf_fzf_stash
}
