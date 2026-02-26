#!/usr/bin/env bash

gf_helper_pr_menu_content() {
  gf_command_with_header 2 gh pr list --json number,title,labels,state,updatedAt --template "$GF_GH_PR_FORMAT"
}

gf_helper_pr_preview_content() {
  if [ -n "$1" ]; then
    DIFF_PARAMS="$(gh pr view "$1" --json baseRefName,headRefName --jq '"\(.baseRefName) \(.headRefName)"')"
    if [ -n "$DIFF_PARAMS" ]; then
      # shellcheck disable=2086
      gf_git_command_with_header 1 diff $DIFF_PARAMS
    fi
  fi
}

gf_helper_pr_select() {
  if [ -n "$1" ]; then
    DIFF_PARAMS="$(gh pr view "$1" --json baseRefName,headRefName --jq '"\(.baseRefName) \(.headRefName)"')"
    if [ -n "$DIFF_PARAMS" ]; then
      # shellcheck disable=2086
      gf_git_command_with_header 1 fuzzy diff $DIFF_PARAMS
    fi
  fi
}

gf_helper_pr_show() {
  if [ -n "$1" ]; then
    gh pr view "$1" --web
  fi
}

gf_helper_pr_log() {
  if [ -n "$1" ]; then
    DIFF_PARAMS="$(gh pr view "$1" --json baseRefName,headRefName --jq '"\(.baseRefName)..\(.headRefName)"')"
    if [ -n "$DIFF_PARAMS" ]; then
      # shellcheck disable=2086
      gf_git_command_with_header 1 fuzzy log $DIFF_PARAMS
    fi
  fi
}
