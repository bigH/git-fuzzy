#!/usr/bin/awk -f

# Array utilities

function push(A,B) {
  idx = length(A);
  A[idx] = B;
}

function new_array(A) {
  split("", A);
}

function contains_string_version_of(A, E) {
  for (i in A) {
    if (A[i] == E"") {
      return 1;
    }
  }
  return 0
}

# hunk management

function new_hunk() {
  if (length(hunk) > 0) {
    if (contains_string_version_of(desired_hunk_numbers_tokenized, hunk_number)) {
      for (preamble_index = 0; preamble_index < length(preamble); preamble_index ++) {
        print preamble[preamble_index];
      }
      for (hunk_index = 0; hunk_index < length(hunk); hunk_index ++) {
        print hunk[hunk_index];
      }
    }
    hunk_number++;
  }

  new_array(hunk);
}

BEGIN {
  split(desired_hunk_numbers, desired_hunk_numbers_tokenized, ",")
  hunk_number = 0;
}

# diff marker detection
/^diff --git/ {
  new_hunk()
  in_hunk = 0;
  new_array(preamble);
  push(preamble, $0);
}

/^---/ {
  in_hunk = 0
  push(preamble, $0);
}

/^\+\+\+/ {
  in_hunk = 0
  push(preamble, $0);
}

/^@@/ {
  new_hunk()
  in_hunk = 1;
}

# treatment for every line
{
  print $0
  if (in_hunk) {
    push(hunk, $0);
  }
}

# ensure we print last hunk
END {
  new_hunk();
}
