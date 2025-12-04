#!/usr/bin/env bash

GIT_FUZZY_REFLOG_WORKING_COPY_KEY="${GIT_FUZZY_REFLOG_WORKING_COPY_KEY:-Ctrl-P}"
GIT_FUZZY_REFLOG_MERGE_BASE_KEY="${GIT_FUZZY_REFLOG_MERGE_BASE_KEY:-Alt-P}"
GIT_FUZZY_REFLOG_COMMIT_KEY="${GIT_FUZZY_REFLOG_COMMIT_KEY:-Alt-D}"

# shellcheck disable=2016
GF_REFLOG_HEADER='
Use '"${YELLOW}|${NORMAL} to separate CLI args for ${MAGENTA}git reflog${NORMAL} vs ${MAGENTA}git diff${NORMAL}. ${WHITE}Enter${NORMAL} to ${GREEN}ACCEPT${NORMAL}"'
Select an entry with '"${WHITE}<Tab>${NORMAL}"' to use as basis for comparison in the preview.

  '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}working copy${NORMAL}  ${WHITE}$GIT_FUZZY_REFLOG_WORKING_COPY_KEY${NORMAL}    ${GRAY}-- search messages${NORMAL}  ${MAGENTA}--grep=Foo${NORMAL}"'
    '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}merge-base${NORMAL}  ${WHITE}$GIT_FUZZY_REFLOG_MERGE_BASE_KEY${NORMAL}        ${GRAY}-- search patch${NORMAL}  ${MAGENTA}-G 'Foo'${NORMAL}"'
        '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}commit${NORMAL}  ${WHITE}$GIT_FUZZY_REFLOG_COMMIT_KEY${NORMAL}     ${GRAY}-- customize patch${NORMAL}  ${MAGENTA}-G 'Foo' | -W -- foo.c${NORMAL}"'

'

if [ "$(particularly_small_screen)" = '1' ]; then
  GF_REFLOG_HEADER=''
fi

gf_fzf_reflog() {
  PARAMS_FOR_SUBSTITUTION=''
  if [ "$#" -gt 0 ]; then
    PARAMS_FOR_SUBSTITUTION="$(quote_params "$@")"
  fi

  # shellcheck disable=2016
  gf_fzf_one -m \
    --phony \
    --header-lines=2 \
    --header "$GF_REFLOG_HEADER" \
    --preview 'git fuzzy helper reflog_preview_content {1} {q} {+..}' \
    --bind "change:reload(git fuzzy helper reflog_menu_content {q} $PARAMS_FOR_SUBSTITUTION)" \
    --bind "click-header:reload(git fuzzy helper reflog_menu_content {q} $PARAMS_FOR_SUBSTITUTION)" \
    --bind "backward-eof:reload(git fuzzy helper reflog_menu_content {q} $PARAMS_FOR_SUBSTITUTION)" \
    --bind "$(lowercase "$GIT_FUZZY_REFLOG_COMMIT_KEY"):execute(git fuzzy diff {1}^ {1})" \
    --bind "$(lowercase "$GIT_FUZZY_REFLOG_WORKING_COPY_KEY"):execute(git fuzzy diff {1})" \
    --bind "$(lowercase "$GIT_FUZZY_REFLOG_MERGE_BASE_KEY"):"'execute(git fuzzy diff "$(git merge-base "'"$GF_BASE_BRANCH"'" {1})" {1})'
}

gf_reflog() {
  # NB: first parameter is the "query", which is empty right now
  git fuzzy helper reflog_menu_content '' "$@" | gf_fzf_reflog "$@" | gf_fzf_log_line_interpreter
}
