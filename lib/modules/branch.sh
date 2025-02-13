#!/usr/bin/env bash

GIT_FUZZY_BRANCH_WORKING_COPY_KEY="${GIT_FUZZY_BRANCH_WORKING_COPY_KEY:-Ctrl-P}"
GIT_FUZZY_BRANCH_MERGE_BASE_KEY="${GIT_FUZZY_BRANCH_MERGE_BASE_KEY:-Alt-P}"
GIT_FUZZY_BRANCH_COMMIT_LOG_KEY="${GIT_FUZZY_BRANCH_COMMIT_LOG_KEY:-Alt-L}"
GIT_FUZZY_BRANCH_CHECKOUT_FILE_KEY="${GIT_FUZZY_BRANCH_CHECKOUT_FILE_KEY:-Alt-F}"
GIT_FUZZY_BRANCH_CHECKOUT_KEY="${GIT_FUZZY_BRANCH_CHECKOUT_KEY:-Alt-B}"
GIT_FUZZY_BRANCH_DELETE_BRANCH_KEY="${GIT_FUZZY_BRANCH_DELETE_BRANCH_KEY:-Alt-D}"

GF_BRANCH_RELOAD="reload(git fuzzy helper branch_menu_content)"

GF_BRANCH_CHECKOUT="git fuzzy helper branch_checkout {1}"

GF_BRANCH_ATTEMPT_DELETE="git fuzzy helper branch_delete {1}"
GF_BRANCH_DELETE_BINDING="execute-silent($GF_BRANCH_ATTEMPT_DELETE)+$GF_BRANCH_RELOAD"

gf_fzf_branch() {
BRANCH_HEADER='
Type to filter. '"${WHITE}Enter${NORMAL} to ${GREEN}ACCEPT${NORMAL}"'
Select an entry with '"${WHITE}<Tab>${NORMAL}"' to use as basis for comparison in the preview.
'
  BRANCH_CHECKOUT_BINDING="$(lowercase "$GIT_FUZZY_BRANCH_CHECKOUT_KEY"):execute-silent($GF_BRANCH_CHECKOUT)+$GF_BRANCH_RELOAD"
  BRANCH_HEADER_BRANCH_CHECKOUT="    ${GREEN}${BOLD}checkout ${YELLOW}${BOLD}${NORMAL}  ${WHITE}${GIT_FUZZY_BRANCH_CHECKOUT_KEY}${NORMAL}"
  BRANCH_HEADER_FILE_CHECKOUT="    ${GREEN}${BOLD}checkout ${YELLOW}${BOLD}📁${NORMAL} ${WHITE}${GIT_FUZZY_BRANCH_CHECKOUT_FILE_KEY}${NORMAL}"
  if [ -n "$(git status --short)" ]; then
    # files are dirty - warn that checkout is potentially undesired
    BRANCH_HEADER_BRANCH_CHECKOUT="${GRAY}(${RED}${BOLD}*${GRAY}) ${RED}${BOLD}checkout ${YELLOW}${BOLD}${NORMAL}  ${WHITE}${GIT_FUZZY_BRANCH_CHECKOUT_KEY}${NORMAL}"
    BRANCH_HEADER_FILE_CHECKOUT="${GRAY}(${RED}${BOLD}*${GRAY}) ${RED}${BOLD}checkout ${YELLOW}${BOLD}📁${NORMAL} ${WHITE}${GIT_FUZZY_BRANCH_CHECKOUT_FILE_KEY}${NORMAL}"
    BRANCH_HEADER="$BRANCH_HEADER"'
'"${GRAY}(${RED}${BOLD}*${GRAY}) ${NORMAL}working copy is dirty; changes may be ${RED}${BOLD}destructive${NORMAL}"'
'
  fi

BRANCH_HEADER="$BRANCH_HEADER"'
  '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}working copy${NORMAL}  ${WHITE}$GIT_FUZZY_BRANCH_WORKING_COPY_KEY${NORMAL}    $BRANCH_HEADER_BRANCH_CHECKOUT"'
    '"${YELLOW}${BOLD}∆${NORMAL} ${GREEN}merge-base${NORMAL}  ${WHITE}$GIT_FUZZY_BRANCH_MERGE_BASE_KEY${NORMAL}     $BRANCH_HEADER_FILE_CHECKOUT"'
      '"${GREEN}commit log${NORMAL}  ${WHITE}$GIT_FUZZY_BRANCH_COMMIT_LOG_KEY${NORMAL}    ${RED}${BOLD}delete branch ✗${NORMAL}  ${WHITE}$GIT_FUZZY_BRANCH_DELETE_BRANCH_KEY${NORMAL}"'

'

if [ "$(particularly_small_screen)" = '1' ]; then
  BRANCH_HEADER=''
fi

  # shellcheck disable=2046,2016,2090,2086
  gf_fzf_one -m \
             --header "$BRANCH_HEADER" \
             --bind 'click-header:reload(git fuzzy helper branch_menu_content)' \
             --bind 'backward-eof:reload(git fuzzy helper branch_menu_content)' \
             --bind "$BRANCH_CHECKOUT_BINDING" \
             --bind "$(lowercase "$GIT_FUZZY_BRANCH_CHECKOUT_FILE_KEY")"':execute(git fuzzy helper branch_checkout_files {1})' \
             --bind "$(lowercase "$GIT_FUZZY_BRANCH_DELETE_BRANCH_KEY"):$GF_BRANCH_DELETE_BINDING" \
             --bind "$(lowercase "$GIT_FUZZY_BRANCH_COMMIT_LOG_KEY")"':execute(git fuzzy log {1})' \
             --bind "$(lowercase "$GIT_FUZZY_BRANCH_WORKING_COPY_KEY")"':execute(git fuzzy diff {1})' \
             --bind "$(lowercase "$GIT_FUZZY_BRANCH_MERGE_BASE_KEY")"':execute(git fuzzy diff "$(git merge-base "'"$GF_BASE_BRANCH"'" {1})" {1})' \
             --preview 'git fuzzy helper branch_preview_content {1} {+1}' | \
    awk '{ print $1 }'
}

gf_branch() {
  gf_snapshot "branch"
  git fuzzy helper branch_menu_content | gf_fzf_branch
}
