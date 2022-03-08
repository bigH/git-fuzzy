#!/usr/bin/env bash

# get the first token by `|`
gf_helper_log_log_query() {
  echo "$1" | cut -d'|' -f1
}

# get the _last_ token by `|`
# NB: this supports using the same query for both chunks
gf_helper_log_diff_query() {
  echo "$1" | rev | cut -d'|' -f1 | rev
}

# TODO faithfully pass `log` params to `log_menu_contents` (e.g. branch name)
gf_helper_log_menu_content() {
  QUERY="$(git fuzzy helper log_log_query "$1")"
  shift
  if [ -n "$QUERY" ]; then
    # shellcheck disable=2086
    gf_git_command_with_header_default_parameters 2 "$GF_LOG_MENU_PARAMS" log $QUERY "$@"
  else
    gf_git_command_with_header_default_parameters 2 "$GF_LOG_MENU_PARAMS" log "$@"
  fi
}

gf_helper_log_preview_content() {
  if [ -z "$1" ]; then
    echo "nothing to show (empty line)"
  else
    REF="$(extract_commit_hash_from_first_line "$1")"
    if [ -n "$REF" ]; then
      QUERY="$(git fuzzy helper log_diff_query "$2")"

      # NB: `fold` is not aware of color codes; however, folding over whitespace seems fine
      gf_git_command show --decorate --no-patch "$REF" | fold -s -w "$FZF_PREVIEW_COLUMNS"
      echo

      # shellcheck disable=2086
      gf_git_command_with_header_default_parameters 1 "$GF_DIFF_COMMIT_PREVIEW_DEFAULTS" diff "$REF^" "$REF" $QUERY | gf_diff_renderer
    else
      echo "nothing to show (no commit found on line)"
    fi
  fi
}

gf_helper_log_open_commit_diff() {
  if [ -z "$1" ]; then
    echo "nothing to show (no mode selected)"
  else
    MODE="$1"
    shift
    if [ -z "$1" ]; then
      echo "nothing to show (empty line)"
    else
      COMMIT_HASH="$(extract_commit_hash_from_first_line "$1")"
      if [ -n "$REF" ]; then
        case "$MODE" in
          commit)       git fuzzy diff "$REF^" "$REF" ;;
          working_copy) git fuzzy diff "$REF" ;;
          merge_base)   git fuzzy diff "$(git merge-base "$GF_BASE_BRANCH" "$REF")" "$REF" ;;
          *) log_error "mode unknown: $MODE" ;;
        esac
      else
        echo "nothing to show (no commit found on line)"
      fi
    fi
  fi
}
