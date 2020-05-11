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


# quotes mult-word parameters in order to make a command copy-paste with ease
quote_single_param() {
  if [ -z "$1" ] || [[ "$1" = *' '* ]]; then
    if [[ "$1" = *"'"* ]]; then
      echo "\"$1\""
    else
      echo "'$1'"
    fi
  else
    echo "$1"
  fi
}

# quotes a list of params using `"$@"`
# MISSING: support for anything escapable (`\n`, `\t`, etc.?)
# MISSING: support quotes in params (e.g. quoting `'a' "b'd"`)
quote_params() {
  REST=""
  for arg in "$@"; do
    if [ -z "$REST" ]; then
      printf "%s" "$(quote_single_param "$arg")"
      REST=true
    else
      printf " %s" "$(quote_single_param "$arg")"
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
          printf '%s' "$(quote_single_param "$1")"
          REST=true
        else
          printf ' %s' "$(quote_single_param "$1")"
        fi
        shift
        ;;
    esac
  done
}
