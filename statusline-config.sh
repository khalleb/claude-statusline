#!/usr/bin/env bash
# Claude Statusline — Configurador interativo
# Uso: bash ~/.claude/statusline-config.sh

SETTINGS="$HOME/.claude/settings.json"

# ── Cores ──────────────────────────────────────────────────────────────────────
RST="\033[0m"; BOLD="\033[1m"; DIM="\033[2m"; REV="\033[7m"
CY="\033[36m"; GR="\033[32m"; YL="\033[33m"

# ── Definição das opções ───────────────────────────────────────────────────────
KEYS=(  nerdfont     git                    pwd                     account                    cost                    ascii                 noupdate                      update-mode              update-freq            )
VARS=(  CLAUDE_STATUSLINE_NERDFONT  CLAUDE_STATUSLINE_GIT  CLAUDE_STATUSLINE_PWD  CLAUDE_STATUSLINE_ACCOUNT  CLAUDE_STATUSLINE_COST  CLAUDE_STATUSLINE_ASCII  CLAUDE_STATUSLINE_NOUPDATE  CLAUDE_STATUSLINE_UPDATE_MODE  CLAUDE_STATUSLINE_UPDATE_FREQ  )
DESCS=( "Ícones Nerd Font (CaskaydiaCove NF / JetBrainsMono NF)"
        "Linha 2: branch git + nome da pasta"
        "Linha 2: caminho completo (\$HOME → ~)"
        "Linha 2: conta logada (organização ou e-mail)"
        "Linha 1: custo da sessão + linhas +/−"
        "Modo ASCII puro — sem Unicode, sem cores"
        "Desativa verificação de atualização no GitHub"
        "Modo de atualização: prompt / auto / reminder / disabled"
        "Frequência de verificação em dias" )
TYPES=( toggle toggle toggle toggle toggle toggle toggle cycle number )
CYCLES=( "" "" "" "" "" "" "" "prompt,auto,reminder,disabled" "" )
N=${#KEYS[@]}

declare -a VALUES
cur=0
changed=0

# ── Lê valores do settings.json ────────────────────────────────────────────────
_load() {
  VALUES=()
  for v in "${VARS[@]}"; do
    local val=""
    if [[ -f "$SETTINGS" ]]; then
      val=$(jq -r --arg k "$v" '.env[$k] // empty' "$SETTINGS" 2>/dev/null | tr -d '\r')
    fi
    VALUES+=("$val")
  done
}

# ── Salva no settings.json ─────────────────────────────────────────────────────
_save() {
  [[ ! -f "$SETTINGS" ]] && echo '{}' > "$SETTINGS"
  local tmp
  tmp=$(mktemp)

  jq 'if .env == null then .env = {} else . end' "$SETTINGS" > "$tmp" && cp "$tmp" "$SETTINGS"

  for i in "${!VARS[@]}"; do
    local var="${VARS[$i]}"
    local val="${VALUES[$i]}"
    local type="${TYPES[$i]}"

    if [[ -z "$val" ]] || { [[ "$type" == "toggle" ]] && [[ "$val" != "1" ]]; }; then
      jq --arg k "$var" 'del(.env[$k])' "$SETTINGS" > "$tmp" && cp "$tmp" "$SETTINGS"
    else
      jq --arg k "$var" --arg v "$val" '.env[$k] = $v' "$SETTINGS" > "$tmp" && cp "$tmp" "$SETTINGS"
    fi
  done

  rm -f "$tmp"
}

# ── Renderiza a tela ───────────────────────────────────────────────────────────
_render() {
  printf "\033[2J\033[H"
  printf "%b\n\n" " ${BOLD}${CY}Claude Statusline — Configurações${RST}"

  for i in "${!KEYS[@]}"; do
    local type="${TYPES[$i]}"
    local val="${VALUES[$i]}"
    local badge

    case "$type" in
      toggle)
        [[ "$val" == "1" ]] && badge="${GR}[X]${RST}" || badge="${DIM}[ ]${RST}"
        ;;
      cycle)
        badge="${YL}[${val:-prompt}]${RST}"
        ;;
      number)
        badge="${YL}[${val:-1}d]${RST}"
        ;;
    esac

    local key="${KEYS[$i]}"
    local desc="${DESCS[$i]}"

    if [[ $i -eq $cur ]]; then
      printf " ${REV}${badge} $(printf '%-12s' "$key") ${DIM}${desc}${RST}${REV} ${RST}\n"
    else
      printf " ${badge} $(printf '%-12s' "$key") ${DIM}${desc}${RST}\n"
    fi
  done

  local hint=""
  [[ $changed -eq 1 ]] && hint="${YL} — alterações não salvas${RST}"
  printf "\n%b\n" " ${DIM}↑↓ navegar  Espaço/Enter alternar  s salvar  q sair${RST}${hint}"
}

# ── Alterna o item atual ───────────────────────────────────────────────────────
_toggle() {
  local i=$1
  local type="${TYPES[$i]}"
  local val="${VALUES[$i]}"
  changed=1

  case "$type" in
    toggle)
      [[ "$val" == "1" ]] && VALUES[$i]="" || VALUES[$i]="1"
      ;;
    cycle)
      IFS=',' read -ra opts <<< "${CYCLES[$i]}"
      local cur_val="${val:-${opts[0]}}"
      local next=0
      for j in "${!opts[@]}"; do
        if [[ "${opts[$j]}" == "$cur_val" ]]; then
          next=$(( (j + 1) % ${#opts[@]} ))
          break
        fi
      done
      VALUES[$i]="${opts[$next]}"
      ;;
    number)
      tput cnorm 2>/dev/null
      printf "\n %b" "${CY}Frequência (dias): ${RST}"
      local num
      read -r num
      tput civis 2>/dev/null
      [[ "$num" =~ ^[1-9][0-9]*$ ]] && VALUES[$i]="$num"
      ;;
  esac
}

# ── Lê tecla (suporte a setas) ─────────────────────────────────────────────────
_read_key() {
  local key rest
  IFS= read -rsn1 key
  if [[ "$key" == $'\033' ]]; then
    IFS= read -rsn2 -t 0.1 rest
    key="${key}${rest}"
  fi
  printf '%s' "$key"
}

# ── Verifica dependências ──────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  printf "Erro: jq não encontrado. Instale com: winget install jqlang.jq\n" >&2
  exit 1
fi

# ── Main ───────────────────────────────────────────────────────────────────────
_load

tput civis 2>/dev/null
tput smcup 2>/dev/null
trap 'tput cnorm 2>/dev/null; tput rmcup 2>/dev/null' EXIT INT TERM

while true; do
  _render
  key=$(_read_key)

  case "$key" in
    $'\033[A'|k)     (( cur > 0 ))     && (( cur-- )) ;;
    $'\033[B'|j)     (( cur < N - 1 )) && (( cur++ )) ;;
    ' '|$'\n'|$'\r') _toggle "$cur" ;;
    s|S)
      _save
      tput cnorm 2>/dev/null
      tput rmcup 2>/dev/null
      printf "%b\n" "${GR}✓ Configurações salvas. Reinicie o Claude Code para aplicar.${RST}"
      exit 0
      ;;
    q|Q|$'\033')
      tput cnorm 2>/dev/null
      tput rmcup 2>/dev/null
      if [[ $changed -eq 1 ]]; then
        printf "%b" "${YL}Descartar alterações? [s/N] ${RST}"
        read -r ans
        [[ "${ans:-n}" =~ ^[sS] ]] && printf "${DIM}Saído sem salvar.${RST}\n" && exit 0
        tput civis 2>/dev/null
        tput smcup 2>/dev/null
      else
        printf "${DIM}Saído.${RST}\n"
        exit 0
      fi
      ;;
  esac
done
