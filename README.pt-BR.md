# claude-statusline

Status line minimalista e de linha única para o [Claude Code](https://claude.ai/code) rodando no **Git Bash no Windows**.

Exibe modelo, uso do contexto, limite da sessão atual e limite semanal — tudo em uma linha, atualizado após cada resposta.

> 📖 [Read in English](README.md)

---

## Preview

```
 Sonnet 4.6 (200K context) │  ███░░░░░░░░░░░░░░░░░ 16% │ 5h ██░░░░░░░░ 31% ↺ 2h 33m │ 7d ↺ 2d
```

| Segmento | Descrição |
|----------|-----------|
| ` Sonnet 4.6` | Modelo atual |
| `(200K context)` | Tamanho do context window |
| `███░░░ 16%` | Barra de uso do contexto |
| `5h ██░░░ 31% ↺ 2h 33m` | Barra de uso da sessão de 5h + tempo para reset |
| `7d ↺ 2d` | Tempo para reset da sessão semanal |

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

---

## Instalação

**1. Clone o repositório:**
```bash
git clone https://github.com/SEU_USUARIO/claude-statusline.git
cd claude-statusline
```

**2. Execute o instalador:**
```bash
bash install.sh
```

O instalador irá:
- Verificar se o `jq` está disponível
- Copiar `statusline.sh` para `~/.claude/statusline.sh`
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

Ative o modo Nerd Font no `~/.bashrc`:
```bash
export CLAUDE_STATUSLINE_NERDFONT=1
```

---

## Variáveis de Ambiente

| Variável | Valor | Efeito |
|----------|-------|--------|
| `CLAUDE_STATUSLINE_NERDFONT` | `1` | Ativa ícones Nerd Font (requer CaskaydiaCove NF) |
| `CLAUDE_STATUSLINE_ASCII` | `1` | Força modo ASCII puro (sem Unicode, sem cores) |
| `CLAUDE_STATUSLINE_DEBUG` | `1` | Grava o JSON em `/tmp/claude-sl-debug.json` para inspeção |

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
rate_limits.five_hour.resets_at       ← Unix timestamp (segundos)
rate_limits.seven_day.used_percentage
rate_limits.seven_day.resets_at       ← Unix timestamp (segundos)
```

> **Obs.:** Os dados de rate limit (`5h` / `7d`) só estão disponíveis nos planos Claude Pro e Max. O status line oculta esses segmentos automaticamente quando não disponíveis.

---

## Testes

```bash
bash test-mock.sh
```

Executa 5 cenários: normal, aviso (75%), perigo (92%), sem rate limits e sessão nova.

---

## Estrutura do Projeto

```
claude-statusline/
├── statusline.sh      # Script principal — chamado pelo Claude Code a cada resposta
├── install.sh         # Instalador — copia o script e configura o settings.json
├── test-mock.sh       # Suite de testes com payloads JSON simulados
├── README.md          # Documentação em inglês
└── README.pt-BR.md    # Documentação em português
```

---

## Diferenças do Projeto Original

Este projeto é inspirado no [claude-code-statusline](https://github.com/KCChien/claude-code-statusline) de KC Chien. Diferenças principais:

| Funcionalidade | Original | Este projeto |
|----------------|----------|--------------|
| Plataforma | macOS | **Git Bash (Windows)** |
| Comando `stat` | BSD (`-f %m`) | GNU (`-c %Y`) |
| CRLF | Não necessário | `tr -d '\r'` no output do jq |
| Detecção true-color | `COLORTERM` | `COLORTERM` + `WT_SESSION` |
| Paths Windows | Não suportado | Converte `C:\caminho` → `/c/caminho` |
| Tempo de reset | Não implementado | Timestamp Unix `resets_at` |
| Layout | 2 linhas | **1 linha** |

---

## Licença

MIT — veja [LICENSE](LICENSE).

Inspirado em [claude-code-statusline](https://github.com/KCChien/claude-code-statusline) © KC Chien.
