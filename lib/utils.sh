#!/usr/bin/env bash

DARK_GRAY="${DARK_GRAY:-$(tput setaf 0)}"
RED="${RED:-$(tput setaf 1)}"
GREEN="${GREEN:-$(tput setaf 2)}"
YELLOW="${YELLOW:-$(tput setaf 3)}"
BLUE="${BLUE:-$(tput setaf 4)}"
MAGENTA="${MAGENTA:-$(tput setaf 5)}"
CYAN="${CYAN:-$(tput setaf 6)}"
WHITE="${WHITE:-$(tput setaf 7)}"
GRAY="${GRAY:-$(tput setaf 8)}"
BOLD="${BOLD:-$(tput bold)}"
UNDERLINE="${UNDERLINE:-$(tput sgr 0 1)}"
INVERT="${INVERT:-$(tput sgr 1 0)}"
NORMAL="${NORMAL:-$(tput sgr0)}"

export DARK_GRAY
export RED
export GREEN
export YELLOW
export BLUE
export MAGENTA
export CYAN
export WHITE
export GRAY
export BOLD
export UNDERLINE
export INVERT
export NORMAL

# Mispellings
export DARKGRAY="$DARK_GRAY"
export DARK_GREY="$DARK_GRAY"
export DARKGREY="$DARK_GRAY"
export GREY="$GRAY"

quote_params() {
  if [ "$#" -eq 0 ]; then
    printf ''
  else
    printf '%q ' "$@"
  fi
}

lowercase() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

join_lines_quoted() {
  IFS=$'\r\n' eval 'LINES_TO_BE_QUOTED=($(cat -))'

  if [ "${#LINES_TO_BE_QUOTED[@]}" -gt 0 ]; then
    printf ' %q' "${LINES_TO_BE_QUOTED[@]}"
  else
    printf ''
  fi
}

extract_commit_hash_from_first_line() {
  # shellcheck disable=2001
  echo "$1" | awk '{
    for(i=1; i<=NF; i++) {
      if(match($i, /^[0-9a-f]{7,40}$/)){ print $i }
    }
  }'
}
