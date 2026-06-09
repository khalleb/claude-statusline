# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Does

A status bar for Claude Code running in **Git Bash or PowerShell on Windows**, and also in **WSL/Linux**. Claude Code calls `statusline.sh` via its `statusLine` hook after every response, piping session state as JSON to stdin. The script outputs two lines; Claude Code renders them in the status area.

- **Line 1** (always): model + optional output style + context bar + 5h session bar + reset times + optional session cost/lines (`CLAUDE_STATUSLINE_COST=1`)
- **Line 2** (optional): git branch (`CLAUDE_STATUSLINE_GIT=1`) + current folder name, or full path (`CLAUDE_STATUSLINE_PWD=1`)

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
| `CLAUDE_STATUSLINE_PWD=1` | Line 2: full current path instead of just the folder name (`$HOME` shown as `~`) |
| `CLAUDE_STATUSLINE_COST=1` | Line 1: session cost (`$X.XX`) + lines added/removed (`+N -N`) |
| `CLAUDE_STATUSLINE_ASCII=1` | Plain ASCII mode, no Unicode, no colors |
| `CLAUDE_STATUSLINE_DEBUG=1` | Writes raw JSON to `/tmp/claude-sl-debug.json` |
| `CLAUDE_STATUSLINE_NOUPDATE=1` | Disables the GitHub update check entirely |
| `CLAUDE_STATUSLINE_UPDATE_MODE=prompt\|auto\|reminder` | Controls `statusline-update.sh` behavior (default: `prompt`) |

Output style (`output_style.name`) is shown automatically on line 1 — only when it is set and not `default`. No flag needed.

When a new GitHub release is available, `↑ x.y.z` appears on line 1. To update, run `bash ~/.claude/statusline-update.sh` — it fetches the new script from the release tag, backs up the old file, and updates itself. Behavior is controlled by `CLAUDE_STATUSLINE_UPDATE_MODE` (prompt/auto/reminder/disabled).

## Architecture

Everything runs in a single file: `statusline.sh`. Execution order:

1. **Feature flags** — `FORCE_ASCII`, `FORCE_NERDFONT`, `FORCE_GIT`, `FORCE_PWD`, `FORCE_COST`, `FORCE_NOUPDATE` from env vars
2. **True-color detection** — checks `COLORTERM` and `WT_SESSION` (Windows Terminal)
3. **Symbol set selection** — three tiers: ASCII / Unicode default / Nerd Font
4. **JSON parse** — single `jq` call reads all fields at once; `tr -d '\r'` strips Windows CRLF from jq.exe output; sentinel `"END"` prevents `$()` from swallowing trailing newlines
5. **Reset time calculation** — `resets_at` fields are Unix timestamps; remaining seconds = `resets_at - $(date +%s)`
6. **`make_bar <pct> <width>`** — writes result to `BAR_RESULT`; renders a true-color gradient (20-entry RGB arrays), ANSI fallback, or ASCII `[###---]`
7. **`format_reset <secs>`** — converts seconds to `Xd`, `Xd Yh`, `Xh`, `Xh Ym`, or `Xm`; omits trailing zero units
8. **`pct_color <pct>`** — returns colored percentage string (green/yellow/red thresholds: 70/90)
9. **Line 1 assembly** — model + output style (when non-`default`) + context bar + 5h bar + reset times + session cost/lines (when `FORCE_COST=1`) + update notice (when newer release exists on GitHub); cost is parsed as integer cents (`total_cost_usd * 100 | floor`) to avoid float math in bash
  - **Update check** — `VERSION="x.y.z"` constant in the script; once per day (cache at `/tmp/claude-statusline-update-cache`, TTL 86400s) a background `curl` fetches the latest GitHub release tag; if `latest != current`, appends `↑ x.y.z` to line 1; requires `curl`; disabled by `FORCE_NOUPDATE=1`
10. **Line 2 assembly** — when `FORCE_GIT=1` or `FORCE_PWD=1`; branch (gated by `FORCE_GIT`) from `worktree.branch` JSON field, falls back to `git rev-parse --abbrev-ref HEAD` when empty, dirty flag `*` via git diff with 5s cache; path shows full normalised dir (`FORCE_PWD`) or just the folder basename

## Windows-Specific Behaviour

- `jq` from winget outputs CRLF — always pipe through `tr -d '\r'`
- `stat -c %Y` (GNU coreutils in Git Bash) — not BSD `-f %m`
- Windows paths like `C:\path` must be converted to `/c/path` for git commands (see path normalisation block)
- True-color is detected via `$WT_SESSION` (Windows Terminal sets this) in addition to the standard `$COLORTERM`
- `worktree.branch` from Claude Code JSON is often empty — always add `git rev-parse` fallback
- Shell scripts are forced to **LF** line endings via `.gitattributes` (`*.sh text eol=lf`) so they run under both Git Bash and WSL/Linux; `install.sh` also strips `\r` (`tr -d '\r'`) when copying, so a CRLF source never breaks the installed copy

## Key JSON Fields (from Claude Code)

```
context_window.used_percentage          integer 0–100
context_window.context_window_size      integer (e.g. 200000, 1000000)
rate_limits.five_hour.used_percentage   float; -1 when unavailable (non-Pro plans)
rate_limits.five_hour.resets_at         Unix timestamp in seconds
rate_limits.seven_day.used_percentage   float; -1 when unavailable
rate_limits.seven_day.resets_at         Unix timestamp in seconds
worktree.branch                         string; often empty — use git fallback
workspace.current_dir                   Windows path e.g. C:\repositorios\project (or /mnt/... on WSL)
cost.total_cost_usd                     float; session cost in USD (shown with CLAUDE_STATUSLINE_COST=1)
cost.total_lines_added                  integer; lines added this session
cost.total_lines_removed                integer; lines removed this session
output_style.name                       string; current output style — shown on line 1 when not "default"
```

Rate limit fields are only present on Claude Pro/Max plans. The script hides those segments when `used_percentage` is -1. The `cost.*` fields default to `0` (and `output_style.name` to empty) when absent, so those segments degrade gracefully.
