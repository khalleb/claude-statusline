# claude-statusline

Status line minimalista para o [Claude Code](https://claude.ai/code) rodando no **Git Bash ou PowerShell no Windows** (e também no **WSL/Linux**).

Exibe modelo, uso do contexto, limite da sessão atual e limite semanal — tudo em uma linha, atualizado após cada resposta. Opcionalmente exibe a branch git atual e o nome da pasta em uma segunda linha.

> 📖 [Read in English](README.md)

---

## Preview

**Git Bash**
![Git Bash preview](docs/preview-gitbash.png)

**PowerShell**
![PowerShell preview](docs/preview-powershell.png)

```
 Sonnet 4.6 (200K context) │  ███░░░░░░░░░░░░░░░░░ 16% │ 5h ██░░░░░░░░ 31% ↺ 2h 33m │ 7d ↺ 2d │ $0.03 +12 -4
 master │  meu-projeto
```

**Linha 1 — sempre visível:**

| Segmento | Descrição |
|----------|-----------|
| ` Sonnet 4.6` | Modelo atual |
| `(200K context)` | Tamanho do context window |
| `███░░░ 16%` | Barra de uso do contexto |
| `5h ██░░░ 31% ↺ 2h 33m` | Barra de uso da sessão de 5h + tempo para reset |
| `7d ↺ 2d` | Tempo para reset da sessão semanal |
| `$0.03 +12 -4` | Custo da sessão + linhas adicionadas/removidas (requer `CLAUDE_STATUSLINE_COST=1`) |
| `↑ 1.2.0` | Atualização disponível (link clicável em terminais compatíveis) |

**Linha 2 — opcional (`CLAUDE_STATUSLINE_GIT=1`, `CLAUDE_STATUSLINE_PWD=1` ou `CLAUDE_STATUSLINE_ACCOUNT=1`):**

| Segmento | Descrição |
|----------|-----------|
| ` master` | Branch git atual (sufixo `*` se houver alterações não commitadas) |
| ` meu-projeto` | Nome da pasta (padrão) ou caminho completo com `CLAUDE_STATUSLINE_PWD=1` |
| ` Acme Corp` | Conta logada — nome da organização, ou e-mail como fallback (requer `CLAUDE_STATUSLINE_ACCOUNT=1`) |

**Cores:**
- 🟢 Verde — 0–69%
- 🟡 Amarelo — 70–89%
- 🔴 Vermelho — 90–100%

---

## Requisitos

| Ferramenta | Finalidade | Instalação |
|------------|------------|------------|
| [Git Bash](https://git-scm.com/downloads) | Shell de execução | Incluído no Git for Windows |
| [jq](https://jqlang.github.io/jq/) | Parsing de JSON | `winget install jqlang.jq` |
| [CaskaydiaCove NF](https://www.nerdfonts.com/) *(opcional)* | Ícones Nerd Font | Veja [Configuração de Fonte](#configuração-de-fonte-opcional) |

> **Usando PowerShell?** O Claude Code executa o status line via `bash`, então o **Git Bash é necessário mesmo ao iniciar o Claude Code pelo PowerShell**. O instalador PowerShell (`install.ps1`) apenas copia o script e configura o `settings.json` — o script em si sempre roda no `bash`.

---

## Instalação

**1. Clone o repositório:**
```bash
git clone https://github.com/khalleb/claude-statusline.git
cd claude-statusline
```

**2. Execute o instalador** — escolha o adequado ao seu shell:

**Git Bash / WSL / Linux:**
```bash
bash install.sh
```

**PowerShell (Windows):**
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Os dois instaladores fazem a mesma coisa:
- Verificar se o `jq` está disponível
- Copiar `statusline.sh`, `statusline-update.sh` e `statusline-config.sh` para `~/.claude/`
- Oferecer para atualizar o `~/.claude/settings.json` automaticamente

**3. Adicione `statusLine` ao `~/.claude/settings.json`** (caso não tenha sido feito automaticamente):
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "timeout": 10
  }
}
```

**4. Reinicie o Claude Code.**

---

## Configuração

Existem três formas de configurar o claude-statusline:

### 1. Comando `/statusline-khalleb` (dentro do Claude Code)

Digite `/statusline-khalleb` em qualquer sessão do Claude Code para abrir o menu interativo de configuração:

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

Digite um número para alternar a opção. Digite `q` para sair.

### 2. TUI interativo (terminal)

Execute diretamente no terminal para navegação com setas do teclado:

```bash
bash ~/.claude/statusline-config.sh
```

- **↑↓** para navegar
- **Espaço / Enter** para alternar
- **s** para salvar
- **q** para sair sem salvar

### 3. Editar `~/.claude/settings.json` manualmente

Adicione as variáveis na chave `env`:

```json
{
  "env": {
    "CLAUDE_STATUSLINE_NERDFONT": "1",
    "CLAUDE_STATUSLINE_GIT": "1"
  }
}
```

> **Por que não usar `~/.bashrc`?** Variáveis no `~/.bashrc` só são carregadas pelo Git Bash. Se você iniciar o Claude Code pelo PowerShell ou outro shell, elas não estarão disponíveis e os recursos não aparecerão.

---

## Variáveis de Ambiente

| Variável | Valor | Efeito |
|----------|-------|--------|
| `CLAUDE_STATUSLINE_NERDFONT` | `1` | Ativa ícones Nerd Font (requer CaskaydiaCove NF ou JetBrainsMono NF) |
| `CLAUDE_STATUSLINE_GIT` | `1` | Linha 2: branch git + nome da pasta |
| `CLAUDE_STATUSLINE_PWD` | `1` | Linha 2: caminho completo no lugar do nome da pasta (`$HOME` exibido como `~`) |
| `CLAUDE_STATUSLINE_COST` | `1` | Linha 1: custo da sessão (`$X.XX`) + linhas adicionadas/removidas (`+N -N`) |
| `CLAUDE_STATUSLINE_ACCOUNT` | `1` | Linha 2: conta logada (nome da organização, ou e-mail como fallback) — útil para quem alterna entre múltiplas contas |
| `CLAUDE_STATUSLINE_ASCII` | `1` | Força modo ASCII puro (sem Unicode, sem cores) |
| `CLAUDE_STATUSLINE_DEBUG` | `1` | Grava o JSON em `/tmp/claude-sl-debug.json` para inspeção |
| `CLAUDE_STATUSLINE_NOUPDATE` | `1` | Desativa a verificação de atualização do GitHub |
| `CLAUDE_STATUSLINE_UPDATE_MODE` | `prompt` \| `auto` \| `reminder` \| `disabled` | Controla o comportamento do updater (padrão: `prompt`) |
| `CLAUDE_STATUSLINE_UPDATE_FREQ` | número | Frequência de verificação em dias (padrão: `1`) |

O `output_style.name` é exibido automaticamente na linha 1 quando definido e diferente de `"default"`. Nenhuma variável extra necessária.

O segmento da conta não faz parte do JSON que o Claude Code envia — ele é lido do `.claude.json` (`.oauthAccount`), que o `/login` mantém atualizado. `CLAUDE_CONFIG_DIR` é respeitado para setups multi-perfil, e o valor fica em cache por 30 segundos. Contas pessoais (Pro/Max) têm um nome de organização auto-gerado como `voce@mail.com's Organization` — nesse caso o e-mail é exibido no lugar; organizações reais (Team/Enterprise) mostram o nome.

---

## Notificações de Atualização

Quando uma nova versão é lançada, a linha 1 exibe um aviso `↑ x.y.z` (link clicável no Windows Terminal, VSCode, iTerm2, Kitty, WezTerm). Para atualizar, execute:

```bash
bash ~/.claude/statusline-update.sh
```

O updater exibe o **changelog de todas as versões puladas**, baixa o novo script da release do GitHub, faz backup da versão atual (`.bak`) e se atualiza também.

| Modo | Comportamento |
|------|---------------|
| `prompt` (padrão) | Pergunta "Atualizar para vX.Y.Z? [Y/n]" |
| `auto` | Atualiza sem perguntar — também disparado automaticamente pelo status line |
| `reminder` | Só exibe o comando para atualizar, não faz nada |
| `disabled` | Sai imediatamente |

A verificação roda em background na frequência configurada (cache em `/tmp/claude-statusline-update-cache`) e requer `curl`. Um lock file (`/tmp/claude-statusline-update.lock`) impede atualizações simultâneas.

---

## Configuração de Fonte (opcional)

Para ícones Nerd Font, instale a **CaskaydiaCove NF**:

```powershell
# Baixar e instalar (execute no PowerShell)
$url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip"
$zip = "$env:TEMP\CascadiaCode-NF.zip"
$out = "$env:TEMP\CascadiaCode-NF"
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
Expand-Archive -Path $zip -DestinationPath $out -Force
$fontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
New-Item -ItemType Directory -Force -Path $fontsDir | Out-Null
Get-ChildItem "$out\*.ttf" | ForEach-Object {
    Copy-Item $_.FullName -Destination $fontsDir -Force
    New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" `
        -Name "$($_.BaseName) (TrueType)" -Value "$fontsDir\$($_.Name)" -PropertyType String -Force | Out-Null
}
```

Configure a fonte no **Windows Terminal** (`settings.json`):
```json
"profiles": {
  "defaults": {
    "font": { "face": "CaskaydiaCove NF", "size": 11 }
  }
}
```

Ative o modo Nerd Font — adicione ao `~/.claude/settings.json`:
```json
{
  "env": {
    "CLAUDE_STATUSLINE_NERDFONT": "1"
  }
}
```

---

## Como Funciona

O Claude Code chama o `statusline.sh` após cada resposta, enviando o estado da sessão como JSON via stdin. O script:

1. Lê o JSON com uma **única chamada ao `jq`** (< 5ms)
2. Constrói barras de progresso com gradiente true-color
3. Calcula os tempos de reset a partir dos timestamps Unix `resets_at`
4. Imprime duas linhas — o Claude Code exibe na área de status

### Campos JSON utilizados

```
model.display_name
context_window.used_percentage
context_window.context_window_size
rate_limits.five_hour.used_percentage
rate_limits.five_hour.resets_at         ← Unix timestamp (segundos)
rate_limits.seven_day.used_percentage
rate_limits.seven_day.resets_at         ← Unix timestamp (segundos)
worktree.branch                         ← usado pelo CLAUDE_STATUSLINE_GIT (fallback para git command)
workspace.current_dir                   ← usado pelo CLAUDE_STATUSLINE_GIT / CLAUDE_STATUSLINE_PWD
cost.total_cost_usd                     ← usado pelo CLAUDE_STATUSLINE_COST
cost.total_lines_added                  ← usado pelo CLAUDE_STATUSLINE_COST
cost.total_lines_removed                ← usado pelo CLAUDE_STATUSLINE_COST
output_style.name                       ← exibido na linha 1 automaticamente quando não for "default"
```

> **Obs.:** Os dados de rate limit (`5h` / `7d`) só estão disponíveis nos planos Claude Pro e Max. O status line oculta esses segmentos automaticamente quando não disponíveis. Os campos `cost.*` e `output_style.name` assumem valor `0`/vazio quando ausentes, então esses segmentos degradam sem erros.

---

## Testes

```bash
bash test-mock.sh
```

Executa 10 cenários: normal, aviso (75%), perigo (92%), sem rate limits, sessão nova, output style, custo de sessão, linha 2 com branch, aviso de atualização e modo ASCII.

---

## Estrutura do Projeto

```
claude-statusline/
├── statusline.sh          # Script principal — chamado pelo Claude Code a cada resposta
├── update.sh              # Updater — execute para instalar uma nova versão
├── statusline-config.sh   # Configurador TUI interativo (setas + espaço)
├── install.sh             # Instalador (Git Bash / WSL / Linux)
├── install.ps1            # Instalador (PowerShell no Windows)
├── test-mock.sh           # Suite de testes com payloads JSON simulados
├── CLAUDE.md              # Contexto para o Claude Code ao trabalhar neste repositório
├── README.md              # Documentação em inglês
└── README.pt-BR.md        # Documentação em português
```

Após a instalação, `~/.claude/` conterá:

```
~/.claude/
├── statusline.sh          # Script principal (cópia)
├── statusline-update.sh   # Updater (cópia)
├── statusline-config.sh   # Configurador TUI (cópia)
└── settings.json          # Configurações do Claude Code (statusLine + env vars)
```

---

## Diferenças do Projeto Original

Este projeto é inspirado no [claude-code-statusline](https://github.com/KCChien/claude-code-statusline) de KC Chien. Diferenças principais:

| Funcionalidade | Original | Este projeto |
|----------------|----------|--------------|
| Plataforma | macOS | **Git Bash / PowerShell (Windows) e WSL/Linux** |
| Comando `stat` | BSD (`-f %m`) | GNU (`-c %Y`) |
| CRLF | Não necessário | `tr -d '\r'` no output do jq |
| Detecção true-color | `COLORTERM` | `COLORTERM` + `WT_SESSION` |
| Paths Windows | Não suportado | Converte `C:\caminho` → `/c/caminho` |
| Tempo de reset | Não implementado | Timestamp Unix `resets_at` |
| Layout | 2 linhas | **1 linha + 2ª linha opcional** |
| Notificações de update | Não | Verificação no GitHub + auto-updater |
| Interface de configuração | Não | Comando `/statusline-khalleb` + script TUI |

---

## Licença

MIT — veja [LICENSE](LICENSE).

Inspirado em [claude-code-statusline](https://github.com/KCChien/claude-code-statusline) © KC Chien.
