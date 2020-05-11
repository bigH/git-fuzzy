#!/usr/bin/env bash

# shellcheck disable=2016
GF_PR_HEADER='
   '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}diff${NORMAL}  ${WHITE}Enter${NORMAL}"'
   '"${BOLD}🌐${NORMAL} ${GREEN}web${NORMAL}  ${WHITE}Alt-O${NORMAL}"'
   '"   ${GREEN}log${NORMAL}  ${WHITE}Alt-L${NORMAL}"'

'

gf_fzf_pr_select() {
  gf_fzf -m 2 \
    --header="$GF_PR_HEADER" \
    --header-lines 2 \
    --preview 'git fuzzy helper pr_preview_content {1}' \
    --bind 'alt-o:execute(git fuzzy helper pr_show {1})' \
    --bind 'alt-l:execute(git fuzzy helper pr_log {1})' \
    --bind 'enter:execute(git fuzzy helper pr_select {1})'
}

gf_pr() {
  gf_command_logged git fetch "$GF_BASE_REMOTE"
  if [ $# -eq 0 ]; then
    git fuzzy helper pr_menu_content | gf_fzf_pr_select
  elif [[ "$1" =~ [0-9]+ ]]; then
    DIFF_PARAMS="$(hub pr show --format='%sB %sH' "$1")"
    if [ -z "$DIFF_PARAMS" ]; then
      eval "git fuzzy diff $DIFF_PARAMS"
    fi
  else
    gf_log_error '`git fuzzy pr` only accepts one numeric parameter, the PR number'
  fi
}
