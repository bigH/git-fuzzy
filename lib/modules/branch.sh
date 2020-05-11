#!/usr/bin/env bash

GF_BRANCH_RELOAD="reload(git fuzzy helper branch_menu_content)"

GF_BRANCH_CHECKOUT="git fuzzy helper branch_checkout {1}"
# shellcheck disable=2089
GF_BRANCH_CHECKOUT_BINDING="--bind \"alt-b:execute-silent($GF_BRANCH_CHECKOUT)+$GF_BRANCH_RELOAD\""

GF_BRANCH_ATTEMPT_DELETE="git fuzzy helper branch_delete {1}"
GF_BRANCH_DELETE_BINDING="execute-silent($GF_BRANCH_ATTEMPT_DELETE)+$GF_BRANCH_RELOAD"

gf_fzf_branch() {
  if [ -n "$(git status --short)" ]; then
    BRANCH_CHECKOUT_BINDING=""
    BRANCH_HEADER_BRANCH_CHECKOUT="${GRAY}${BOLD}checkout ${YELLOW}${BOLD}${GRAY}  DISABLED${NORMAL}"
  else
    BRANCH_CHECKOUT_BINDING="$GF_BRANCH_CHECKOUT_BINDING"
    BRANCH_HEADER_BRANCH_CHECKOUT="${GREEN}${BOLD}checkout ${YELLOW}${BOLD}${NORMAL}  ${WHITE}Alt-B${NORMAL}"
  fi

BRANCH_HEADER='
Type to filter. '"${WHITE}Enter${NORMAL} to ${GREEN}ACCEPT${NORMAL}"'

  '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}working copy${NORMAL}  ${WHITE}Ctrl-P${NORMAL}        $BRANCH_HEADER_BRANCH_CHECKOUT"'
    '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}merge-base${NORMAL}  ${WHITE}Alt-P${NORMAL}         ${GREEN}${BOLD}checkout ${YELLOW}${BOLD}📁${NORMAL} ${WHITE}Alt-F${NORMAL}"'
      '"${GREEN}commit log${NORMAL}  ${WHITE}Alt-L${NORMAL}    ${RED}${BOLD}delete branch ✗${NORMAL}  ${WHITE}Alt-D${NORMAL}"'

'

  # shellcheck disable=2046,2016,2090,2086
  gf_fzf_one -m \
             --header "$BRANCH_HEADER" \
             $BRANCH_CHECKOUT_BINDING \
             --bind 'alt-f:execute(git fuzzy helper branch_checkout_files {1})' \
             --bind "alt-d:$GF_BRANCH_DELETE_BINDING" \
             --bind 'alt-l:execute(git fuzzy log {1})' \
             --bind 'ctrl-p:execute(git fuzzy diff {1})' \
             --bind 'alt-p:execute(git fuzzy diff "$(git merge-base "'"$GF_BASE_BRANCH"'" {1})" {1})' \
             --preview 'git fuzzy helper branch_preview_content {1}' | \
    awk '{ print $1 }'
}

gf_branch() {
  gf_snapshot "branch"
  git fuzzy helper branch_menu_content | gf_fzf_branch
}
