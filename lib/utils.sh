#!/usr/bin/env bash
# shellcheck disable=2155

if [ -z "$COLOR_SUPPORT" ]; then
  export COLOR_SUPPORT="YES"

  export DARK_GRAY="$(tput setaf 0)"
  export RED="$(tput setaf 1)"
  export GREEN="$(tput setaf 2)"
  export YELLOW="$(tput setaf 3)"
  export BLUE="$(tput setaf 4)"
  export MAGENTA="$(tput setaf 5)"
  export CYAN="$(tput setaf 6)"
  export WHITE="$(tput setaf 7)"
  export GRAY="$(tput setaf 8)"
  export BOLD="$(tput bold)"
  export UNDERLINE="$(tput sgr 0 1)"
  export INVERT="$(tput sgr 1 0)"
  export NORMAL="$(tput sgr0)"

  # Mispellings
  export DARKGRAY="$DARK_GRAY"
  export DARK_GREY="$DARK_GRAY"
  export DARKGREY="$DARK_GRAY"
  export GREY="$GRAY"
fi

quote_params() {
  if [ "$#" -eq 0 ]; then
    printf ''
  else
    printf '%q ' "$@"
  fi
}
