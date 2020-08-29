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


# quotes a list of params by escaping whitespace and special characters so word-splitting happens as desired
quote_params() {
  REST=""
  for arg in "$@"; do
    if [ -z "$REST" ]; then
      printf "%s" "$(printf '%q' "$arg")"
      REST=true
    else
      printf " %s" "$(printf '%q' "$arg")"
    fi
  done
}

# filter out switches
remove_switches() {
  REST=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --*) shift ;;
      -*) shift ;;
      *)
        if [ -z "$REST" ]; then
          printf '%s' "$(printf '%q' "$1")"
          REST=true
        else
          printf ' %s' "$(printf '%q' "$1")"
        fi
        shift
        ;;
    esac
  done
}
