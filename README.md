# claude-statusline

A lightweight status bar for [Claude Code](https://claude.ai/code) running in **Git Bash or PowerShell on Windows** (and in **WSL/Linux**).

Displays model, context usage, current session limit, and weekly session limit — all in one line, updated after every response. Optionally shows the current git branch and folder on a second line.

> 📖 [Leia em Português](README.pt-BR.md)

---

## Preview

**Git Bash**
![Git Bash preview](docs/preview-gitbash.png)

**PowerShell**
![PowerShell preview](docs/preview-powershell.png)

```
 Sonnet 4.6 (200K context) │  ███░░░░░░░░░░░░░░░░░ 16% │ 5h ██░░░░░░░░ 31% ↺ 2h 33m │ 7d ↺ 2d │ $0.03 +12 -4
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
| `$0.03 +12 -4` | Session cost + lines added/removed (requires `CLAUDE_STATUSLINE_COST=1`) |
| `↑ 1.2.0` | Update available (clickable link in supported terminals) |

**Line 2 — optional (`CLAUDE_STATUSLINE_GIT=1`, `CLAUDE_STATUSLINE_PWD=1` or `CLAUDE_STATUSLINE_ACCOUNT=1`):**

| Segment | Description |
|---------|-------------|
| ` master` | Current git branch (`*` suffix if there are uncommitted changes) |
| ` my-project` | Folder name (default) or full path with `CLAUDE_STATUSLINE_PWD=1` |
| ` Acme Corp` | Logged-in account — organization name, or e-mail as fallback (requires `CLAUDE_STATUSLINE_ACCOUNT=1`) |

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

> **Using PowerShell?** Claude Code launches the status line through `bash`, so **Git Bash is required even when you start Claude Code from PowerShell**. The PowerShell installer (`install.ps1`) only copies the script and configures `settings.json` — the script itself always runs under `bash`.

---

## Installation

**1. Clone the repository:**
```bash
git clone https://github.com/khalleb/claude-statusline.git
cd claude-statusline
```

**2. Run the installer** — pick the one for your shell:

**Git Bash / WSL / Linux:**
```bash
bash install.sh
```

**PowerShell (Windows):**
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Both installers:
- Check that `jq` is available
- Copy `statusline.sh`, `statusline-update.sh`, and `statusline-config.sh` to `~/.claude/`
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

## Configuration

There are three ways to configure claude-statusline:

### 1. `/statusline` command (inside Claude Code)

Type `/statusline` in any Claude Code session to open the interactive configuration menu:

```
  [X] 1  nerdfont     Ícones Nerd Font (CaskaydiaCove NF)
  [X] 2  git          Linha 2: branch git + pasta
  [ ] 3  pwd          Linha 2: caminho completo
  [ ] 4  account      Linha 2: conta logada
  [X] 5  cost         Custo da sessão na linha 1
  [ ] 6  ascii        Modo ASCII puro
  [ ] 7  noupdate     Sem verificação de update
  [prompt] 8  update-mode  Modo de atualização
  [1d]     9  update-freq  Frequência de verificação

  ──────────────────────────────────────────────────
  Digite o número para alternar  •  ex: 3  ou  1 5
  "8 auto" para update-mode  •  "9 7" para 7 dias
  "q" para sair
```

Type a number to toggle it. Type `q` to exit.

### 2. Interactive TUI (terminal)

Run directly in your terminal for arrow-key navigation:

```bash
bash ~/.claude/statusline-config.sh
```

- **↑↓** to navigate
- **Space / Enter** to toggle
- **s** to save
- **q** to exit without saving

### 3. Edit `~/.claude/settings.json` manually

Add variables under the `env` key:

```json
{
  "env": {
    "CLAUDE_STATUSLINE_NERDFONT": "1",
    "CLAUDE_STATUSLINE_GIT": "1"
  }
}
```

> **Why not `~/.bashrc`?** Variables in `~/.bashrc` are only loaded by Git Bash. If you launch Claude Code from PowerShell or another shell, those variables won't be set and features won't appear.

---

## Environment Variables

| Variable | Value | Effect |
|----------|-------|--------|
| `CLAUDE_STATUSLINE_NERDFONT` | `1` | Enable Nerd Font icons (requires CaskaydiaCove NF or JetBrainsMono NF) |
| `CLAUDE_STATUSLINE_GIT` | `1` | Show git branch and folder name on line 2 |
| `CLAUDE_STATUSLINE_PWD` | `1` | Line 2: show the full current path instead of just the folder name (`$HOME` shown as `~`) |
| `CLAUDE_STATUSLINE_COST` | `1` | Line 1: show session cost (`$X.XX`) + lines added/removed (`+N -N`) |
| `CLAUDE_STATUSLINE_ACCOUNT` | `1` | Line 2: show the logged-in account (organization name, or e-mail as fallback) — useful when switching between multiple Claude accounts |
| `CLAUDE_STATUSLINE_ASCII` | `1` | Force plain ASCII mode (no Unicode, no colors) |
| `CLAUDE_STATUSLINE_DEBUG` | `1` | Write raw JSON to `/tmp/claude-sl-debug.json` for inspection |
| `CLAUDE_STATUSLINE_NOUPDATE` | `1` | Disable the GitHub update check entirely |
| `CLAUDE_STATUSLINE_UPDATE_MODE` | `prompt` \| `auto` \| `reminder` \| `disabled` | Controls updater behavior (default: `prompt`) |
| `CLAUDE_STATUSLINE_UPDATE_FREQ` | number | Check frequency in days (default: `1`) |

The `output_style.name` is shown automatically on line 1 when set and not `"default"`. No extra variable needed.

The account segment is not part of the JSON Claude Code sends — it is read from `.claude.json` (`.oauthAccount`), which `/login` keeps up to date. `CLAUDE_CONFIG_DIR` is respected for multi-profile setups, and the value is cached for 30 seconds. Personal (Pro/Max) accounts have an auto-generated organization name like `you@mail.com's Organization` — in that case the e-mail is shown instead; real Team/Enterprise organizations show their name.

---

## Update Notifications

When a new release is available, line 1 shows a `↑ x.y.z` notice (clickable link in Windows Terminal, VSCode, iTerm2, Kitty, WezTerm). To update, run:

```bash
bash ~/.claude/statusline-update.sh
```

The updater shows the **changelog for all skipped versions**, downloads the new script from the GitHub release tag, backs up your current install to `.bak`, and updates itself too.

| Mode | Behavior |
|------|----------|
| `prompt` (default) | Asks "Update to vX.Y.Z? [Y/n]" |
| `auto` | Updates silently — also triggered automatically from the status line |
| `reminder` | Only prints the update command, does nothing |
| `disabled` | Exits immediately |

The background version check runs on the configured frequency (cached in `/tmp/claude-statusline-update-cache`) and requires `curl`. A lock file (`/tmp/claude-statusline-update.lock`) prevents concurrent updates.

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

Finally, enable Nerd Font mode — add to `~/.claude/settings.json`:
```json
{
  "env": {
    "CLAUDE_STATUSLINE_NERDFONT": "1"
  }
}
```

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
workspace.current_dir                   ← used by CLAUDE_STATUSLINE_GIT / CLAUDE_STATUSLINE_PWD
cost.total_cost_usd                     ← used by CLAUDE_STATUSLINE_COST
cost.total_lines_added                  ← used by CLAUDE_STATUSLINE_COST
cost.total_lines_removed                ← used by CLAUDE_STATUSLINE_COST
output_style.name                       ← shown on line 1 automatically when not "default"
```

> **Note:** Rate limit data (`5h` / `7d`) is only available on Claude Pro and Max plans. The status line hides those segments gracefully when unavailable. The `cost.*` fields and `output_style.name` default to `0`/empty when absent, so those segments degrade gracefully too.

---

## Testing

```bash
bash test-mock.sh
```

Runs 10 scenarios: normal, warning (75%), danger (92%), no rate limits, fresh session, output style, session cost, git branch line, update notification, and ASCII mode.

---

## Project Structure

```
claude-statusline/
├── statusline.sh          # Main script — called by Claude Code on every response
├── update.sh              # Updater — run to install a new version interactively
├── statusline-config.sh   # Interactive TUI configurator (arrow keys + space)
├── install.sh             # Installer (Git Bash / WSL / Linux)
├── install.ps1            # Installer (PowerShell on Windows)
├── test-mock.sh           # Test suite with mock JSON payloads
├── CLAUDE.md              # Guidance for Claude Code when working in this repo
├── README.md              # English documentation
└── README.pt-BR.md        # Portuguese documentation
```

After installation, `~/.claude/` contains:

```
~/.claude/
├── statusline.sh          # Main script (copy)
├── statusline-update.sh   # Updater (copy)
├── statusline-config.sh   # TUI configurator (copy)
└── settings.json          # Claude Code settings (statusLine + env vars)
```

---

## Differences from the Original

This project is inspired by [claude-code-statusline](https://github.com/KCChien/claude-code-statusline) by KC Chien. Key differences:

| Feature | Original | This project |
|---------|----------|--------------|
| Platform | macOS | **Git Bash / PowerShell (Windows) and WSL/Linux** |
| `stat` command | BSD (`-f %m`) | GNU (`-c %Y`) |
| CRLF handling | Not needed | `tr -d '\r'` on jq output |
| True-color detection | `COLORTERM` | `COLORTERM` + `WT_SESSION` |
| Path handling | Unix only | Converts `C:\path` → `/c/path` |
| Rate limit reset | Not implemented | `resets_at` Unix timestamp |
| Layout | 2 lines | **1 line + optional 2nd line** |
| Update notifications | None | GitHub release check + auto-updater |
| Configuration UI | None | `/statusline` command + TUI script |

---

## License

MIT — see [LICENSE](LICENSE).

Inspired by [claude-code-statusline](https://github.com/KCChien/claude-code-statusline) © KC Chien.
