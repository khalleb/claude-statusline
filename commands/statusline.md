Você está no modo de configuração interativa do claude-statusline.

Argumentos recebidos: $ARGUMENTS

## Mapeamento de opções

| # | Chave | Variável | Tipo |
|---|-------|----------|------|
| 1 | nerdfont | CLAUDE_STATUSLINE_NERDFONT | toggle |
| 2 | git | CLAUDE_STATUSLINE_GIT | toggle |
| 3 | pwd | CLAUDE_STATUSLINE_PWD | toggle |
| 4 | account | CLAUDE_STATUSLINE_ACCOUNT | toggle |
| 5 | cost | CLAUDE_STATUSLINE_COST | toggle |
| 6 | ascii | CLAUDE_STATUSLINE_ASCII | toggle |
| 7 | noupdate | CLAUDE_STATUSLINE_NOUPDATE | toggle |
| 8 | update-mode | CLAUDE_STATUSLINE_UPDATE_MODE | ciclo: prompt → auto → reminder → disabled |
| 9 | update-freq | CLAUDE_STATUSLINE_UPDATE_FREQ | número de dias |

## Descrições de cada opção

1. **nerdfont** — Ícones Nerd Font na linha 1 (requer CaskaydiaCove NF ou JetBrainsMono NF)
2. **git** — Linha 2: branch git + nome da pasta atual
3. **pwd** — Linha 2: caminho completo em vez do nome da pasta ($HOME → ~)
4. **account** — Linha 2: conta logada (organização ou e-mail) — útil para quem alterna entre contas
5. **cost** — Linha 1: custo da sessão ($X.XX) + linhas adicionadas/removidas (+N -N)
6. **ascii** — Modo ASCII puro: sem Unicode, sem gradiente de cores
7. **noupdate** — Desativa a verificação de atualização no GitHub
8. **update-mode** — Como o updater se comporta: prompt (pergunta), auto (silencioso), reminder (só avisa), disabled (desligado)
9. **update-freq** — De quantos em quantos dias verificar por atualizações (padrão: 1)

---

## Se $ARGUMENTS estiver vazio (chamada inicial)

1. Leia `~/.claude/settings.json`
2. Para cada opção, determine o estado atual:
   - toggle: `[X]` se a variável for `"1"`, `[ ]` se ausente ou outro valor
   - update-mode: mostra o valor atual entre colchetes, ex: `[prompt]`
   - update-freq: mostra o valor atual com sufixo "d", ex: `[1d]`
3. Exiba **exatamente** neste formato (substitua os estados):

```
  [X] 1  nerdfont     Ícones Nerd Font (CaskaydiaCove NF)
  [X] 2  git          Linha 2: branch git + pasta
  [ ] 3  pwd          Linha 2: caminho completo
  [ ] 4  account      Linha 2: conta logada
  [X] 5  cost         Custo da sessão na linha 1
  [ ] 6  ascii        Modo ASCII puro
  [ ] 7  noupdate     Sem verificação de update
  [prompt] 8  update-mode  Modo de atualização
  [1d]     9  update-freq  Frequência de verificação

  ──────────────────────────────────────────────────
  Digite o número para alternar  •  ex: 3  ou  1 5
  "8 auto" para update-mode  •  "9 7" para 7 dias
  "q" para sair
```

4. Aguarde a próxima mensagem do usuário.

---

## Para cada mensagem seguinte

### Comando de número simples (ex: `3` ou `1 5 6`)

Para cada número na mensagem:
- Se for toggle (1–7): inverta o estado
  - Estava `[ ]` → muda para `[X]` (define como `"1"` no env)
  - Estava `[X]` → muda para `[ ]` (remove do env)
- Se for 8 (update-mode) sem valor: avance para o próximo do ciclo (prompt → auto → reminder → disabled → prompt)
- Se for 9 (update-freq) sem valor: pergunte o número de dias

### Comando com valor (ex: `8 auto` ou `9 3`)

- **8 + valor**: define CLAUDE_STATUSLINE_UPDATE_MODE com o valor informado
- **9 + número**: define CLAUDE_STATUSLINE_UPDATE_FREQ com o número informado

### Comando `q` ou `sair`

Encerre o modo de configuração com: "Configurações fechadas."

---

## Ao aplicar qualquer alteração

1. Leia o `~/.claude/settings.json` atual
2. Aplique a mudança na chave `env`:
   - Ativar toggle: `.env.VARIAVEL = "1"`
   - Desativar toggle: `del(.env.VARIAVEL)`
   - update-mode/update-freq: `.env.VARIAVEL = "valor"`
3. Salve o arquivo (mantenha todas as outras chaves intactas; crie `env` se não existir)
4. Exiba a lista **completa e atualizada** no mesmo formato acima
5. Confirme em uma linha: `✓ salvo`
6. Aguarde a próxima ação do usuário

---

## Regras obrigatórias

- Variáveis desativadas → **remove** do `env`, nunca define como `"0"` ou `"false"`
- Variáveis ativadas → define como `"1"`
- Não altere nenhuma outra chave do settings.json (statusLine, hooks, permissions, etc.)
- Se `env` não existir no settings.json, crie-a antes de adicionar variáveis
