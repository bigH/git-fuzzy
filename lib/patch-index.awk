#!/usr/bin/awk -f

# Array utilities

function push(A,B) {
  A[length(A)] = B;
}

function new_array(A) {
  split("", A);
}

function set_file_name() {
  if (preamble[1] ~ /^--- \/dev\/null$/) {
    file_name = ENVIRON["GREEN"] substr(preamble[2], 7) ENVIRON["NORMAL"]
  } else if (preamble[2] ~ /^\+\+\+ \/dev\/null$/) {
    file_name = ENVIRON["RED"] substr(preamble[1], 7) ENVIRON["NORMAL"]
  } else {
    remove_file_name = substr(preamble[1], 7)
    add_file_name = substr(preamble[2], 7)
    if (remove_file_name == add_file_name) {
      file_name = ENVIRON["YELLOW"] add_file_name ENVIRON["NORMAL"]
    } else {
      file_name = ENVIRON["RED"] remove_file_name ENVIRON["GRAY"] " -> " ENVIRON["GREEN"] add_file_name ENVIRON["NORMAL"] 
    }
  }
}

# hunk management

function print_hunk_line() {
  if (preamble[1] ~ /^--- \/dev\/null$/) {
    file_marker = ENVIRON["GREEN"] ENVIRON["BOLD"] "+++" ENVIRON["NORMAL"];
  } else if (preamble[2] ~ /^\+\+\+ \/dev\/null$/) {
    file_marker = ENVIRON["RED"] ENVIRON["BOLD"] "---" ENVIRON["NORMAL"];
  } else {
    file_marker = ENVIRON["YELLOW"] ENVIRON["BOLD"] "+/-" ENVIRON["NORMAL"];
  }

  file_hunk_number_str = ENVIRON["GRAY"] "#" ENVIRON["MAGENTA"] ENVIRON["BOLD"] file_hunk_number ENVIRON["NORMAL"]

  set_file_name()
  printf("%s %s %s %s\n", hunk_number, file_marker, file_hunk_number_str, file_name);

  file_hunk_number ++;
  hunk_number ++;
}

BEGIN {
  hunk_number = 0;
}

/^diff --git/ {
  file_hunk_number = 1;
  new_array(preamble);
  push(preamble, $0);
}

/^---/ {
  push(preamble, $0);
}

/^\+\+\+/ {
  push(preamble, $0);
}

/^@@/ {
  print_hunk_line();
}
