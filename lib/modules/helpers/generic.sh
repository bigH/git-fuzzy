#!/usr/bin/env bash

gf_fzf_log_line_interpreter() {
  cat - | awk '{ print $1 }'
}
