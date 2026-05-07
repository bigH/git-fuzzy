#!/usr/bin/env bash

GIT_FUZZY_DROP_KEY="${GIT_FUZZY_DROP_KEY:-Alt-D}"
GIT_FUZZY_POP_KEY="${GIT_FUZZY_POP_KEY:-Alt-P}"
GIT_FUZZY_APPLY_KEY="${GIT_FUZZY_APPLY_KEY:-Alt-A}"

# shellcheck disable=2016
GF_STASH_HEADER='
'"${WHITE}Enter${NORMAL} to ${GREEN}QUIT${NORMAL}"'

    '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}drop${NORMAL}   ${WHITE}$GIT_FUZZY_DROP_KEY${NORMAL}     ${GRAY}-- drop the selected stash${NORMAL}"'
    '"${YELLOW}${BOLD}⇧${NORMAL} ${GREEN}pop ${NORMAL}   ${WHITE}$GIT_FUZZY_POP_KEY${NORMAL}     ${GRAY}-- pops the selected stash${NORMAL}"'
    '"${GREEN}${BOLD}⇧${NORMAL} ${GREEN}apply${NORMAL}  ${WHITE}$GIT_FUZZY_APPLY_KEY${NORMAL}     ${GRAY}-- applies the selected stash${NORMAL}"'

'

if [ "$(particularly_small_screen)" = '1' ]; then
  GF_STASH_HEADER=''
fi

gf_fzf_stash() {
  gf_fzf_one -m \
    --track \
    --id-nth=1 \
    --with-nth=2.. \
    --accept-nth=2.. \
    --header-lines=2 \
    --header "$GF_STASH_HEADER" \
    --preview 'git fuzzy helper stash_preview_content {2}' \
    --bind 'click-header:reload-sync(git fuzzy helper stash_menu_content '"$(quote_params "$@")"')' \
    --bind 'backward-eof:reload-sync(git fuzzy helper stash_menu_content '"$(quote_params "$@")"')' \
    --bind "$(lowercase "$GIT_FUZZY_DROP_KEY"):execute(git fuzzy helper stash_drop {2})+reload-sync(git fuzzy helper stash_menu_content)+clear-multi" \
    --bind "$(lowercase "$GIT_FUZZY_POP_KEY"):execute(git fuzzy helper stash_pop {2})+reload-sync(git fuzzy helper stash_menu_content)+clear-multi" \
    --bind "$(lowercase "$GIT_FUZZY_APPLY_KEY"):execute(git fuzzy helper stash_apply {2})+reload-sync(git fuzzy helper stash_menu_content)+clear-multi" \
    --bind "$(gf_inspect_binding stash_inspect '{2}')"
}

gf_stash() {
  # NB: first parameter is the "query", which is empty right now
  git fuzzy helper stash_menu_content "$@" | gf_fzf_stash "$@"
}
