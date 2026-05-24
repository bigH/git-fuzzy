#!/usr/bin/env bash

GIT_FUZZY_LOG_WORKING_COPY_KEY="${GIT_FUZZY_LOG_WORKING_COPY_KEY:-Ctrl-P}"
GIT_FUZZY_MERGE_BASE_KEY="${GIT_FUZZY_MERGE_BASE_KEY:-Alt-P}"
GIT_FUZZY_LOG_COMMIT_KEY="${GIT_FUZZY_LOG_COMMIT_KEY:-Alt-D}"
GF_LOG_RELOAD_DEBOUNCE="${GF_LOG_RELOAD_DEBOUNCE:-0.15}"

# shellcheck disable=2016
GF_LOG_HEADER='
'"${YELLOW}|${NORMAL} split args: ${MAGENTA}git log${NORMAL} query | ${MAGENTA}git show/diff${NORMAL} patch args      ${WHITE}Enter${NORMAL} to ${GREEN}PRINT SHA(s)${NORMAL}"'
'"${YELLOW}*${NORMAL} send full query to ${MAGENTA}git log${NORMAL}                               ${WHITE}<Tab>${NORMAL} to ${GREEN}SELECT SHA${NORMAL} for ${MAGENTA}show/diff${NORMAL}"'
'"${YELLOW}#${NORMAL} send full query to ${MAGENTA}git show/diff${NORMAL}                         ${GRAY}(cannot select >1 SHA)${NORMAL}"'

  '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}working copy${NORMAL}        ${WHITE}$GIT_FUZZY_LOG_WORKING_COPY_KEY${NORMAL}  ${GRAY}-- diff from commit to worktree${NORMAL}  ${MAGENTA}-G 'Foo'${NORMAL}"'
  '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}merge-base${NORMAL}          ${WHITE}$GIT_FUZZY_MERGE_BASE_KEY${NORMAL}   ${GRAY}-- diff merge-base to commit${NORMAL}   ${MAGENTA}-G 'Foo'${NORMAL}"'
  '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}single-commit show${NORMAL}  ${WHITE}$GIT_FUZZY_LOG_COMMIT_KEY${NORMAL}   ${GRAY}-- show commit patch${NORMAL}          ${MAGENTA}-G 'Foo' | -W -- foo.c${NORMAL}"'

'

if [ "$(particularly_small_screen)" = '1' ]; then
  GF_LOG_HEADER=''
fi

gf_fzf_log() {
  PARAMS_FOR_SUBSTITUTION=''
  if [ "$#" -gt 0 ]; then
    PARAMS_FOR_SUBSTITUTION="$(quote_params "$@")"
  fi
  LOG_RELOAD_DEBOUNCE="$(quote_params "$GF_LOG_RELOAD_DEBOUNCE")"

  # shellcheck disable=2016
  gf_fzf_one -m \
    --phony \
    --listen \
    --track \
    --id-nth=1 \
    --header-lines=2 \
    --header "$GF_LOG_HEADER" \
    --preview 'git fuzzy helper log_preview_content {..} {q} {+..}' \
    --bind "click-header:track-current+reload-sync(git fuzzy helper log_menu_content {q} $PARAMS_FOR_SUBSTITUTION)" \
    --bind "backward-eof:track-current+reload-sync(git fuzzy helper log_menu_content {q} $PARAMS_FOR_SUBSTITUTION)" \
    --bind "change:execute-silent(git fuzzy helper log_debounced_reload \$FZF_PORT $LOG_RELOAD_DEBOUNCE {q} $PARAMS_FOR_SUBSTITUTION >/dev/null 2>&1 &)" \
    --bind "$(lowercase "$GIT_FUZZY_LOG_COMMIT_KEY"):execute(git fuzzy helper log_open_diff commit {..})" \
    --bind "$(lowercase "$GIT_FUZZY_LOG_WORKING_COPY_KEY"):execute(git fuzzy helper log_open_diff working_copy {..})" \
    --bind "$(lowercase "$GIT_FUZZY_MERGE_BASE_KEY")"':execute(git fuzzy helper log_open_diff merge_base {..})' \
    --bind "$(gf_inspect_binding log_inspect '{..}' '{q}' '{+..}')"
}

gf_log() {
  # NB: first parameter is the "query", which is empty right now
  git fuzzy helper log_menu_content '' "$@" | gf_fzf_log "$@" | gf_fzf_log_line_interpreter
}
