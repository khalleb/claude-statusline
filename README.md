# claude-statusline

A lightweight status bar for [Claude Code](https://claude.ai/code) running in **Git Bash on Windows**.

Displays model, context usage, current session limit, and weekly session limit — all in one line, updated after every response. Optionally shows the current git branch and folder on a second line.

> 📖 [Leia em Português](README.pt-BR.md)

---

## Preview

```
 Sonnet 4.6 (200K context) │  ███░░░░░░░░░░░░░░░░░ 16% │ 5h ██░░░░░░░░ 31% ↺ 2h 33m │ 7d ↺ 2d
 master │  my-project
```

**Line 1 — always visible:**

| Segment | Description |
|---------|-------------|
| ` Sonnet 4.6` | Current model name |
| `(200K context)` | Context window size |
| `███░░░ 16%` | Context window usage bar |
| `5h ██░░░ 31% ↺ 2h 33m` | 5-hour session usage bar + time until reset |
| `7d ↺ 2d` | Time until weekly session reset |

**Line 2 — optional (`CLAUDE_STATUSLINE_GIT=1`):**

| Segment | Description |
|---------|-------------|
| ` master` | Current git branch (`*` suffix if there are uncommitted changes) |
| ` my-project` | Name of the folder where Claude Code was started |

**Color coding:**
- 🟢 Green — 0–69%
- 🟡 Yellow — 70–89%
- 🔴 Red — 90–100%

---

## Requirements

| Tool | Purpose | Install |
|------|---------|---------|
| [Git Bash](https://git-scm.com/downloads) | Shell runtime | Comes with Git for Windows |
| [jq](https://jqlang.github.io/jq/) | JSON parsing | `winget install jqlang.jq` |
| [CaskaydiaCove NF](https://www.nerdfonts.com/) *(optional)* | Nerd Font icons | See [Font Setup](#font-setup-optional) |

---

## Installation

**1. Clone the repository:**
```bash
git clone https://github.com/YOUR_USERNAME/claude-statusline.git
cd claude-statusline
```

**2. Run the installer:**
```bash
bash install.sh
```

The installer will:
- Check that `jq` is available
- Copy `statusline.sh` to `~/.claude/statusline.sh`
- Offer to update `~/.claude/settings.json` automatically

**3. Add `statusLine` to `~/.claude/settings.json`** (if not done automatically):
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "timeout": 10
  }
}
```

**4. Restart Claude Code.**

---

## Font Setup (optional)

For Nerd Font icons, install **CaskaydiaCove NF**:

```powershell
# Download and install (run in PowerShell)
$url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip"
$zip = "$env:TEMP\CascadiaCode-NF.zip"
$out = "$env:TEMP\CascadiaCode-NF"
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
Expand-Archive -Path $zip -DestinationPath $out -Force
$fontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
New-Item -ItemType Directory -Force -Path $fontsDir | Out-Null
Get-ChildItem "$out\*.ttf" | ForEach-Object {
    Copy-Item $_.FullName -Destination $fontsDir -Force
    New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" `
        -Name "$($_.BaseName) (TrueType)" -Value "$fontsDir\$($_.Name)" -PropertyType String -Force | Out-Null
}
```

Then set the font in **Windows Terminal** (`settings.json`):
```json
"profiles": {
  "defaults": {
    "font": { "face": "CaskaydiaCove NF", "size": 11 }
  }
}
```

Finally, enable Nerd Font mode in `~/.bashrc`:
```bash
export CLAUDE_STATUSLINE_NERDFONT=1
```

---

## Environment Variables

| Variable | Value | Effect |
|----------|-------|--------|
| `CLAUDE_STATUSLINE_NERDFONT` | `1` | Enable Nerd Font icons (requires CaskaydiaCove NF) |
| `CLAUDE_STATUSLINE_GIT` | `1` | Show git branch and folder name on line 2 |
| `CLAUDE_STATUSLINE_ASCII` | `1` | Force plain ASCII mode (no Unicode, no colors) |
| `CLAUDE_STATUSLINE_DEBUG` | `1` | Write raw JSON to `/tmp/claude-sl-debug.json` for inspection |

---

## How It Works

Claude Code calls `statusline.sh` after every response, sending session state as JSON via stdin. The script:

1. Reads the JSON with a **single `jq` call** (< 5ms)
2. Builds gradient progress bars with true-color ANSI escapes
3. Calculates reset times from `resets_at` Unix timestamps
4. Outputs two lines — Claude Code displays them in the status area

### JSON fields used

```
model.display_name
context_window.used_percentage
context_window.context_window_size
rate_limits.five_hour.used_percentage
rate_limits.five_hour.resets_at         ← Unix timestamp (seconds)
rate_limits.seven_day.used_percentage
rate_limits.seven_day.resets_at         ← Unix timestamp (seconds)
worktree.branch                         ← used by CLAUDE_STATUSLINE_GIT (falls back to git command)
workspace.current_dir                   ← used by CLAUDE_STATUSLINE_GIT
```

> **Note:** Rate limit data (`5h` / `7d`) is only available on Claude Pro and Max plans. The status line hides those segments gracefully when unavailable.

---

## Testing

```bash
bash test-mock.sh
```

Runs 5 scenarios: normal, warning (75%), danger (92%), no rate limits, and fresh session.

---

## Project Structure

```
claude-statusline/
├── statusline.sh     # Main script — called by Claude Code on every response
├── install.sh        # Installer — copies script and configures settings.json
├── test-mock.sh      # Test suite with mock JSON payloads
├── CLAUDE.md         # Guidance for Claude Code when working in this repo
├── README.md         # English documentation
└── README.pt-BR.md   # Portuguese documentation
```

---

## Differences from the Original

This project is inspired by [claude-code-statusline](https://github.com/KCChien/claude-code-statusline) by KC Chien. Key differences:

| Feature | Original | This project |
|---------|----------|--------------|
| Platform | macOS | **Git Bash (Windows)** |
| `stat` command | BSD (`-f %m`) | GNU (`-c %Y`) |
| CRLF handling | Not needed | `tr -d '\r'` on jq output |
| True-color detection | `COLORTERM` | `COLORTERM` + `WT_SESSION` |
| Path handling | Unix only | Converts `C:\path` → `/c/path` |
| Rate limit reset | Not implemented | `resets_at` Unix timestamp |
| Layout | 2 lines | **1 line + optional 2nd line** |

---

## License

MIT — see [LICENSE](LICENSE).

Inspired by [claude-code-statusline](https://github.com/KCChien/claude-code-statusline) © KC Chien.
