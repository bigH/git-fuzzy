#!/usr/bin/env bash

GIT_FUZZY_BRANCH_WORKING_COPY_KEY=${GIT_FUZZY_BRANCH_WORKING_COPY_KEY:-Ctrl-P}
GIT_FUZZY_BRANCH_MERGE_BASE_KEY=${GIT_FUZZY_BRANCH_MERGE_BASE_KEY:-Alt-P}
GIT_FUZZY_BRANCH_COMMIT_LOG_KEY=${GIT_FUZZY_BRANCH_COMMIT_LOG_KEY:-Alt-L}
GIT_FUZZY_BRANCH_CHECKOUT_KEY=${GIT_FUZZY_BRANCH_CHECKOUT_KEY:-Alt-F}
GIT_FUZZY_BRANCH_DELETE_BRANCH_KEY=${GIT_FUZZY_BRANCH_DELETE_BRANCH_KEY:-Alt-D}

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

  '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}working copy${NORMAL}  ${WHITE}$GIT_FUZZY_BRANCH_WORKING_COPY_KEY${NORMAL}        $BRANCH_HEADER_BRANCH_CHECKOUT"'
    '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}merge-base${NORMAL}  ${WHITE}$GIT_FUZZY_BRANCH_MERGE_BASE_KEY${NORMAL}         ${GREEN}${BOLD}checkout ${YELLOW}${BOLD}📁${NORMAL} ${WHITE}$GIT_FUZZY_BRANCH_CHECKOUT_KEY${NORMAL}"'
      '"${GREEN}commit log${NORMAL}  ${WHITE}$GIT_FUZZY_BRANCH_COMMIT_LOG_KEY${NORMAL}    ${RED}${BOLD}delete branch ✗${NORMAL}  ${WHITE}$GIT_FUZZY_BRANCH_DELETE_BRANCH_KEY${NORMAL}"'

'

  # shellcheck disable=2046,2016,2090,2086
  gf_fzf_one -m \
             --header "$BRANCH_HEADER" \
             $BRANCH_CHECKOUT_BINDING \
             --bind $GIT_FUZZY_BRANCH_CHECKOUT_KEY':execute(git fuzzy helper branch_checkout_files {1})' \
             --bind "$GIT_FUZZY_BRANCH_DELETE_BRANCH_KEY:$GF_BRANCH_DELETE_BINDING" \
             --bind $GIT_FUZZY_BRANCH_COMMIT_LOG_KEY':execute(git fuzzy log {1})' \
             --bind $GIT_FUZZY_BRANCH_WORKING_COPY_KEY':execute(git fuzzy diff {1})' \
             --bind $GIT_FUZZY_BRANCH_MERGE_BASE_KEY':execute(git fuzzy diff "$(git merge-base "'"$GF_BASE_BRANCH"'" {1})" {1})' \
             --preview 'git fuzzy helper branch_preview_content {1}' | \
    awk '{ print $1 }'
}

gf_branch() {
  gf_snapshot "branch"
  git fuzzy helper branch_menu_content | gf_fzf_branch
}
