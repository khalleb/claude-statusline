# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Does

A status bar for Claude Code running in **Git Bash or PowerShell on Windows**. Claude Code calls `statusline.sh` via its `statusLine` hook after every response, piping session state as JSON to stdin. The script outputs two lines; Claude Code renders them in the status area.

- **Line 1** (always): model + context bar + 5h session bar + reset times
- **Line 2** (optional, `CLAUDE_STATUSLINE_GIT=1`): git branch + current folder

## Running Tests

```bash
# Run all mock scenarios (requires jq in PATH)
bash test-mock.sh

# Run with Nerd Font + git line
CLAUDE_STATUSLINE_NERDFONT=1 CLAUDE_STATUSLINE_GIT=1 bash test-mock.sh

# Run with ASCII fallback
CLAUDE_STATUSLINE_ASCII=1 bash test-mock.sh

# Test a single JSON payload manually
echo '{"model":{"display_name":"Sonnet 4.6"},"context_window":{"used_percentage":42,"context_window_size":200000},"rate_limits":{"five_hour":{"used_percentage":30,"resets_at":1780331400},"seven_day":{"used_percentage":9,"resets_at":1780495200}},"worktree":{"branch":"master"},"workspace":{"current_dir":"C:/repositorios/claude-statusline"}}' | bash statusline.sh

# Inspect what Claude Code is actually sending at runtime
CLAUDE_STATUSLINE_DEBUG=1 claude   # then ask anything; JSON lands in /tmp/claude-sl-debug.json
cat /tmp/claude-sl-debug.json | jq .
```

## Deploying Changes

The installed script at `~/.claude/statusline.sh` is a **copy** — always copy after editing:

```bash
cp statusline.sh ~/.claude/statusline.sh
```

## Environment Variables

Set via `~/.claude/settings.json` under the `env` key — this works regardless of shell (Git Bash, PowerShell, etc.). Variables set only in `~/.bashrc` are invisible to Claude Code when launched from PowerShell.

```json
{
  "env": {
    "CLAUDE_STATUSLINE_NERDFONT": "1",
    "CLAUDE_STATUSLINE_GIT": "1"
  }
}
```

| Variable | Effect |
|----------|--------|
| `CLAUDE_STATUSLINE_NERDFONT=1` | Nerd Font icons (requires JetBrainsMono NF or CaskaydiaCove NF) |
| `CLAUDE_STATUSLINE_GIT=1` | Line 2: git branch + folder name |
| `CLAUDE_STATUSLINE_ASCII=1` | Plain ASCII mode, no Unicode, no colors |
| `CLAUDE_STATUSLINE_DEBUG=1` | Writes raw JSON to `/tmp/claude-sl-debug.json` |

## Architecture

Everything runs in a single file: `statusline.sh`. Execution order:

1. **Feature flags** — `FORCE_ASCII`, `FORCE_NERDFONT`, `FORCE_GIT` from env vars
2. **True-color detection** — checks `COLORTERM` and `WT_SESSION` (Windows Terminal)
3. **Symbol set selection** — three tiers: ASCII / Unicode default / Nerd Font
4. **JSON parse** — single `jq` call reads all fields at once; `tr -d '\r'` strips Windows CRLF from jq.exe output; sentinel `"END"` prevents `$()` from swallowing trailing newlines
5. **Reset time calculation** — `resets_at` fields are Unix timestamps; remaining seconds = `resets_at - $(date +%s)`
6. **`make_bar <pct> <width>`** — writes result to `BAR_RESULT`; renders a true-color gradient (20-entry RGB arrays), ANSI fallback, or ASCII `[###---]`
7. **`format_reset <secs>`** — converts seconds to `Xd`, `Xd Yh`, `Xh`, `Xh Ym`, or `Xm`; omits trailing zero units
8. **`pct_color <pct>`** — returns colored percentage string (green/yellow/red thresholds: 70/90)
9. **Line 1 assembly** — model + context bar + 5h bar + reset times
10. **Line 2 assembly** — only when `FORCE_GIT=1`; gets branch from `worktree.branch` JSON field, falls back to `git rev-parse --abbrev-ref HEAD` when empty; dirty flag `*` via git diff with 5s cache

## Windows-Specific Behaviour

- `jq` from winget outputs CRLF — always pipe through `tr -d '\r'`
- `stat -c %Y` (GNU coreutils in Git Bash) — not BSD `-f %m`
- Windows paths like `C:\path` must be converted to `/c/path` for git commands (see path normalisation block)
- True-color is detected via `$WT_SESSION` (Windows Terminal sets this) in addition to the standard `$COLORTERM`
- `worktree.branch` from Claude Code JSON is often empty — always add `git rev-parse` fallback

## Key JSON Fields (from Claude Code)

```
context_window.used_percentage          integer 0–100
context_window.context_window_size      integer (e.g. 200000, 1000000)
rate_limits.five_hour.used_percentage   float; -1 when unavailable (non-Pro plans)
rate_limits.five_hour.resets_at         Unix timestamp in seconds
rate_limits.seven_day.used_percentage   float; -1 when unavailable
rate_limits.seven_day.resets_at         Unix timestamp in seconds
worktree.branch                         string; often empty — use git fallback
workspace.current_dir                   Windows path e.g. C:\repositorios\project
```

Rate limit fields are only present on Claude Pro/Max plans. The script hides those segments when `used_percentage` is -1.
