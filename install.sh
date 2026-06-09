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

if [[ -f "$SETTINGS" ]]; then
  if grep -q '"statusLine"' "$SETTINGS" 2>/dev/null; then
    echo "[INFO] statusLine já configurado em settings.json — nenhuma alteração feita."
  else
    echo "Configurar settings.json automaticamente? (s/N)"
    read -r _answer
    if [[ "$_answer" =~ ^[Ss]$ ]]; then
      jq '. + {
        "statusLine": {
          "type": "command",
          "command": "~/.claude/statusline.sh",
          "timeout": 10
        }
      }' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"
      echo "[OK] settings.json atualizado!"
    else
      echo "[INFO] Edite manualmente o settings.json para ativar."
    fi
  fi
else
  echo "[INFO] $SETTINGS não encontrado — crie-o com o conteúdo acima."
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
echo "  CLAUDE_STATUSLINE_NOUPDATE=1                       — desativa verificação de atualização"
echo "  CLAUDE_STATUSLINE_UPDATE_MODE=prompt|auto|reminder — modo de atualização (padrão: prompt)"
echo ""
echo "Para atualizar no futuro:"
echo "  bash ~/.claude/statusline-update.sh"
