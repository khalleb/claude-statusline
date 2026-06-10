#!/usr/bin/env bash
# Testes do Claude Code Status Line

SCRIPT="$(cd "$(dirname "$0")" && pwd)/statusline.sh"
_now=$(date +%s)

run_test() {
  local name="$1" json="$2" env_vars="${3:-}"
  echo ""
  printf "\033[2m── %s \033[0m\n" "$name"
  if [[ -n "$env_vars" ]]; then
    echo "$json" | env $env_vars bash "$SCRIPT"
  else
    echo "$json" | bash "$SCRIPT"
  fi
}

echo "=== Testes do Claude Code Status Line ==="

run_test "Normal (42% ctx, 5h 23%)" "$(cat <<EOF
{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 42, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": 23, "resets_at": $((_now + 7920))},
    "seven_day":  {"used_percentage": 8,  "resets_at": $((_now + 250200))}
  }
}
EOF
)"

run_test "Aviso (75% ctx, 5h 65%)" "$(cat <<EOF
{
  "model": {"display_name": "Claude Opus 4.8"},
  "context_window": {"used_percentage": 75, "context_window_size": 1000000},
  "rate_limits": {
    "five_hour": {"used_percentage": 65, "resets_at": $((_now + 3720))},
    "seven_day":  {"used_percentage": 42, "resets_at": $((_now + 172800))}
  }
}
EOF
)"

run_test "Perigo (92% ctx, 5h 85%)" "$(cat <<EOF
{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 92, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": 85, "resets_at": $((_now + 1200))},
    "seven_day":  {"used_percentage": 91, "resets_at": $((_now + 86400))}
  }
}
EOF
)"

run_test "Sem rate limits (plano API)" "$(cat <<EOF
{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 30, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": -1},
    "seven_day":  {"used_percentage": -1}
  }
}
EOF
)"

run_test "Sessão nova (0%)" "$(cat <<EOF
{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 0, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": 0, "resets_at": $((_now + 18000))},
    "seven_day":  {"used_percentage": 0, "resets_at": $((_now + 604800))}
  }
}
EOF
)"

run_test "Output style (extended-thinking)" "$(cat <<EOF
{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 35, "context_window_size": 200000},
  "output_style": {"name": "extended-thinking"},
  "rate_limits": {
    "five_hour": {"used_percentage": 15, "resets_at": $((_now + 12000))},
    "seven_day":  {"used_percentage": 5,  "resets_at": $((_now + 500000))}
  }
}
EOF
)"

run_test "Com custo de sessão (COST=1)" "$(cat <<EOF
{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 55, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": 40, "resets_at": $((_now + 5400))},
    "seven_day":  {"used_percentage": 20, "resets_at": $((_now + 345600))}
  },
  "cost": {"total_cost_usd": 0.1247, "total_lines_added": 342, "total_lines_removed": 87}
}
EOF
)" "CLAUDE_STATUSLINE_COST=1"

run_test "Linha 2 com branch (GIT=1)" "$(cat <<EOF
{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 20, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": 10, "resets_at": $((_now + 14400))},
    "seven_day":  {"used_percentage": 3,  "resets_at": $((_now + 600000))}
  },
  "worktree": {"branch": "feature/minha-branch"},
  "workspace": {"current_dir": "C:/repositorios/meu-projeto"}
}
EOF
)" "CLAUDE_STATUSLINE_GIT=1"

# Conta logada: aponta CLAUDE_CONFIG_DIR para um .claude.json fake (teste determinístico)
_acct_dir=$(mktemp -d)
echo '{"oauthAccount":{"organizationName":"Acme Corp","emailAddress":"dev@acme.com"}}' > "$_acct_dir/.claude.json"
run_test "Linha 2 com conta (ACCOUNT=1 + GIT=1)" "$(cat <<EOF
{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 20, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": 10, "resets_at": $((_now + 14400))},
    "seven_day":  {"used_percentage": 3,  "resets_at": $((_now + 600000))}
  },
  "worktree": {"branch": "feature/minha-branch"},
  "workspace": {"current_dir": "C:/repositorios/meu-projeto"}
}
EOF
)" "CLAUDE_STATUSLINE_ACCOUNT=1 CLAUDE_STATUSLINE_GIT=1 CLAUDE_CONFIG_DIR=$_acct_dir"
rm -rf "$_acct_dir"

# Conta pessoal: organizationName auto-gerado ("...'s Organization") → mostra o e-mail
_acct_dir=$(mktemp -d)
echo "{\"oauthAccount\":{\"organizationName\":\"dev@acme.com's Organization\",\"emailAddress\":\"dev@acme.com\"}}" > "$_acct_dir/.claude.json"
run_test "Conta pessoal (org auto-gerada → e-mail)" "$(cat <<EOF
{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 20, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": 10, "resets_at": $((_now + 14400))},
    "seven_day":  {"used_percentage": 3,  "resets_at": $((_now + 600000))}
  }
}
EOF
)" "CLAUDE_STATUSLINE_ACCOUNT=1 CLAUDE_CONFIG_DIR=$_acct_dir"
rm -rf "$_acct_dir"

# Aviso de atualização: cria cache com versão mais nova para simular GitHub release
echo "2.0.0" > /tmp/claude-statusline-update-cache
run_test "Aviso de atualização disponível (v2.0.0)" "$(cat <<EOF
{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 30, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": 12, "resets_at": $((_now + 10800))},
    "seven_day":  {"used_percentage": 4,  "resets_at": $((_now + 432000))}
  }
}
EOF
)"
rm -f /tmp/claude-statusline-update-cache

run_test "ASCII mode" "$(cat <<EOF
{
  "model": {"display_name": "Claude Sonnet 4.6"},
  "context_window": {"used_percentage": 55, "context_window_size": 200000},
  "rate_limits": {
    "five_hour": {"used_percentage": 40, "resets_at": $((_now + 5400))},
    "seven_day":  {"used_percentage": 20, "resets_at": $((_now + 345600))}
  }
}
EOF
)" "CLAUDE_STATUSLINE_ASCII=1"

echo ""
echo "=== Testes concluídos ==="
