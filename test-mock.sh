#!/usr/bin/env bash
# Testes do Claude Code Status Line

SCRIPT="$(cd "$(dirname "$0")" && pwd)/statusline.sh"

run_test() {
  local name="$1" json="$2"
  echo ""
  printf "\033[2m── %s \033[0m\n" "$name"
  echo "$json" | bash "$SCRIPT"
}

echo "=== Testes do Claude Code Status Line ==="

run_test "Normal (42% ctx, 5h 23%)" '{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 42, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": 23, "reset_in_seconds": 7920},
    "seven_day":  {"used_percentage": 8,  "reset_in_seconds": 250200}
  }
}'

run_test "Aviso (75% ctx, 5h 65%)" '{
  "model": {"display_name": "Claude Opus 4.8"},
  "context_window": {"used_percentage": 75, "context_window_size": 1000000},
  "rate_limits": {
    "five_hour": {"used_percentage": 65, "reset_in_seconds": 3720},
    "seven_day":  {"used_percentage": 42, "reset_in_seconds": 172800}
  }
}'

run_test "Perigo (92% ctx, 5h 85%)" '{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 92, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": 85, "reset_in_seconds": 1200},
    "seven_day":  {"used_percentage": 91, "reset_in_seconds": 86400}
  }
}'

run_test "Sem rate limits (plano API)" '{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 30, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": -1},
    "seven_day":  {"used_percentage": -1}
  }
}'

run_test "Sessão nova (0%)" '{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 0, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": 0, "reset_in_seconds": 18000},
    "seven_day":  {"used_percentage": 0, "reset_in_seconds": 604800}
  }
}'

run_test "ASCII mode" "$(CLAUDE_STATUSLINE_ASCII=1 cat <<'EOF'
{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 55, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": 40, "reset_in_seconds": 5400},
    "seven_day":  {"used_percentage": 20, "reset_in_seconds": 345600}
  }
}
EOF
)"

echo ""
echo "=== Testes concluídos ==="
