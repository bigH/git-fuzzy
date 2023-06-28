#!/usr/bin/env bash

gf_helper_diff_patch_menu_content() {
  git diff "$@" | \
    awk -f "$git_fuzzy_dir/lib/patch-index.awk"
}

gf_helper_diff_patch_preview_content() {
  desired_hunk_number="$1"
  shift
  git diff "$@" | \
    awk -f "$git_fuzzy_dir/lib/patch-selector.awk" -v desired_hunk_numbers="$desired_hunk_number" | \
    gf_diff_renderer
}

gf_helper_diff_patch_combined() {
  desired_hunk_numbers="$1"
  shift

  while [ "$1" != "--" ]; do
    desired_hunk_numbers="${desired_hunk_numbers}\n$1"
    shift
  done
  shift

  desired_hunk_numbers_sorted="$(echo "$desired_hunk_numbers" | sort -n | join_lines_with_commas)"

  git diff "$@" | \
    awk -f "$git_fuzzy_dir/lib/patch-selector.awk" -v desired_hunk_numbers="$desired_hunk_numbers_sorted"
}

gf_helper_diff_patch_apply_to_working_copy() {
  git fuzzy helper diff_patch_combined "$@" | \
    git apply
}

gf_helper_diff_patch_apply_to_index() {
  git fuzzy helper diff_patch_combined "$@" | \
    git apply --index
}
