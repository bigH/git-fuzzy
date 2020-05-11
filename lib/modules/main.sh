#!/usr/bin/env bash

gf_menu_item() {
  printf 'choice %s%s%-10s%s %s%s%s' "$MAGENTA" "$BOLD" "$1" "$NORMAL" "$GRAY" "$2" "$NORMAL"
  echo
}

# shellcheck disable=2016
gf_menu_content() {
  gf_menu_item 'status' '`status`, `add`, `reset`, and other status-related tools'
  echo
  gf_menu_item 'branch' 'list branches, `checkout`, `diff`, etc.'
  gf_menu_item 'log' 'browse the log and search diffs'
  gf_menu_item 'reflog' 'browse the reflog and search diffs'
  echo
  gf_menu_item 'diff' 'compare up to two branches (remote or local)'

  if [ -n "$HUB_AVAILABLE" ]; then
    echo
    echo "header ${YELLOW}-- 🚧 ${CYAN}${BOLD}GitHub${NORMAL}${YELLOW} 🚧 --${NORMAL}"
    echo
    gf_menu_item "pr" "browse and see diffs of pull requests"
  fi
}

gf_fzf_main() {
  gf_fzf_one \
    "$(hidden_preview_window_settings)" \
    --with-nth=2.. \
    --bind "enter:execute([ {1} = 'choice' ] && git fuzzy interactive {2})"
}

gf_menu() {
  gf_menu_content | gf_fzf_main
}
