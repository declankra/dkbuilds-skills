#!/usr/bin/env bash
set -euo pipefail

show_usage() {
  cat <<'USAGE'
Usage:
  branch_codex.sh [--terminal terminal|iterm] [--cwd PATH] [--codex-cmd COMMAND] [--summary-file PATH] [--auto-paste|--no-auto-paste]

Options:
  --terminal     Terminal app to target: terminal or iterm. Auto-detects via TERM_PROGRAM if omitted.
  --cwd          Working directory for the new tab (default: current directory).
  --codex-cmd    Codex CLI command to run (default: cxx).
  --summary-file File containing /compact summary to paste in the new tab (optional).
  --auto-paste   Paste the summary automatically after Codex starts (default: on when --summary-file is set).
  --no-auto-paste Do not auto-paste; print a prompt instead.

Notes:
  - If --summary-file is provided and pbcopy is available, the summary is copied to clipboard.
  - Auto-paste uses System Events and may require Accessibility permissions.
USAGE
}

terminal=""
cwd="$(pwd)"
codex_cmd="cxx"
summary_file=""
auto_paste=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --terminal)
      terminal="$2"
      shift 2
      ;;
    --cwd)
      cwd="$2"
      shift 2
      ;;
    --codex-cmd)
      codex_cmd="$2"
      shift 2
      ;;
    --summary-file)
      summary_file="$2"
      shift 2
      ;;
    --auto-paste)
      auto_paste="yes"
      shift 1
      ;;
    --no-auto-paste)
      auto_paste="no"
      shift 1
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      show_usage
      exit 1
      ;;
  esac
done

if [[ -z "$terminal" ]]; then
  case "${TERM_PROGRAM:-}" in
    Apple_Terminal)
      terminal="terminal"
      ;;
    iTerm.app)
      terminal="iterm"
      ;;
  esac
fi

if [[ -z "$terminal" ]]; then
  echo "Could not detect terminal app. Use --terminal terminal|iterm." >&2
  exit 1
fi

if [[ -n "$summary_file" ]]; then
  if [[ ! -f "$summary_file" ]]; then
    echo "Summary file not found: $summary_file" >&2
    exit 1
  fi
  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "$summary_file"
  fi
  if [[ -z "$auto_paste" ]]; then
    auto_paste="yes"
  fi
else
  auto_paste="no"
fi

escape_osascript() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  echo "$s"
}

cmd="cd $(printf %q "$cwd"); ${codex_cmd}"
if [[ -n "$summary_file" && "$auto_paste" == "no" ]]; then
  cmd="${cmd}; printf '\\n---\\nPaste the /compact summary now (Cmd+V)\\n---\\n'"
fi

cmd_escaped="$(escape_osascript "$cmd")"

if [[ "$terminal" == "terminal" ]]; then
  osascript <<APPLESCRIPT
    tell application "Terminal"
      activate
      if (count of windows) is 0 then
        set newTab to do script "${cmd_escaped}"
      else
        try
          tell application "System Events"
            keystroke "t" using {command down}
          end tell
          delay 0.2
          set newTab to selected tab of front window
          do script "${cmd_escaped}" in newTab
        on error
          tell front window
            set newTab to do script "${cmd_escaped}"
          end tell
        end try
      end if
      try
        set selected tab of front window to newTab
      end try
      activate
    end tell
    if "${auto_paste:-no}" is "yes" then
      delay 1.0
      tell application "System Events"
        keystroke "v" using {command down}
      end tell
    end if
APPLESCRIPT
elif [[ "$terminal" == "iterm" ]]; then
  osascript <<APPLESCRIPT
    tell application "iTerm"
      activate
      if (count of windows) is 0 then
        create window with default profile
      end if
      tell current window
        create tab with default profile
        tell current session
          write text "${cmd_escaped}"
        end tell
      end tell
    end tell
    if "${auto_paste:-no}" is "yes" then
      delay 0.7
      tell application "System Events"
        keystroke "v" using {command down}
      end tell
    end if
APPLESCRIPT
else
  echo "Unsupported terminal: $terminal" >&2
  exit 1
fi
