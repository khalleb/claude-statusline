#!/usr/bin/env bash
# Claude Code Status Line — Git Bash (Windows)
# Inspirado em claude-code-statusline por KC Chien

# ── Feature flags ──────────────────────────────────────────────────────────────
FORCE_ASCII="${CLAUDE_STATUSLINE_ASCII:-0}"
FORCE_NERDFONT="${CLAUDE_STATUSLINE_NERDFONT:-0}"

# ── True-color detection ───────────────────────────────────────────────────────
if [[ "${COLORTERM}" == "truecolor" || "${COLORTERM}" == "24bit" || -n "${WT_SESSION}" ]]; then
  TRUE_COLOR=1
else
  TRUE_COLOR=0
fi

# ── Cores ──────────────────────────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"

if [[ $TRUE_COLOR -eq 1 && $FORCE_ASCII -eq 0 ]]; then
  C_CYAN="\033[38;2;86;182;194m"
  C_DIM="\033[38;2;100;100;100m"
  C_YELLOW="\033[38;2;229;192;123m"
  C_GREEN="\033[38;2;152;195;121m"
  C_RED="\033[38;2;224;108;117m"
  C_GRAY="\033[38;2;160;160;160m"
else
  C_CYAN="\033[36m"
  C_DIM="\033[2m"
  C_YELLOW="\033[33m"
  C_GREEN="\033[32m"
  C_RED="\033[31m"
  C_GRAY="\033[37m"
fi

# ── Símbolos ───────────────────────────────────────────────────────────────────
if [[ $FORCE_ASCII -eq 1 ]]; then
  SYM_MODEL="> "
  SYM_CTX="ctx:"
  SYM_CYCLE="reset:"
  SYM_WARN="!"
  SYM_SEP=" | "
elif [[ $FORCE_NERDFONT -eq 1 ]]; then
  SYM_MODEL=$' '      #  robot
  SYM_CTX=$' '        #  gráfico
  SYM_CYCLE=$'↺ '     # ↺ seta de reset
  SYM_WARN=$' '       #  aviso
  SYM_SEP=" │ "
else
  SYM_MODEL="◆ "
  SYM_CTX=" "
  SYM_CYCLE="↺ "
  SYM_WARN=" ⚠"
  SYM_SEP=" │ "
fi

# ── Verificação do jq ──────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  printf "%b\n" "${C_RED}[statusline] jq não encontrado — instale: winget install jqlang.jq${RESET}"
  printf "%b\n" "${C_DIM}ou via scoop: scoop install jq${RESET}"
  exit 0
fi

# ── Parse JSON ─────────────────────────────────────────────────────────────────
JSON_INPUT=$(cat)

# Debug: CLAUDE_STATUSLINE_DEBUG=1 grava o JSON em /tmp para inspeção
[[ "${CLAUDE_STATUSLINE_DEBUG:-0}" == "1" ]] && echo "$JSON_INPUT" > /tmp/claude-sl-debug.json

{
  IFS= read -r model_name
  IFS= read -r ctx_pct
  IFS= read -r ctx_size
  IFS= read -r rate_5h
  IFS= read -r rate_7d
  IFS= read -r resets_at_5h
  IFS= read -r resets_at_7d
  IFS= read -r _sentinel
} <<< "$(jq -r '
  .model.display_name // "Unknown",
  ((.context_window.used_percentage // 0) | floor),
  ((.context_window.context_window_size // 0) | floor),
  ((.rate_limits.five_hour.used_percentage // -1) | floor),
  ((.rate_limits.seven_day.used_percentage // -1) | floor),
  ((.rate_limits.five_hour.resets_at // -1) | floor),
  ((.rate_limits.seven_day.resets_at // -1) | floor),
  "END"
' <<< "$JSON_INPUT" | tr -d '\r')"

# Calcula segundos restantes a partir do Unix timestamp
_now=$(date +%s)
reset_5h_secs=$(( resets_at_5h > 0 ? resets_at_5h - _now : -1 ))
reset_7d_secs=$(( resets_at_7d > 0 ? resets_at_7d - _now : -1 ))

# ── Label do context window (200K context, 1M context) ────────────────────────
ctx_label=""
if   (( ctx_size >= 1000000 )); then ctx_label=" ($(( ctx_size / 1000000 ))M context)"
elif (( ctx_size >= 1000    )); then ctx_label=" ($(( ctx_size / 1000 ))K context)"
fi


# ── Formata tempo de reset (segundos → Xd [Yh] / Xh [Ym] / Xm) ──────────────
format_reset() {
  local secs=$1
  if (( secs <= 0 )); then
    echo ""
  elif (( secs >= 86400 )); then
    local d=$(( secs / 86400 )) h=$(( secs % 86400 / 3600 ))
    (( h > 0 )) && printf "%dd %dh" $d $h || printf "%dd" $d
  elif (( secs >= 3600 )); then
    local h=$(( secs / 3600 )) m=$(( secs % 3600 / 60 ))
    (( m > 0 )) && printf "%dh %dm" $h $m || printf "%dh" $h
  else
    printf "%dm" $(( secs / 60 ))
  fi
}

# ── Cria barra de progresso ────────────────────────────────────────────────────
# Uso: make_bar <percentual> <largura>
# Retorna a string da barra em BAR_RESULT
make_bar() {
  local pct=$1 width=$2
  pct=$(( pct < 0 ? 0 : pct > 100 ? 100 : pct ))
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))

  # Gradiente true-color (até 20 segmentos)
  local GRAD_R=( 46  52  58  74  90 115 140 175 210 224 230 236 236 236 236 233 224 214 205 192)
  local GRAD_G=(204 202 199 200 195 183 168 140 110  92  72  52  42  32  22  14   8   0   0   0)
  local GRAD_B=(113  95  77  62  35  22  11   8   6   4   3   2   1   1   0   0   0   0   0   0)

  if [[ $FORCE_ASCII -eq 1 ]]; then
    BAR_RESULT="["
    for (( i=0; i<filled; i++ )); do BAR_RESULT+="#"; done
    for (( i=0; i<empty;  i++ )); do BAR_RESULT+="-"; done
    BAR_RESULT+="]"
  elif [[ $TRUE_COLOR -eq 1 ]]; then
    BAR_RESULT=""
    for (( i=0; i<width; i++ )); do
      local idx=$(( i * 20 / width ))  # mapeia o índice para o gradiente de 20 cores
      (( idx > 19 )) && idx=19
      if (( i < filled )); then
        BAR_RESULT+=$(printf "\033[38;2;%d;%d;%dm█" "${GRAD_R[$idx]}" "${GRAD_G[$idx]}" "${GRAD_B[$idx]}")
      else
        BAR_RESULT+=$(printf "\033[38;2;50;50;50m▓")
      fi
    done
    BAR_RESULT+="${RESET}"
  else
    if   (( pct >= 90 )); then local bc="${C_RED}"
    elif (( pct >= 70 )); then local bc="${C_YELLOW}"
    else                       local bc="${C_GREEN}"
    fi
    BAR_RESULT="${bc}"
    for (( i=0; i<filled; i++ )); do BAR_RESULT+="█"; done
    for (( i=0; i<empty;  i++ )); do BAR_RESULT+="░"; done
    BAR_RESULT+="${RESET}"
  fi
}

# ── Cor do percentual baseada no valor ────────────────────────────────────────
pct_color() {
  local pct=$1 warn_sym=$2
  if   (( pct >= 90 )); then printf "%b" "${C_RED}${pct}%${warn_sym}${RESET}"
  elif (( pct >= 70 )); then printf "%b" "${C_YELLOW}${pct}%${RESET}"
  else                       printf "%b" "${C_GREEN}${pct}%${RESET}"
  fi
}

# ── Separador ─────────────────────────────────────────────────────────────────
SEP="${C_DIM}${SYM_SEP}${RESET}"

# ── Linha única ───────────────────────────────────────────────────────────────
make_bar "$ctx_pct" 20
ctx_bar="$BAR_RESULT"
ctx_pct_str=$(pct_color "$ctx_pct" "$SYM_WARN")

line1="${C_CYAN}${SYM_MODEL}${model_name}${C_DIM}${ctx_label}${RESET}"
line1+="${SEP}${C_DIM}${SYM_CTX}${RESET}${ctx_bar} ${ctx_pct_str}"

# Sessão 5h: barra + % + tempo para reset
if (( rate_5h >= 0 )); then
  make_bar "$rate_5h" 10
  rate_bar="$BAR_RESULT"
  rate_pct_str=$(pct_color "$rate_5h" "")
  _r5=$(format_reset "$reset_5h_secs")

  line1+="${SEP}${C_DIM}5h${RESET} ${rate_bar} ${rate_pct_str}"
  [[ -n "$_r5" ]] && line1+=" ${C_DIM}${SYM_CYCLE}${_r5}${RESET}"
fi

# Sessão 7d: tempo para reset
if (( rate_7d >= 0 )); then
  _r7=$(format_reset "$reset_7d_secs")
  if [[ -n "$_r7" ]]; then
    line1+="${SEP}${C_DIM}7d ${SYM_CYCLE}${RESET}${C_GRAY}${_r7}${RESET}"
  else
    line1+="${SEP}${C_DIM}7d${RESET} $(pct_color "$rate_7d" "")"
  fi
fi

line2=""

printf "%b\n" "$line1"
printf "%b\n" "$line2"
