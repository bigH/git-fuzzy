#!/usr/bin/env bash

gf_snapshot() {
  if [ -n "$GF_SNAPSHOT_DIRECTORY" ]; then
    NAME="snapshot"
    if [ -z "$1" ]; then
      NAME="$1"
    fi
    if [ ! -d "$GF_SNAPSHOT_DIRECTORY" ]; then
      mkdir -p "$GF_SNAPSHOT_DIRECTORY"
    fi
    if [ ! -w "$GF_SNAPSHOT_DIRECTORY" ]; then
      gf_log_error "GF_SNAPSHOT_DIRECTORY not writeable"
      exit 1
    fi

    GF_SNAPSHOT_LOCATION="$(cd "$GF_SNAPSHOT_DIRECTORY" && pwd)"

    NOW="$(date +'%Y-%m-%d-%H-%M-%S')"

    NOW_DIR="$GF_SNAPSHOT_LOCATION/$NAME-$NOW"

    if [ ! -d "$NOW_DIR" ]; then
      mkdir "$NOW_DIR"

      git rev-parse HEAD > "$NOW_DIR/HEAD"
      git rev-parse --abbrev-ref HEAD > "$NOW_DIR/HEAD-branch"
      git diff > "$NOW_DIR/working-copy"
      git diff --staged > "$NOW_DIR/index"

      mkdir "$NOW_DIR/new"

      # NB: creates appropriate directory structure and only copies files in the list
      rsync --files-from <(git status --short | grep '^??' | cut -c4-) . "$NOW_DIR/new/"
    fi
  fi
}
