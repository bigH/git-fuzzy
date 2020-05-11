#!/usr/bin/env bash

gf_helper_diff_checkout_file() {
  BRANCH="$1"
  shift
  if [ -n "$BRANCH" ] && [ "$#" -gt 0 ]; then
    gf_command_logged git checkout "$BRANCH" -- "$@"
  else
    gf_log_error "invalid args for \`checkout\`: '$BRANCH' -- $(quote_params "$@")"
  fi
}
