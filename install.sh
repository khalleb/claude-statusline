#!/usr/bin/env bash
# Instalador do Claude Code Status Line — Git Bash (Windows)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude/statusline.sh"
SETTINGS="$HOME/.claude/settings.json"

echo "=== Claude Code Status Line — Instalador ==="
echo ""

# ── Verificações de dependência ────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  echo "ERRO: jq não encontrado."
  echo ""
  echo "Instale com o comando adequado ao seu sistema e tente novamente:"
  if   command -v pacman  &>/dev/null; then echo "  sudo pacman -S jq"
  elif command -v apt-get &>/dev/null; then echo "  sudo apt install jq"
  elif command -v dnf     &>/dev/null; then echo "  sudo dnf install jq"
  elif command -v brew    &>/dev/null; then echo "  brew install jq"
  elif command -v scoop   &>/dev/null; then echo "  scoop install jq"
  else
    echo "  winget install jqlang.jq   (Windows)"
    echo "  scoop install jq           (Windows)"
    echo "  choco install jq           (Windows)"
  fi
  exit 1
fi
echo "[OK] jq $(jq --version)"

if ! command -v git &>/dev/null; then
  echo "[AVISO] git não encontrado — branch e dirty flag não serão exibidos"
fi

# ── Cópia dos scripts ──────────────────────────────────────────────────────────
# Remove CR (\r) na cópia para funcionar tanto no Git Bash quanto no WSL/Linux
mkdir -p "$(dirname "$TARGET")"
tr -d '\r' < "$SCRIPT_DIR/statusline.sh" > "$TARGET"
chmod +x "$TARGET"
echo "[OK] Instalado em: $TARGET"

UPDATE_TARGET="$HOME/.claude/statusline-update.sh"
tr -d '\r' < "$SCRIPT_DIR/update.sh" > "$UPDATE_TARGET"
chmod +x "$UPDATE_TARGET"
echo "[OK] Updater instalado em: $UPDATE_TARGET"

CONFIG_TARGET="$HOME/.claude/statusline-config.sh"
tr -d '\r' < "$SCRIPT_DIR/statusline-config.sh" > "$CONFIG_TARGET"
chmod +x "$CONFIG_TARGET"
echo "[OK] Configurador instalado em: $CONFIG_TARGET"

COMMAND_TARGET="$HOME/.claude/commands/statusline-khalleb.md"
mkdir -p "$(dirname "$COMMAND_TARGET")"
tr -d '\r' < "$SCRIPT_DIR/commands/statusline-khalleb.md" > "$COMMAND_TARGET"
echo "[OK] Comando /statusline-khalleb instalado em: $COMMAND_TARGET"

# Remove o comando antigo: chamava-se /statusline e colidia com o comando
# nativo do Claude Code, fazendo aparecer duas entradas no menu.
if [[ -f "$HOME/.claude/commands/statusline.md" ]]; then
  rm -f "$HOME/.claude/commands/statusline.md"
  echo "[OK] Comando antigo /statusline removido (colidia com o nativo)"
fi

# ── Configuração do settings.json ─────────────────────────────────────────────
echo ""
echo "==> Configuração necessária em: $SETTINGS"
echo ""
cat <<'EOF'
Adicione a chave "statusLine" no seu ~/.claude/settings.json:

{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "timeout": 10
  }
}
EOF
echo ""

# Cria o settings.json quando ausente ou vazio — sem isso o jq abaixo falha e a
# instalação termina "com sucesso" mas sem status line configurado.
if [[ ! -s "$SETTINGS" ]]; then
  echo "{}" > "$SETTINGS"
  echo "[INFO] $SETTINGS não existia — criado vazio."
fi

if ! jq -e . "$SETTINGS" >/dev/null 2>&1; then
  echo "[ERRO] $SETTINGS não é um JSON válido — corrija-o e rode o instalador de novo."
  echo "       Nada foi alterado. Use o trecho acima para editar manualmente."
  exit 1
fi

if jq -e 'has("statusLine")' "$SETTINGS" >/dev/null 2>&1; then
  echo "[INFO] statusLine já configurado em settings.json — nenhuma alteração feita."
else
  echo "Configurar settings.json automaticamente? (s/N)"
  read -r _answer
  if [[ "$_answer" =~ ^[Ss]$ ]]; then
    _tmp="$(mktemp)"
    if jq '. + {
      "statusLine": {
        "type": "command",
        "command": "~/.claude/statusline.sh",
        "timeout": 10
      }
    }' "$SETTINGS" > "$_tmp" && [[ -s "$_tmp" ]]; then
      cp "$SETTINGS" "${SETTINGS}.bak"
      mv "$_tmp" "$SETTINGS"
      echo "[OK] settings.json atualizado! (backup em ${SETTINGS}.bak)"
    else
      rm -f "$_tmp"
      echo "[ERRO] Falha ao atualizar $SETTINGS — arquivo original preservado."
      echo "       Adicione a chave statusLine manualmente com o trecho acima."
      exit 1
    fi
  else
    echo "[INFO] Edite manualmente o settings.json para ativar."
  fi
fi

echo ""
echo "Instalação concluída! Reinicie o Claude Code para ativar o status line."
echo ""
echo "Variáveis de ambiente opcionais:"
echo "  CLAUDE_STATUSLINE_ASCII=1      — modo ASCII puro (sem Unicode)"
echo "  CLAUDE_STATUSLINE_NERDFONT=1   — ícones Nerd Font"
echo "  CLAUDE_STATUSLINE_GIT=1                            — linha 2: branch + nome da pasta"
echo "  CLAUDE_STATUSLINE_PWD=1                            — linha 2: caminho completo"
echo "  CLAUDE_STATUSLINE_COST=1                           — custo da sessão + linhas alteradas"
echo "  CLAUDE_STATUSLINE_ACCOUNT=1                        — linha 2: conta logada (org ou e-mail)"
echo "  CLAUDE_STATUSLINE_NOUPDATE=1                       — desativa verificação de atualização"
echo "  CLAUDE_STATUSLINE_UPDATE_MODE=prompt|auto|reminder — modo de atualização (padrão: prompt)"
echo ""
echo "Para atualizar no futuro:"
echo "  bash ~/.claude/statusline-update.sh"
