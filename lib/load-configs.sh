#!/usr/bin/env bash

# -- High Level Configurations: --

GF_ENABLE_GITHUB_ASSUMPTIONS="${GF_ENABLE_GITHUB_ASSUMPTIONS:-2.0}"

# -- Configuring FZF UI: --

GF_VERTICAL_THRESHOLD="${GF_VERTICAL_THRESHOLD:-2.0}"
GF_VERTICAL_PREVIEW_LOCATION="${GF_VERTICAL_PREVIEW_LOCATION:-bottom}"
GF_HORIZONTAL_PREVIEW_LOCATION="${GF_HORIZONTAL_PREVIEW_LOCATION:-right}"

GF_HORIZONTAL_PREVIEW_PERCENT_CALCULATION_DEFAULT='max(50, min(80, 100 - ((7000 + (11 * __WIDTH__))  / __WIDTH__)))'
GF_HORIZONTAL_PREVIEW_PERCENT_CALCULATION="${GF_HORIZONTAL_PREVIEW_PERCENT_CALCULATION:-${GF_HORIZONTAL_PREVIEW_PERCENT_CALCULATION_DEFAULT}}"

GF_HORIZONTAL_SMALL_SCREEN_CALCULATION_DEFAULT='__HEIGHT__ <= 30'
GF_HORIZONTAL_SMALL_SCREEN_CALCULATION="${GF_HORIZONTAL_SMALL_SCREEN_CALCULATION:-${GF_HORIZONTAL_SMALL_SCREEN_CALCULATION_DEFAULT}}"

GF_VERTICAL_PREVIEW_PERCENT_CALCULATION_DEFAULT='max(50, min(80, 100 - ((3000 + __HEIGHT__) / __HEIGHT__)))'
GF_VERTICAL_PREVIEW_PERCENT_CALCULATION="${GF_VERTICAL_PREVIEW_PERCENT_CALCULATION:-${GF_VERTICAL_PREVIEW_PERCENT_CALCULATION_DEFAULT}}"

GF_VERTICAL_SMALL_SCREEN_CALCULATION_DEFAULT='__HEIGHT__ <= 60'
GF_VERTICAL_SMALL_SCREEN_CALCULATION="${GF_VERTICAL_SMALL_SCREEN_CALCULATION:-${GF_VERTICAL_SMALL_SCREEN_CALCULATION_DEFAULT}}"

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

GF_EDITOR_ARGS="${GF_EDITOR_ARGS:-}"

# -- Configuring `git`: --

GF_DIFF_SEARCH_DEFAULTS="${GF_DIFF_SEARCH_DEFAULTS:-}"

if [ -z "$GF_HUB_PR_FORMAT" ]; then
  GF_HUB_PR_FORMAT="%pC%>(8)%I%Creset  %t%  l%n"
fi

GF_LOG_MENU_PARAMS_DEFAULT='--pretty=oneline --abbrev-commit'
GF_LOG_MENU_PARAMS="${GF_LOG_MENU_PARAMS:-${GF_LOG_MENU_PARAMS_DEFAULT}}"

GF_REFLOG_MENU_PARAMS_DEFAULT='--pretty=oneline --abbrev-commit'
GF_REFLOG_MENU_PARAMS="${GF_REFLOG_MENU_PARAMS:-${GF_REFLOG_MENU_PARAMS_DEFAULT}}"

GF_BASE_REMOTE="${GF_BASE_REMOTE:-origin}"

if [ -z "$GF_BASE_BRANCH" ]; then
  GF_BASE_BRANCH="$(git symbolic-ref -q "refs/remotes/${GF_BASE_REMOTE}/HEAD" || echo -n "main" | sed "s@^refs/remotes/${GF_BASE_REMOTE}/@@")"
  export GF_BASE_BRANCH
fi

# -- Configuring Web Open: --

if [[ "$OSTYPE" == "darwin"* ]]; then
    GF_WEB_OPEN="${GF_WEB_OPEN:-open}"
else
    GF_WEB_OPEN="${GF_WEB_OPEN:-xdg-open}"
fi

# -- Load directory-specific overrides: --

if [ -r "./.git-fuzzy-config" ]; then
  # shellcheck disable=1091
  . "./.git-fuzzy-config"
fi
