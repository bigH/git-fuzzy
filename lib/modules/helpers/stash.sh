#!/usr/bin/env bash

gf_helper_stash_menu_content() {
  printf "%s" "$GRAY" "$BOLD" '$ ' "$CYAN" "$BOLD"
  printf "%s " "git stash list"
  if [ -n "$1" ]; then
    printf "%s" "| grep " "$(quote_params "$@")"
    printf "%s\n\n" "$NORMAL"
    git stash list | grep "$1"
  else
    printf "%s\n\n" "$NORMAL"
    git stash list
  fi
}

gf_helper_stash_preview_content() {
  if [ -z "$1" ]; then
    echo "nothing to show"
  else
    STASH_ID="$(echo "$1" | cut -d':' -f1)"

    git stash show -p "$STASH_ID" | gf_diff_renderer
  fi
}

gf_helper_stash_drop() {
  if [ -z "$1" ]; then
    echo "nothing to show"
  else
    STASH_ID="$(echo "$1" | cut -d':' -f1)"

    git stash drop "$STASH_ID"
  fi

}
