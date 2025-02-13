#!/usr/bin/env bash

GIT_FUZZY_LOG_WORKING_COPY_KEY="${GIT_FUZZY_LOG_WORKING_COPY_KEY:-Ctrl-P}"
GIT_FUZZY_MERGE_BASE_KEY="${GIT_FUZZY_MERGE_BASE_KEY:-Alt-P}"
GIT_FUZZY_LOG_COMMIT_KEY="${GIT_FUZZY_LOG_COMMIT_KEY:-Alt-D}"

# shellcheck disable=2016
GF_LOG_HEADER='
'"${YELLOW}|${NORMAL} to split CLI args for ${MAGENTA}git log${NORMAL} vs ${MAGENTA}git diff${NORMAL}         ${WHITE}Enter${NORMAL} to ${GREEN}PRINT SHA(s)${NORMAL}"'
'"${YELLOW}*${NORMAL} as prefix to send all content to ${MAGENTA}git log${NORMAL}          ${WHITE}<Tab>${NORMAL} to ${GREEN}SELECT SHA${NORMAL} for ${MAGENTA}diff${NORMAL}"'
'"${YELLOW}#${NORMAL} as prefix to send all content to ${MAGENTA}git diff${NORMAL}               ${GRAY}(cannot select >1 SHA)${NORMAL}"'

  '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}working copy${NORMAL}  ${WHITE}$GIT_FUZZY_LOG_WORKING_COPY_KEY${NORMAL}    ${GRAY}-- search messages${NORMAL}  ${MAGENTA}--grep=Foo${NORMAL}"'
    '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}merge-base${NORMAL}  ${WHITE}$GIT_FUZZY_MERGE_BASE_KEY${NORMAL}        ${GRAY}-- search patch${NORMAL}  ${MAGENTA}-G 'Foo'${NORMAL}"'
        '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}commit${NORMAL}  ${WHITE}$GIT_FUZZY_LOG_COMMIT_KEY${NORMAL}     ${GRAY}-- customize patch${NORMAL}  ${MAGENTA}-G 'Foo' | -W -- foo.c${NORMAL}"'

'

if [ "$(particularly_small_screen)" = '1' ]; then
  GF_LOG_HEADER=''
fi

gf_fzf_log() {
  PARAMS_FOR_SUBSTITUTION=''
  if [ "$#" -gt 0 ]; then
    PARAMS_FOR_SUBSTITUTION="$(quote_params "$@")"
  fi

  # shellcheck disable=2016
  gf_fzf_one -m \
    --phony \
    --header-lines=2 \
    --header "$GF_LOG_HEADER" \
    --preview 'git fuzzy helper log_preview_content {..} {q} {+..}' \
    --bind "click-header:reload(git fuzzy helper log_menu_content {q} $PARAMS_FOR_SUBSTITUTION)" \
    --bind "backward-eof:reload(git fuzzy helper log_menu_content {q} $PARAMS_FOR_SUBSTITUTION)" \
    --bind "change:reload(git fuzzy helper log_menu_content {q} $PARAMS_FOR_SUBSTITUTION)" \
    --bind "$(lowercase "$GIT_FUZZY_LOG_COMMIT_KEY"):execute(git fuzzy helper log_open_diff commit {..})" \
    --bind "$(lowercase "$GIT_FUZZY_LOG_WORKING_COPY_KEY"):execute(git fuzzy helper log_open_diff working_copy {..})" \
    --bind "$(lowercase "$GIT_FUZZY_MERGE_BASE_KEY")"':execute(git fuzzy helper log_open_diff merge_base {..})'
}

gf_log() {
  # NB: first parameter is the "query", which is empty right now
  git fuzzy helper log_menu_content '' "$@" | gf_fzf_log "$@" | gf_fzf_log_line_interpreter
}
