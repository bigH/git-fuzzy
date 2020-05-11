#!/usr/bin/env bash

# -- Configuring FZF UI: --

if [ -z "$GF_VERTICAL_THRESHOLD" ]; then
  export GF_VERTICAL_THRESHOLD="2.0"
fi

if [ -z "$GF_VERTICAL_PREVIEW_LOCATION" ]; then
  export GF_VERTICAL_PREVIEW_LOCATION="bottom"
fi

if [ -z "$GF_HORIZONTAL_PREVIEW_LOCATION" ]; then
  export GF_HORIZONTAL_PREVIEW_LOCATION="right"
fi

if [ -z "$GF_HORIZONTAL_PREVIEW_PERCENT_CALCULATION" ]; then
  export GF_HORIZONTAL_PREVIEW_PERCENT_CALCULATION='max(50, min(80, 100 - ((7000 + (11 * __WIDTH__))  / __WIDTH__)))'
fi

if [ -z "$GF_VERTICAL_PREVIEW_PERCENT_CALCULATION" ]; then
  export GF_VERTICAL_PREVIEW_PERCENT_CALCULATION='max(50, min(80, 100 - ((4000 + (5 * __HEIGHT__)) / __HEIGHT__)))'
fi

# -- Configuring External Command Style: --

# NB: used for highlighting search terms in diff output
if [ -n "$GF_GREP_COLOR" ]; then
  # NB: needs exporting as `grep` runs as a subprocess
  export GREP_COLOR="$GF_GREP_COLOR"
fi

if [ -n "$GF_BAT_STYLE" ]; then
  # NB: needs exporting as `bat` runs as a subprocess
  export BAT_STYLE="$GF_BAT_STYLE"
fi

if [ -n "$GF_BAT_THEME" ]; then
  # NB: needs exporting as `bat` runs as a subprocess
  export BAT_THEME="$GF_BAT_THEME"
fi

# -- Configuring `$EDITOR`: --

if [ -z "$GF_EDITOR_ARGS" ]; then
  export GF_EDITOR_ARGS=''
fi

# -- Configuring `git`: --

if [ -z "$GF_DIFF_SEARCH_DEFAULTS" ]; then
  export GF_DIFF_SEARCH_DEFAULTS="-G"
fi

if [ -z "$GF_HUB_PR_FORMAT" ]; then
  export GF_HUB_PR_FORMAT='%pC%>(8)%I%Creset  %t%  l%n'
fi

if [ -z "$GF_LOG_MENU_PARAMS" ]; then
  export GF_LOG_MENU_PARAMS='--pretty=oneline --abbrev-commit'
fi

if [ -z "$GF_REFLOG_MENU_PARAMS" ]; then
  export GF_REFLOG_MENU_PARAMS='--pretty=oneline --abbrev-commit'
fi

if [ -z "$GF_BASE_REMOTE" ]; then
  export GF_BASE_REMOTE=origin
fi

if [ -z "$GF_BASE_BRANCH" ]; then
  GF_BASE_BRANCH="$(git symbolic-ref "refs/remotes/${GF_BASE_REMOTE}/HEAD" | sed "s@^refs/remotes/${GF_BASE_REMOTE}/@@")"
  export GF_BASE_BRANCH
fi

if [ -r "./.git-fuzzy-config" ]; then
  # shellcheck disable=1091
  . "./.git-fuzzy-config"
fi
