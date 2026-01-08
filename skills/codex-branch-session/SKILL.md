---
name: codex-branch-session
description: Branch a Codex CLI conversation by capturing a /compact summary, opening a new terminal tab in the same working directory, and seeding the new Codex session with the same context. Use when the user asks to fork/branch a Codex chat, start a parallel session from the current point, or open a new terminal tab with the same context.
---

# Codex Branch Session

## Overview

Create a "branch" of the current Codex conversation by summarizing the current context and opening a new terminal tab that starts Codex in the same directory, ready to paste the summary.

## Workflow

### 1) Collect runtime details

Defaults for this environment (use without asking unless the user requests otherwise):
- Terminal app: Terminal.app
- Codex command: `cxx`
- Auto-copy + auto-paste summary: yes

Only ask if the user explicitly wants different settings or if a command fails due to missing permissions.

### 2) Generate a compact summary

In the current session, run the native `/compact` slash command and capture the summary text. Save it to a temporary file so it can be copied to the clipboard and reused.

Example (adjust path as needed):
```bash
summary_file="/tmp/codex-compact-summary.txt"
cat <<'SUMMARY' > "$summary_file"
<Paste /compact summary here>
SUMMARY
```

### 3) Open a new terminal tab and start Codex

Use the helper script to open a new tab in the same terminal window and start Codex from the same working directory. The script copies the summary to clipboard and auto-pastes it into the new session by default.

```bash
scripts/branch_codex.sh \
  --terminal terminal \
  --cwd "$(pwd)" \
  --codex-cmd "cxx" \
  --summary-file "$summary_file"
```

Supported terminals: `terminal` (Terminal.app), `iterm` (iTerm2).

To disable auto-paste and show the prompt instead:
```bash
scripts/branch_codex.sh \
  --terminal terminal \
  --cwd "$(pwd)" \
  --codex-cmd "cxx" \
  --summary-file "$summary_file" \
  --no-auto-paste
```

### 4) Seed the new session

If auto-paste is enabled, confirm the new session acknowledges the context. If it does not, re-paste or provide a shorter summary.

## Fallbacks and Limits

- There is no native "true branching" of context in Codex; this workflow uses `/compact` as a best-effort snapshot.
- Auto-paste uses System Events and may require Accessibility permissions for the terminal app. If AppleScript or accessibility permissions are blocked, instruct the user to open a new tab manually and run:
  ```bash
  cd "<same-directory>" && codex
  ```
  Then paste the summary.
- If the user’s terminal is not Terminal.app or iTerm2, skip the script and do the manual fallback.

## Resources

### scripts/
- `scripts/branch_codex.sh` opens a new tab (Terminal.app or iTerm2), runs Codex in the same directory, copies the summary to clipboard, and can auto-paste it into the new session.
