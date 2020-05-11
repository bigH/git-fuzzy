#!/usr/bin/env bash

# shellcheck disable=2016
GF_LOG_HEADER='
Use '"${YELLOW}|${NORMAL} to separate CLI args for ${MAGENTA}git log${NORMAL} vs ${MAGENTA}git diff${NORMAL}. ${WHITE}Enter${NORMAL} to ${GREEN}ACCEPT${NORMAL}"'

  '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}working copy${NORMAL}  ${WHITE}Ctrl-P${NORMAL}    ${GRAY}-- search messages${NORMAL}  ${MAGENTA}--grep=Foo${NORMAL}"'
    '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}merge-base${NORMAL}  ${WHITE}Alt-P${NORMAL}        ${GRAY}-- search patch${NORMAL}  ${MAGENTA}-G 'Foo'${NORMAL}"'
        '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}commit${NORMAL}  ${WHITE}Alt-D${NORMAL}     ${GRAY}-- customize patch${NORMAL}  ${MAGENTA}-G 'Foo' | -W -- foo.c${NORMAL}"'

'

gf_fzf_log() {
  # shellcheck disable=2016
  gf_fzf_one -m \
    --phony \
    --header-lines=2 \
    --header "$GF_LOG_HEADER" \
    --preview 'git fuzzy helper log_preview_content {1} {q}' \
    --bind 'change:reload(git fuzzy helper log_menu_content {q})' \
    --bind 'alt-d:execute(git fuzzy diff {1}^ {1})' \
    --bind 'ctrl-p:execute(git fuzzy diff {1})' \
    --bind 'alt-p:execute(git fuzzy diff "$(git merge-base "'"$GF_BASE_BRANCH"'" {1})" {1})'
}

gf_log() {
  # NB: first parameter is the "query", which is empty right now
  git fuzzy helper log_menu_content '' "$@" | gf_fzf_log | gf_fzf_log_line_interpreter
}
