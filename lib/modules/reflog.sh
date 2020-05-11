#!/usr/bin/env bash

# shellcheck disable=2016
GF_REFLOG_HEADER='
Use '"${YELLOW}|${NORMAL} to separate CLI args for ${MAGENTA}git reflog${NORMAL} vs ${MAGENTA}git diff${NORMAL}. ${WHITE}Enter${NORMAL} to ${GREEN}ACCEPT${NORMAL}"'

  '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}working copy${NORMAL}  ${WHITE}Ctrl-P${NORMAL}    ${GRAY}-- search messages${NORMAL}  ${MAGENTA}--grep=Foo${NORMAL}"'
    '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}merge-base${NORMAL}  ${WHITE}Alt-P${NORMAL}        ${GRAY}-- search patch${NORMAL}  ${MAGENTA}-G 'Foo'${NORMAL}"'
        '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}commit${NORMAL}  ${WHITE}Alt-C${NORMAL}     ${GRAY}-- customize patch${NORMAL}  ${MAGENTA}-G 'Foo' | -W -- foo.c${NORMAL}"'

'

gf_fzf_reflog() {
  # shellcheck disable=2016
  gf_fzf_one -m \
    --phony \
    --header-lines=2 \
    --header "$GF_REFLOG_HEADER" \
    --preview 'git fuzzy helper reflog_preview_content {1} {q}' \
    --bind 'change:reload(git fuzzy helper reflog_menu_content {q})' \
    --bind 'alt-d:execute(git fuzzy diff {1}^ {1})' \
    --bind 'ctrl-p:execute(git fuzzy diff {1})' \
    --bind 'alt-p:execute(git fuzzy diff "$(git merge-base "'"$GF_BASE_BRANCH"'" {1})" {1})'
}

gf_reflog() {
  git fuzzy helper reflog_menu_content "$@" | gf_fzf_reflog | gf_fzf_log_line_interpreter
}
