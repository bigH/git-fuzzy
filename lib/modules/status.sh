#!/usr/bin/env bash
# shellcheck disable=2016

GF_STATUS_HEADER='
Type to filter. '"${WHITE}Enter${NORMAL} to ${GREEN}ACCEPT${NORMAL}"'

  '"${GRAY}-- (${NORMAL}*${GRAY}) editor: ${MAGENTA}${EDITOR} ${NORMAL}${GF_EDITOR_ARGS}${NORMAL}"'
  '"                                      * ${GREEN}${BOLD}edit ✎${NORMAL}  ${WHITE}Alt-E${NORMAL}"'
   '"${GREEN}all ☑${NORMAL}  ${WHITE}Alt-A${NORMAL}     ${GREEN}stage ${BOLD}⇡${NORMAL}  ${WHITE}Alt-S${NORMAL}     ${RED}${BOLD}discard ✗${NORMAL}  ${WHITE}Alt-U${NORMAL}"'
  '"${GREEN}none ☐${NORMAL}  ${WHITE}Alt-D${NORMAL}     ${GREEN}reset ${RED}${BOLD}⇣${NORMAL}  ${WHITE}Alt-R${NORMAL}    * ${RED}${BOLD}commit ${NORMAL}${RED}⇧${NORMAL}  ${WHITE}Alt-C${NORMAL}"'

'
gf_fzf_status() {
  RELOAD="reload:git fuzzy helper status_menu_content"
  # doesn't work

  gf_fzf -m --header "$GF_STATUS_HEADER" \
            --header-lines=2 \
            --expect='alt-e,alt-c' \
            --nth=2 \
            --preview 'git fuzzy helper status_preview_content {1} {2..}' \
            --bind "alt-s:execute-silent(git fuzzy helper status_add {+2..})+down+$RELOAD" \
            --bind "alt-r:execute-silent(git fuzzy helper status_reset {+2..})+down+$RELOAD" \
            --bind "alt-u:execute-silent(git fuzzy helper status_discard {2..})+$RELOAD"
}

gf_status_interpreter() {
  CONTENT="$(cat -)"
  HEAD="$(echo "$CONTENT" | head -n1)"
  TAIL="$(echo "$CONTENT" | tail -n +2)"
  if [ "$HEAD" = 'alt-e' ]; then
    eval "git fuzzy helper status_edit $(echo "$TAIL" | cut -c4- | join_lines_quoted)"
  elif [ "$HEAD" = 'alt-c' ]; then
    eval "git fuzzy helper status_commit"
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
