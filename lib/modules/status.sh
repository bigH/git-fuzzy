#!/usr/bin/env bash
# shellcheck disable=2016

GIT_FUZZY_STATUS_AMEND_KEY="${GIT_FUZZY_STATUS_AMEND_KEY:-Alt-M}"
GIT_FUZZY_STATUS_ADD_KEY="${GIT_FUZZY_STATUS_ADD_KEY:-Alt-S}"
GIT_FUZZY_STATUS_ADD_PATCH_KEY="${GIT_FUZZY_STATUS_ADD_PATCH_KEY:-Alt-P}"
GIT_FUZZY_STATUS_EDIT_KEY="${GIT_FUZZY_STATUS_EDIT_KEY:-Alt-E}"
GIT_FUZZY_STATUS_COMMIT_KEY="${GIT_FUZZY_STATUS_COMMIT_KEY:-Alt-C}"
GIT_FUZZY_STATUS_RESET_KEY="${GIT_FUZZY_STATUS_RESET_KEY:-Alt-R}"
GIT_FUZZY_STATUS_DISCARD_KEY="${GIT_FUZZY_STATUS_DISCARD_KEY:-Alt-U}"

GF_STATUS_HEADER='
Type to filter. '"${WHITE}Enter${NORMAL} to ${GREEN}ACCEPT${NORMAL}"'

  '"${GRAY}-- (${NORMAL}*${GRAY}) editor: ${MAGENTA}${EDITOR} ${NORMAL}${GF_EDITOR_ARGS}${NORMAL}"'
  '""'
 '"${GREEN}amend ✁${NORMAL}  ${WHITE}${GIT_FUZZY_STATUS_AMEND_KEY}${NORMAL}  ${GREEN}stage -p ${BOLD}⇡  ${NORMAL}${WHITE}${GIT_FUZZY_STATUS_ADD_PATCH_KEY}${NORMAL}      * ${GREEN}${BOLD}edit ✎${NORMAL}  ${WHITE}$GIT_FUZZY_STATUS_EDIT_KEY${NORMAL}"'
   '"${GREEN}all ☑${NORMAL}  ${WHITE}${GIT_FUZZY_SELECT_ALL_KEY}${NORMAL}     ${GREEN}stage ${BOLD}⇡${NORMAL}  ${WHITE}$GIT_FUZZY_STATUS_ADD_KEY${NORMAL}     ${RED}${BOLD}discard ✗${NORMAL}  ${WHITE}$GIT_FUZZY_STATUS_DISCARD_KEY${NORMAL}"'
  '"${GREEN}none ☐${NORMAL}  ${WHITE}${GIT_FUZZY_SELECT_NONE_KEY}${NORMAL}     ${GREEN}reset ${RED}${BOLD}⇣${NORMAL}  ${WHITE}$GIT_FUZZY_STATUS_RESET_KEY${NORMAL}    * ${RED}${BOLD}commit ${NORMAL}${RED}⇧${NORMAL}  ${WHITE}$GIT_FUZZY_STATUS_COMMIT_KEY${NORMAL}"'

'

if [ "$(particularly_small_screen)" = '1' ]; then
  GF_STATUS_HEADER=''
fi

gf_fzf_status() {
  RELOAD="reload:git fuzzy helper status_menu_content"

  gf_fzf -m --header "$GF_STATUS_HEADER" \
            --header-lines=2 \
            --expect="$(lowercase "$GIT_FUZZY_STATUS_EDIT_KEY"),$(lowercase "$GIT_FUZZY_STATUS_COMMIT_KEY"),$(lowercase "$GIT_FUZZY_STATUS_ADD_PATCH_KEY")" \
            --nth=2 \
            --preview 'git fuzzy helper status_preview_content {1} {2} {4}' \
            --bind 'click-header:reload(git fuzzy helper status_menu_content)' \
            --bind 'backward-eof:reload(git fuzzy helper status_menu_content)' \
            --bind "$(lowercase "$GIT_FUZZY_STATUS_AMEND_KEY"):execute-silent(git fuzzy helper status_amend {+2..})+down+$RELOAD" \
            --bind "$(lowercase "$GIT_FUZZY_STATUS_ADD_KEY"):execute-silent(git fuzzy helper status_add {+2..})+down+$RELOAD" \
            --bind "$(lowercase "$GIT_FUZZY_STATUS_RESET_KEY"):execute-silent(git fuzzy helper status_reset {+2..})+down+$RELOAD" \
            --bind "$(lowercase "$GIT_FUZZY_STATUS_DISCARD_KEY"):execute-silent(git fuzzy helper status_discard {+2..})+$RELOAD"
}

gf_status_interpreter() {
  CONTENT="$(cat -)"
  HEAD="$(echo "$CONTENT" | head -n1)"
  TAIL="$(echo "$CONTENT" | tail -n +2)"

  if [ "$(lowercase "$HEAD")" = "$(lowercase "$GIT_FUZZY_STATUS_EDIT_KEY")" ]; then
    local selected_file=$(echo "$TAIL" | cut -c4- | join_lines_quoted)
    eval "git fuzzy helper status_edit $selected_file"
  elif [ "$(lowercase "$HEAD")" = "$(lowercase "$GIT_FUZZY_STATUS_COMMIT_KEY")" ]; then
    eval "git fuzzy helper status_commit"
  elif [ "$(lowercase "$HEAD")" = "$(lowercase "$GIT_FUZZY_STATUS_ADD_PATCH_KEY")" ]; then
    local selected_file=$(echo "$TAIL" | cut -c4- | join_lines_quoted)
    eval "git fuzzy helper status_add_patch $selected_file"
  else
    echo "$TAIL" | cut -c4-
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
