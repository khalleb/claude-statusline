#!/usr/bin/env bash
# Claude Code Status Line — Updater
# Uso: bash ~/.claude/statusline-update.sh
# Modo: CLAUDE_STATUSLINE_UPDATE_MODE=prompt|auto|reminder|disabled

TARGET="$HOME/.claude/statusline.sh"
SELF="$HOME/.claude/statusline-update.sh"
REPO="khalleb/claude-statusline"
UPDATE_MODE="${CLAUDE_STATUSLINE_UPDATE_MODE:-prompt}"

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

# ── Consulta GitHub Releases ───────────────────────────────────────────────────
printf "%b\r" "${C_DIM}Verificando atualizações...${RESET}"
_api="https://api.github.com/repos/${REPO}/releases/latest"
_response=$(curl -sf --max-time 10 "$_api" 2>/dev/null || true)
printf "\033[2K"  # limpa linha

if [[ -z "$_response" ]]; then
  printf "%b\n" "${C_RED}Não foi possível contatar o GitHub. Verifique sua conexão.${RESET}"
  exit 1
fi

_tag=$(printf '%s' "$_response" | jq -r '.tag_name // empty' | tr -d '\r')
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

# Release notes (primeiras linhas do body)
_notes=$(printf '%s' "$_response" | jq -r '.body // empty' | tr -d '\r' | head -15)
if [[ -n "$_notes" ]]; then
  printf "\n%b\n" "${C_DIM}  O que há de novo:${RESET}"
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && printf "  %b\n" "${C_DIM}${_line}${RESET}"
  done <<< "$_notes"
  echo
fi

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

# Baixa statusline.sh
if ! curl -sf --max-time 30 "${_raw_base}/statusline.sh" -o "$_tmp_sl" 2>/dev/null; then
  rm -f "$_tmp_sl" "$_tmp_up"
  printf "%b\n" "${C_RED}  Erro ao baixar. Tente novamente mais tarde.${RESET}"
  exit 1
fi

# Baixa update.sh (opcional — falha silenciosa)
curl -sf --max-time 30 "${_raw_base}/update.sh" -o "$_tmp_up" 2>/dev/null || true

# Backup e instalação do statusline.sh
cp "$TARGET" "${TARGET}.bak"
tr -d '\r' < "$_tmp_sl" > "$TARGET"
chmod +x "$TARGET"

# Atualiza o próprio script de update (se baixou com sucesso)
if [[ -s "$_tmp_up" ]]; then
  tr -d '\r' < "$_tmp_up" > "$SELF"
  chmod +x "$SELF"
fi

rm -f "$_tmp_sl" "$_tmp_up"

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
