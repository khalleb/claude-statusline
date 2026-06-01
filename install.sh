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
  echo "Instale com uma das opções abaixo e tente novamente:"
  echo "  winget install jqlang.jq"
  echo "  scoop install jq"
  echo "  choco install jq"
  exit 1
fi
echo "[OK] jq $(jq --version)"

if ! command -v git &>/dev/null; then
  echo "[AVISO] git não encontrado — branch e dirty flag não serão exibidos"
fi

# ── Cópia do script ────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$TARGET")"
cp "$SCRIPT_DIR/statusline.sh" "$TARGET"
chmod +x "$TARGET"
echo "[OK] Instalado em: $TARGET"

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
echo "  CLAUDE_STATUSLINE_POWERLINE=1  — separadores Powerline (requer Nerd Font)"
