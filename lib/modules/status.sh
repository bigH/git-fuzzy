#!/usr/bin/env bash
# shellcheck disable=2016

GIT_FUZZY_STATUS_AMEND_KEY="${GIT_FUZZY_STATUS_AMEND_KEY:-Alt-M}"
GIT_FUZZY_STATUS_ADD_KEY="${GIT_FUZZY_STATUS_ADD_KEY:-Alt-S}"
GIT_FUZZY_STATUS_ADD_PATCH_KEY="${GIT_FUZZY_STATUS_ADD_PATCH_KEY:-Alt-P}"
GIT_FUZZY_STATUS_EDIT_KEY="${GIT_FUZZY_STATUS_EDIT_KEY:-Alt-E}"
GIT_FUZZY_STATUS_COMMIT_KEY="${GIT_FUZZY_STATUS_COMMIT_KEY:-Alt-C}"
GIT_FUZZY_STATUS_RESET_KEY="${GIT_FUZZY_STATUS_RESET_KEY:-Alt-R}"
GIT_FUZZY_STATUS_DISCARD_KEY="${GIT_FUZZY_STATUS_DISCARD_KEY:-Alt-U}"
GIT_FUZZY_STATUS_DIFF_KEY="${GIT_FUZZY_STATUS_DIFF_KEY:-$GIT_FUZZY_INSPECT_KEY}"

GF_STATUS_HEADER='
Type to filter. '"${WHITE}Enter${NORMAL} to ${GREEN}ACCEPT${NORMAL}"'

  '"${GRAY}-- (${NORMAL}*${GRAY}) editor: ${MAGENTA}${EDITOR} ${NORMAL}${GF_EDITOR_ARGS}${NORMAL}"'
  '""'
 '"${GREEN}amend ✁${NORMAL}  ${WHITE}${GIT_FUZZY_STATUS_AMEND_KEY}${NORMAL}  ${GREEN}stage -p ${BOLD}⇡  ${NORMAL}${WHITE}${GIT_FUZZY_STATUS_ADD_PATCH_KEY}${NORMAL}      * ${GREEN}${BOLD}edit ✎${NORMAL}  ${WHITE}$GIT_FUZZY_STATUS_EDIT_KEY${NORMAL}"'
   '"${GREEN}all ☑${NORMAL}  ${WHITE}${GIT_FUZZY_SELECT_ALL_KEY}${NORMAL}     ${GREEN}stage ${BOLD}⇡${NORMAL}  ${WHITE}$GIT_FUZZY_STATUS_ADD_KEY${NORMAL}     ${RED}${BOLD}discard ✗${NORMAL}  ${WHITE}$GIT_FUZZY_STATUS_DISCARD_KEY${NORMAL}"'
  '"${GREEN}none ☐${NORMAL}  ${WHITE}${GIT_FUZZY_SELECT_NONE_KEY}${NORMAL}     ${GREEN}reset ${RED}${BOLD}⇣${NORMAL}  ${WHITE}$GIT_FUZZY_STATUS_RESET_KEY${NORMAL}    * ${RED}${BOLD}commit ${NORMAL}${RED}⇧${NORMAL}  ${WHITE}$GIT_FUZZY_STATUS_COMMIT_KEY${NORMAL}"'

'

gf_fzf_status() {
  if [ "$(particularly_small_screen)" = '1' ]; then
    GF_STATUS_HEADER=''
  fi

  local passive_reload='reload-sync(git fuzzy helper status_menu_content)'
  local reload_sync="reload-sync(git fuzzy helper status_menu_content)"
  local action_reload="$reload_sync+clear-multi"

  gf_fzf --multi --header "$GF_STATUS_HEADER" \
            --listen \
            --track \
            --id-nth=2.. \
            --header-lines=2 \
            --expect="$(lowercase "$GIT_FUZZY_STATUS_EDIT_KEY"),$(lowercase "$GIT_FUZZY_STATUS_COMMIT_KEY"),$(lowercase "$GIT_FUZZY_STATUS_ADD_PATCH_KEY")" \
            --nth=2 \
            --preview 'git fuzzy helper status_preview_content {1} {2} {4}' \
            --bind 'start:execute-silent(git fuzzy helper status_watch $FZF_PORT > /dev/null 2>&1 &)' \
            --bind "click-header:$passive_reload" \
            --bind "backward-eof:$passive_reload" \
            --bind "$(gf_inspect_binding status_diff '{1}' '{2}' '{4}')" \
            --bind "$(lowercase "$GIT_FUZZY_STATUS_AMEND_KEY"):execute-silent(git fuzzy helper status_amend {+2..})+$action_reload+down" \
            --bind "$(lowercase "$GIT_FUZZY_STATUS_ADD_KEY"):execute-silent(git fuzzy helper status_add {+2..})+$action_reload+down" \
            --bind "$(lowercase "$GIT_FUZZY_STATUS_RESET_KEY"):execute-silent(git fuzzy helper status_reset {+2..})+$action_reload+down" \
            --bind "$(lowercase "$GIT_FUZZY_STATUS_DISCARD_KEY"):execute-silent(git fuzzy helper status_discard {+2..})+$action_reload"
}

gf_status_interpreter() {
  CONTENT="$(cat -)"
  HEAD="$(echo "$CONTENT" | head -n1)"
  TAIL="$(echo "$CONTENT" | tail -n +2)"

  if [ "$(lowercase "$HEAD")" = "$(lowercase "$GIT_FUZZY_STATUS_EDIT_KEY")" ]; then
    local selected_file
    selected_file=$(echo "$TAIL" | cut -c4- | sed 's/.* -> //' | join_lines_quoted)
    eval "git fuzzy helper status_edit $selected_file"
  elif [ "$(lowercase "$HEAD")" = "$(lowercase "$GIT_FUZZY_STATUS_COMMIT_KEY")" ]; then
    eval "git fuzzy helper status_commit"
  elif [ "$(lowercase "$HEAD")" = "$(lowercase "$GIT_FUZZY_STATUS_ADD_PATCH_KEY")" ]; then
    local selected_file
    selected_file=$(echo "$TAIL" | cut -c4- | sed 's/.* -> //' | join_lines_quoted)
    eval "git fuzzy helper status_add_patch $selected_file"
  else
    echo "$TAIL" | cut -c4- | sed 's/.* -> //'
  fi
}

gf_status() {
  gf_snapshot "status"
  if [ -n "$(git status -s)" ]; then
    # shellcheck disable=2086
    git fuzzy helper status_menu_content | gf_fzf_status | gf_status_interpreter
  else
    gf_log_debug "nothing to commit, working tree clean"
    exit 1
  fi
}
