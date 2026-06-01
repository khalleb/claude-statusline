# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Does

A single-line status bar for Claude Code running in **Git Bash on Windows**. Claude Code calls `statusline.sh` via its `statusLine` hook after every response, piping session state as JSON to stdin. The script outputs two lines (second is intentionally empty); Claude Code renders the first as the status bar.

## Running Tests

```bash
# Run all mock scenarios (requires jq in PATH)
bash test-mock.sh

# Run with Nerd Font mode
CLAUDE_STATUSLINE_NERDFONT=1 bash test-mock.sh

# Run with ASCII fallback
CLAUDE_STATUSLINE_ASCII=1 bash test-mock.sh

# Test a single JSON payload manually
echo '{"model":{"display_name":"Sonnet 4.6"},"context_window":{"used_percentage":42,"context_window_size":200000},"rate_limits":{"five_hour":{"used_percentage":30,"resets_at":1780331400},"seven_day":{"used_percentage":9,"resets_at":1780495200}}}' | bash statusline.sh

# Inspect what Claude Code is actually sending at runtime
CLAUDE_STATUSLINE_DEBUG=1 claude   # then ask anything; JSON lands in /tmp/claude-sl-debug.json
cat /tmp/claude-sl-debug.json | jq .
```

## Deploying Changes

The installed script at `~/.claude/statusline.sh` is a **copy** — always copy after editing:

```bash
cp statusline.sh ~/.claude/statusline.sh
```

## Architecture

Everything runs in a single file: `statusline.sh`. Execution order:

1. **Feature flags** — `FORCE_ASCII`, `FORCE_NERDFONT` from env vars
2. **True-color detection** — checks `COLORTERM` and `WT_SESSION` (Windows Terminal)
3. **Symbol set selection** — three tiers: ASCII / Unicode default / Nerd Font
4. **JSON parse** — single `jq` call reads all fields at once; `tr -d '\r'` strips Windows CRLF from jq.exe output; sentinel `"END"` prevents `$()` from swallowing trailing newlines
5. **Reset time calculation** — `resets_at` fields are Unix timestamps; remaining seconds = `resets_at - $(date +%s)`
6. **`make_bar <pct> <width>`** — writes result to `BAR_RESULT`; renders a true-color gradient (20-entry RGB arrays), ANSI fallback, or ASCII `[###---]`
7. **`format_reset <secs>`** — converts seconds to `Xd`, `Xd Yh`, `Xh`, `Xh Ym`, or `Xm`; omits trailing zero units
8. **`pct_color <pct>`** — returns colored percentage string (green/yellow/red thresholds: 70/90)
9. **Line assembly** — builds `line1` by appending segments; `line2` is always empty (kept for Claude Code's two-line protocol)

## Windows-Specific Behaviour

- `jq` from winget outputs CRLF — always pipe through `tr -d '\r'`
- `stat -c %Y` (GNU coreutils in Git Bash) — not BSD `-f %m`
- Windows paths like `C:\path` must be converted to `/c/path` for git commands (see path normalisation block)
- True-color is detected via `$WT_SESSION` (Windows Terminal sets this) in addition to the standard `$COLORTERM`

## Key JSON Fields (from Claude Code)

```
context_window.used_percentage          integer 0–100
context_window.context_window_size      integer (e.g. 200000, 1000000)
rate_limits.five_hour.used_percentage   float; -1 when unavailable (non-Pro plans)
rate_limits.five_hour.resets_at         Unix timestamp in seconds
rate_limits.seven_day.used_percentage   float; -1 when unavailable
rate_limits.seven_day.resets_at         Unix timestamp in seconds
```

Rate limit fields are only present on Claude Pro/Max plans. The script hides those segments when `used_percentage` is -1.
