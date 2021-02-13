#!/usr/bin/env bash

DARK_GRAY="$(tput setaf 0)"
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
BLUE="$(tput setaf 4)"
MAGENTA="$(tput setaf 5)"
CYAN="$(tput setaf 6)"
WHITE="$(tput setaf 7)"
GRAY="$(tput setaf 8)"
BOLD="$(tput bold)"
UNDERLINE="$(tput sgr 0 1)"
INVERT="$(tput sgr 1 0)"
NORMAL="$(tput sgr0)"

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
