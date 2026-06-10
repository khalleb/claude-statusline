#!/usr/bin/env bash
# Claude Code Status Line — Updater
# Uso: bash ~/.claude/statusline-update.sh
# Modo: CLAUDE_STATUSLINE_UPDATE_MODE=prompt|auto|reminder|disabled

TARGET="$HOME/.claude/statusline.sh"
SELF="$HOME/.claude/statusline-update.sh"
REPO="khalleb/claude-statusline"
UPDATE_MODE="${CLAUDE_STATUSLINE_UPDATE_MODE:-prompt}"
_LOCK="/tmp/claude-statusline-update.lock"

# ── Modo disabled ──────────────────────────────────────────────────────────────
[[ "$UPDATE_MODE" == "disabled" ]] && exit 0

# ── Cores ──────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RESET="\033[0m"
  BOLD="\033[1m"
  C_CYAN="\033[36m"
  C_GREEN="\033[32m"
  C_YELLOW="\033[33m"
  C_RED="\033[31m"
  C_DIM="\033[2m"
  RAINBOW=(
    "\033[38;5;196m" "\033[38;5;208m" "\033[38;5;226m"
    "\033[38;5;82m"  "\033[38;5;39m"  "\033[38;5;93m"
    "\033[38;5;201m"
  )
else
  RESET="" BOLD="" C_CYAN="" C_GREEN="" C_YELLOW="" C_RED="" C_DIM=""
  RAINBOW=("" "" "" "" "" "" "")
fi

# ── Lock file — impede execuções simultâneas ───────────────────────────────────
if [[ -d "$_LOCK" ]]; then
  _lmtime=$(stat -c %Y "$_LOCK" 2>/dev/null || echo 0)
  _lnow=$(date +%s)
  if (( (_lnow - _lmtime) > 3600 )); then
    rm -rf "$_LOCK"  # lock obsoleto (> 1h) — remove e continua
  else
    printf "%b\n" "${C_YELLOW}Atualização já em andamento. Tente novamente em instantes.${RESET}"
    exit 0
  fi
fi
if ! mkdir "$_LOCK" 2>/dev/null; then
  printf "%b\n" "${C_YELLOW}Atualização já em andamento. Tente novamente em instantes.${RESET}"
  exit 0
fi
trap 'rm -rf "$_LOCK"' EXIT

# ── Dependências ───────────────────────────────────────────────────────────────
for _dep in curl jq; do
  if ! command -v "$_dep" &>/dev/null; then
    printf "%b\n" "${C_RED}Erro: $_dep não encontrado.${RESET}"
    exit 1
  fi
done

# ── Versão instalada ───────────────────────────────────────────────────────────
if [[ ! -f "$TARGET" ]]; then
  printf "%b\n" "${C_RED}Erro: $TARGET não encontrado. Execute o instalador primeiro.${RESET}"
  exit 1
fi
current=$(grep -m1 '^VERSION=' "$TARGET" 2>/dev/null | tr -d '"' | cut -d= -f2 | tr -d 'v ' || true)
current="${current:-0.0.0}"

# ── Consulta releases do GitHub (lista para changelog multi-versão) ────────────
printf "%b\r" "${C_DIM}Verificando atualizações...${RESET}"
_releases_json=$(curl -sf --max-time 10 \
  "https://api.github.com/repos/${REPO}/releases?per_page=20" 2>/dev/null || true)
printf "\033[2K"

if [[ -z "$_releases_json" ]]; then
  printf "%b\n" "${C_RED}Não foi possível contatar o GitHub. Verifique sua conexão.${RESET}"
  exit 1
fi

_tag=$(printf '%s' "$_releases_json" | jq -r '.[0].tag_name // empty' | tr -d '\r')
latest=$(printf '%s' "$_tag" | tr -d 'v ')

if [[ -z "$latest" ]]; then
  printf "%b\n" "${C_YELLOW}Nenhuma release publicada no GitHub ainda.${RESET}"
  exit 0
fi

# ── Compara versões ────────────────────────────────────────────────────────────
if [[ "$current" == "$latest" ]]; then
  printf "%b\n" "${C_GREEN}✓ Já está na versão mais recente (v${current}).${RESET}"
  exit 0
fi

# ── Atualização disponível ─────────────────────────────────────────────────────
printf "\n%b\n" "${C_YELLOW}${BOLD}  ↑ Atualização disponível: v${current} → v${latest}${RESET}"

# Changelog entre versões — mostra todas as releases entre current e latest
printf "\n%b\n" "${C_DIM}  O que há de novo:${RESET}"
_showed_notes=0
while IFS= read -r _rel; do
  _rver=$(printf '%s' "$_rel" | jq -r '.tag_name // empty' | tr -d '\rv ')
  [[ -z "$_rver" ]] && continue
  [[ "$_rver" == "$current" ]] && break
  _rtag=$(printf '%s' "$_rel" | jq -r '.tag_name' | tr -d '\r')
  _rbody=$(printf '%s' "$_rel" | jq -r '.body // empty' | tr -d '\r')
  printf "\n  %b\n" "${C_YELLOW}${BOLD}${_rtag}${RESET}"
  if [[ -n "$_rbody" ]]; then
    while IFS= read -r _bline; do
      [[ -n "$_bline" ]] && printf "  %b\n" "${C_DIM}${_bline}${RESET}"
    done <<< "$(printf '%s' "$_rbody" | head -10)"
  fi
  _showed_notes=1
done < <(printf '%s' "$_releases_json" | jq -c '.[]')
[[ $_showed_notes -eq 0 ]] && printf "  %b\n" "${C_DIM}(sem notas de release)${RESET}"
echo

# ── Modo reminder: só avisa ────────────────────────────────────────────────────
if [[ "$UPDATE_MODE" == "reminder" ]]; then
  printf "%b\n\n" "${C_CYAN}  Para atualizar, execute:${RESET}"
  printf "%b\n\n" "    bash ~/.claude/statusline-update.sh"
  exit 0
fi

# ── Modo prompt (padrão): pergunta ─────────────────────────────────────────────
if [[ "$UPDATE_MODE" == "prompt" ]]; then
  printf "%b" "${C_CYAN}  Atualizar para v${latest}? [Y/n] ${RESET}"
  read -r _ans
  case "${_ans:-y}" in
    [yY]*|"") ;;
    *)
      printf "%b\n\n" "${C_DIM}  Cancelado. Execute novamente para atualizar.${RESET}"
      exit 0
      ;;
  esac
fi

# ── Executa a atualização ──────────────────────────────────────────────────────
printf "\n%b\n" "${C_DIM}  Baixando v${latest}...${RESET}"

_raw_base="https://raw.githubusercontent.com/${REPO}/refs/tags/${_tag}"
_tmp_sl=$(mktemp)
_tmp_up=$(mktemp)
_tmp_cfg=$(mktemp)
_tmp_cmd=$(mktemp)

if ! curl -sf --max-time 30 "${_raw_base}/statusline.sh" -o "$_tmp_sl" 2>/dev/null; then
  rm -f "$_tmp_sl" "$_tmp_up" "$_tmp_cfg" "$_tmp_cmd"
  printf "%b\n" "${C_RED}  Erro ao baixar. Tente novamente mais tarde.${RESET}"
  exit 1
fi

# Backup e instalação do statusline.sh
cp "$TARGET" "${TARGET}.bak"
tr -d '\r' < "$_tmp_sl" > "$TARGET"
chmod +x "$TARGET"

# Atualiza o próprio script de update (falha silenciosa)
curl -sf --max-time 30 "${_raw_base}/update.sh" -o "$_tmp_up" 2>/dev/null || true
if [[ -s "$_tmp_up" ]]; then
  tr -d '\r' < "$_tmp_up" > "$SELF"
  chmod +x "$SELF"
fi

# Atualiza o configurador TUI (falha silenciosa)
_cfg_target="$HOME/.claude/statusline-config.sh"
curl -sf --max-time 30 "${_raw_base}/statusline-config.sh" -o "$_tmp_cfg" 2>/dev/null || true
if [[ -s "$_tmp_cfg" ]]; then
  tr -d '\r' < "$_tmp_cfg" > "$_cfg_target"
  chmod +x "$_cfg_target"
fi

# Atualiza o comando /statusline (falha silenciosa — releases antigas não têm o arquivo)
_cmd_target="$HOME/.claude/commands/statusline.md"
curl -sf --max-time 30 "${_raw_base}/commands/statusline.md" -o "$_tmp_cmd" 2>/dev/null || true
if [[ -s "$_tmp_cmd" ]]; then
  mkdir -p "$(dirname "$_cmd_target")"
  tr -d '\r' < "$_tmp_cmd" > "$_cmd_target"
fi

rm -f "$_tmp_sl" "$_tmp_up" "$_tmp_cfg" "$_tmp_cmd"

# Atualiza cache (evita notificação na próxima execução do status line)
printf '%s' "$latest" > /tmp/claude-statusline-update-cache

# ── Banner de sucesso ──────────────────────────────────────────────────────────
R=("${RAINBOW[@]}")
echo ""
printf "%b   ____  __          __             __   %b\n"  "${R[0]}" "$RESET"
printf "%b  / __/ / /_  __ _  / /_  __ ___  / /__ %b\n"  "${R[1]}" "$RESET"
printf "%b _\ \  / __/ / _ \  / __/ / // _  / (_-< %b\n"  "${R[2]}" "$RESET"
printf "%b/___/  \__/  \_,_/ /_/    \_,_/\_,_/___/ %b\n"  "${R[3]}" "$RESET"
echo ""
printf "  %b✓ Atualizado para v%s com sucesso!%b\n\n"    "${C_GREEN}${BOLD}" "$latest" "$RESET"
printf "  %bBackup salvo em: %s.bak%b\n"                 "$C_DIM" "$TARGET" "$RESET"
printf "  %bReinicie o Claude Code para ativar.%b\n\n"   "$C_DIM" "$RESET"
