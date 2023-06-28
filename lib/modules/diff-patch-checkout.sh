#!/usr/bin/env bash

GIT_FUZZY_DIFF_PATCH_INTO_INDEX_KEY="${GIT_FUZZY_DIFF_PATCH_INTO_INDEX_KEY:-Alt-I}"

# shellcheck disable=2016
GF_DIFF_PATCH_HEADER='
Type to filter. '"${WHITE}Enter${NORMAL} to ${GREEN}APPLY TO WORKING COPY${NORMAL}"'
Select an entry with '"${WHITE}<Tab>${NORMAL}"' to checkout into your WC/index

  (we do not verify if the patch will work OR if has already been applied)
'

GF_DIFF_PATCH_HEADER="$GF_DIFF_PATCH_HEADER"'
         '"${YELLOW}${BOLD}↘${NORMAL} ${GREEN}index${NORMAL}  ${WHITE}${GIT_FUZZY_DIFF_PATCH_INTO_INDEX_KEY}${NORMAL}"'

'

if [ "$(particularly_small_screen)" = '1' ]; then
  GF_DIFF_PATCH_HEADER=''
fi

gf_fzf_diff_patch() {
  # shellcheck disable=2016
  PREVIEW_COMMAND="git fuzzy helper diff_patch_preview_content {1} $(quote_params "$@")"

  gf_fzf -m --with-nth=2.. \
    --header-lines=0 \
    --header "$GF_DIFF_PATCH_HEADER" \
    --preview "$PREVIEW_COMMAND" \
    --bind "$(lowercase "$GIT_FUZZY_DIFF_PATCH_INTO_INDEX_KEY"):execute-silent(git fuzzy helper diff_patch_apply_to_index {+1} -- $(quote_params "$@"))+down"
}

gf_diff_patch() {
  gf_snapshot "diff-patch"
  gf_go_to_git_root_directory
  SELECTIONS="$(git fuzzy helper diff_patch_menu_content "$@" | \
    gf_fzf_diff_patch "$@" | \
    awk '{ print $1 }' | \
    join_lines_with_commas)"
  echo git fuzzy helper diff_patch_combined "$SELECTIONS" -- "$@"
}
