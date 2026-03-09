#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve the repo root from the script's own location so the script can be
# invoked from any working directory without "folder not found" errors.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a sorted array of Question-* directories found in the repo root.
get_questions() {
  # Sort numerically on the number that follows "Question-"
  find . -maxdepth 1 -type d -name 'Question-*' \
    | sed 's|^\./||' \
    | sort -t'-' -k2 -V
}

# Given a user-supplied name (e.g. "Question-01" or "Question-1 MariaDB..."),
# try to find the matching directory.  Normalise leading zeros so "Question-01"
# resolves to "Question-1 ...".
resolve_question_dir() {
  local input="$1"

  # Exact match first.
  if [[ -d "$input" ]]; then
    echo "$input"
    return 0
  fi

  # Strip leading zeros from the number part: "Question-01" → "Question-1"
  local normalised
  normalised="$(echo "$input" | sed 's/\(Question-\)0*\([0-9]\+\)/\1\2/')"

  if [[ -d "$normalised" ]]; then
    echo "$normalised"
    return 0
  fi

  # Prefix match: find a directory that starts with the normalised name
  # followed by a space (avoids "Question-1" matching "Question-14").
  local match
  match="$(find . -maxdepth 1 -type d \
    | sed 's|^\./||' \
    | grep -E "^${normalised}( |$)" \
    | head -1)"
  if [[ -n "$match" && -d "$match" ]]; then
    echo "$match"
    return 0
  fi

  return 1
}

# Run a resolved question directory.
run_question() {
  local dir="$1"

  local setup="$dir/LabSetUp.bash"
  local question_text="$dir/Questions.bash"
  local solution="$dir/SolutionNotes.bash"

  [[ -f "$setup" ]]         || { echo "ERROR: Missing $setup" >&2; exit 1; }
  [[ -f "$question_text" ]] || { echo "ERROR: Missing $question_text" >&2; exit 1; }

  echo "==> Running lab setup for: $dir"
  bash "$setup"

  echo
  echo "==> Question"
  cat "$question_text"

  echo
  if [[ -f "$solution" ]]; then
    echo "Hints: see $solution"
  fi
}

# ---------------------------------------------------------------------------
# Interactive UI
# ---------------------------------------------------------------------------
interactive_menu() {
  local filter=""

  while true; do
    # Build list (optionally filtered).
    mapfile -t questions < <(get_questions)
    local filtered=()
    for q in "${questions[@]}"; do
      if [[ -z "$filter" ]] || echo "$q" | grep -qi "$filter"; then
        filtered+=("$q")
      fi
    done

    echo
    echo "========================================"
    echo "   CKA Practice — Select a Question"
    echo "========================================"

    if [[ ${#filtered[@]} -eq 0 ]]; then
      echo "  (no matches for \"$filter\")"
    else
      local i=1
      for q in "${filtered[@]}"; do
        printf "  [%2d]  %s\n" "$i" "$q"
        (( i++ ))
      done
    fi

    echo "----------------------------------------"
    if [[ -n "$filter" ]]; then
      echo "  Active filter: \"$filter\"  (leave blank to clear)"
    fi
    printf "  Enter number, or type keyword to filter (Ctrl-C to quit): "
    read -r selection

    # Blank input clears the filter and redraws.
    if [[ -z "$selection" ]]; then
      filter=""
      continue
    fi

    # Pure integer → pick from the filtered list.
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
      local idx=$(( selection - 1 ))
      if [[ $idx -lt 0 || $idx -ge ${#filtered[@]} ]]; then
        echo "  Invalid selection. Try again."
        sleep 1
        continue
      fi
      local chosen="${filtered[$idx]}"
      echo
      echo "  Selected: $chosen"
      echo
      run_question "$chosen"
      return
    fi

    # Non-integer → treat as a new filter string.
    filter="$selection"
  done
}

# ---------------------------------------------------------------------------
# Entry point — CLI mode if arguments given, interactive UI otherwise.
# ---------------------------------------------------------------------------
if [[ $# -ge 1 ]]; then
  # CLI mode: resolve the supplied name and run immediately.
  input="$*"
  resolved="$(resolve_question_dir "$input")" || {
    echo "ERROR: Question directory not found for: $input" >&2
    echo "Available questions:" >&2
    get_questions | sed 's/^/  /' >&2
    exit 1
  }
  run_question "$resolved"
else
  # No arguments → launch the interactive menu.
  interactive_menu
fi
