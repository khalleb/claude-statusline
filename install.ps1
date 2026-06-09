#!/usr/bin/env pwsh
# Instalador do Claude Code Status Line — PowerShell (Windows)
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
#   # ou, dentro do PowerShell:
#   .\install.ps1

$ErrorActionPreference = 'Stop'

# Diretório onde este script está (funciona como arquivo .ps1)
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }

$ClaudeDir = Join-Path $HOME '.claude'
$Target    = Join-Path $ClaudeDir 'statusline.sh'
$Settings  = Join-Path $ClaudeDir 'settings.json'
$Source    = Join-Path $ScriptDir 'statusline.sh'

Write-Host "=== Claude Code Status Line - Instalador (PowerShell) ==="
Write-Host ""

# ── Verificações de dependência ────────────────────────────────────────────────
if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
    Write-Host "ERRO: jq nao encontrado." -ForegroundColor Red
    Write-Host ""
    Write-Host "Instale com uma das opcoes abaixo e tente novamente:"
    Write-Host "  winget install jqlang.jq"
    Write-Host "  scoop install jq"
    Write-Host "  choco install jq"
    exit 1
}
Write-Host "[OK] jq $(jq --version)" -ForegroundColor Green

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[AVISO] git nao encontrado - branch e dirty flag nao serao exibidos" -ForegroundColor Yellow
}

# statusline.sh roda sob bash (Git Bash) mesmo quando o Claude Code e iniciado pelo PowerShell
if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
    Write-Host "[AVISO] bash nao encontrado - instale o Git for Windows (Git Bash) para o statusline.sh executar" -ForegroundColor Yellow
}

# ── Cópia dos scripts ─────────────────────────────────────────────────────────
if (-not (Test-Path $Source)) {
    Write-Host "ERRO: statusline.sh nao encontrado em: $Source" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

# Copia removendo CR (\r) para garantir LF — assim o statusline.sh roda tanto no
# Git Bash quanto no WSL/Linux sem quebrar por causa de CRLF (ex.: core.autocrlf).
# Le/escreve como UTF-8 sem BOM para preservar os simbolos Unicode do script.
$utf8NoBomSh = New-Object System.Text.UTF8Encoding $false

$scriptText = [System.IO.File]::ReadAllText($Source)
$scriptText = $scriptText.Replace("`r", "")
[System.IO.File]::WriteAllText($Target, $scriptText, $utf8NoBomSh)
Write-Host "[OK] Instalado em: $Target (LF, UTF-8)" -ForegroundColor Green

$UpdateSource = Join-Path $ScriptDir 'update.sh'
$UpdateTarget = Join-Path $ClaudeDir 'statusline-update.sh'
if (Test-Path $UpdateSource) {
    $updateText = [System.IO.File]::ReadAllText($UpdateSource)
    $updateText = $updateText.Replace("`r", "")
    [System.IO.File]::WriteAllText($UpdateTarget, $updateText, $utf8NoBomSh)
    Write-Host "[OK] Updater instalado em: $UpdateTarget (LF, UTF-8)" -ForegroundColor Green
}

# ── Configuração do settings.json ─────────────────────────────────────────────
Write-Host ""
Write-Host "==> Configuracao necessaria em: $Settings"
Write-Host ""
Write-Host 'Adicione a chave "statusLine" no seu ~/.claude/settings.json:'
Write-Host ''
Write-Host '{'
Write-Host '  "statusLine": {'
Write-Host '    "type": "command",'
Write-Host '    "command": "~/.claude/statusline.sh",'
Write-Host '    "timeout": 10'
Write-Host '  }'
Write-Host '}'
Write-Host ''

# Objeto statusLine a ser inserido (ordenado para gerar JSON legível)
$statusLine = [ordered]@{
    type    = 'command'
    command = '~/.claude/statusline.sh'
    timeout = 10
}

# Escreve JSON em UTF-8 sem BOM (alguns parsers nao gostam de BOM)
function Write-JsonNoBom([string]$Path, [object]$Object) {
    $content = $Object | ConvertTo-Json -Depth 20
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $content, $utf8NoBom)
}

if (Test-Path $Settings) {
    $json = Get-Content $Settings -Raw | ConvertFrom-Json

    if ($json.PSObject.Properties.Name -contains 'statusLine') {
        Write-Host "[INFO] statusLine ja configurado em settings.json - nenhuma alteracao feita." -ForegroundColor Cyan
    }
    else {
        $answer = Read-Host "Configurar settings.json automaticamente? (s/N)"
        if ($answer -match '^[Ss]$') {
            $json | Add-Member -NotePropertyName 'statusLine' -NotePropertyValue $statusLine -Force
            Write-JsonNoBom -Path $Settings -Object $json
            Write-Host "[OK] settings.json atualizado!" -ForegroundColor Green
        }
        else {
            Write-Host "[INFO] Edite manualmente o settings.json para ativar." -ForegroundColor Cyan
        }
    }
}
else {
    $answer = Read-Host "settings.json nao existe. Criar automaticamente? (s/N)"
    if ($answer -match '^[Ss]$') {
        $new = [ordered]@{ statusLine = $statusLine }
        Write-JsonNoBom -Path $Settings -Object $new
        Write-Host "[OK] settings.json criado em: $Settings" -ForegroundColor Green
    }
    else {
        Write-Host "[INFO] $Settings nao encontrado - crie-o com o conteudo acima." -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "Instalacao concluida! Reinicie o Claude Code para ativar o status line." -ForegroundColor Green
Write-Host ""
Write-Host "Variaveis de ambiente opcionais (defina em ~/.claude/settings.json, chave 'env'):"
Write-Host "  CLAUDE_STATUSLINE_ASCII=1                            - modo ASCII puro (sem Unicode)"
Write-Host "  CLAUDE_STATUSLINE_NERDFONT=1                       - icones Nerd Font"
Write-Host "  CLAUDE_STATUSLINE_GIT=1                            - linha 2: branch git + pasta"
Write-Host "  CLAUDE_STATUSLINE_PWD=1                            - linha 2: caminho completo"
Write-Host "  CLAUDE_STATUSLINE_COST=1                           - custo da sessao + linhas alteradas"
Write-Host "  CLAUDE_STATUSLINE_NOUPDATE=1                       - desativa verificacao de atualizacao"
Write-Host "  CLAUDE_STATUSLINE_UPDATE_MODE=prompt|auto|reminder - modo de atualizacao (padrao: prompt)"
Write-Host ""
Write-Host "Para atualizar no futuro:"
Write-Host "  bash ~/.claude/statusline-update.sh"
