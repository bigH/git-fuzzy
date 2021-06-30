#!/usr/bin/env bash

gf_helper_stash_menu_content() {
  printf "%s%s%s%s%s%s%s\n\n" "$GRAY" "$BOLD" '$ ' "$CYAN" "$BOLD" "git stash list" "$NORMAL"
  git stash list
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

gf_helper_stash_pop() {
  if [ -z "$1" ]; then
    echo "nothing to show"
  else
    STASH_ID="$(echo "$1" | cut -d':' -f1)"

    git stash pop "$STASH_ID"
  fi

}

gf_helper_stash_apply() {
  if [ -z "$1" ]; then
    echo "nothing to show"
  else
    STASH_ID="$(echo "$1" | cut -d':' -f1)"

    git stash apply "$STASH_ID"
  fi

}
