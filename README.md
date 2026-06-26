# Terminal Dotfiles

Personal terminal setup: **cmux** + **Zed** + **zsh** + **Oh My Zsh** + **Powerlevel10k** + suggestion plugins.

Repo: [github.com/KhBayazidAhmed/terminal-dotfiles](https://github.com/KhBayazidAhmed/terminal-dotfiles)

---

## Quick setup on a new device

```bash
git clone https://github.com/KhBayazidAhmed/terminal-dotfiles.git
cd terminal-dotfiles
chmod +x setup.sh
./setup.sh
```

Then open **cmux** or **Zed** terminal (or run `exec zsh` in any terminal).

## Remove config

Undo everything `setup.sh` applied:

```bash
cd terminal-dotfiles
chmod +x remove.sh
./remove.sh
```

| Option | What it does |
|---|---|
| `./remove.sh` | Restore shell + cmux/Zed backups, remove plugins/theme, clear p10k cache |
| `./remove.sh -y` | Same, no confirmation prompt |
| `./remove.sh --purge` | Also uninstall cmux, Zed, and Nerd Font via Homebrew |

**Not removed:** Homebrew, Oh My Zsh, the cloned repo folder.

`setup.sh` saves timestamped backups before overwriting (e.g. `~/.zshrc.bak.20260626120000`). `remove.sh` restores the newest backup for each file.

### Manual remove (no script)

```bash
# Restore latest backup (example for .zshrc)
cp "$(ls -t ~/.zshrc.bak.* | head -1)" ~/.zshrc

rm -f ~/.p10k.zsh
rm -f ~/.config/ghostty/config
rm -f ~/.local/bin/cmux
rm -f ~/.config/zed/settings.json
rm -rf ~/.oh-my-zsh/custom/themes/powerlevel10k
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
rm -f ~/.cache/p10k-instant-prompt-*.zsh

exec zsh
```

### What `setup.sh` does

1. Installs **Homebrew** (if missing)
2. Installs **cmux** via Homebrew tap + cask (macOS)
3. Installs **Zed** via Homebrew cask (macOS)
4. Copies terminal config to `~/.config/ghostty/config` (cmux reads this)
5. Links **cmux CLI** to `~/.local/bin/cmux`
6. Merges Zed **terminal-only** settings into `~/.config/zed/settings.json`
7. Installs **Oh My Zsh** (if missing)
8. Clones **powerlevel10k**, **zsh-autosuggestions**, **zsh-syntax-highlighting**
9. Backs up and installs `~/.zshrc`, `~/.zprofile`, `~/.p10k.zsh`
10. Installs **MesloLGS Nerd Font** (for prompt icons in cmux + Zed)

### After setup

Restart cmux or Zed, or run `cmux reload-config` after editing terminal config.

Restart Zed terminal tab (`Ctrl+~`) so the Nerd Font loads there too.

This repo is **terminal-only** — no dev tool PATH or completions (pnpm, bun, rust, grok, dex, etc.). Add those in a separate shell config on each machine if you need them.

---

## cmux settings

cmux is a Ghostty-based macOS terminal. Terminal rendering uses **Ghostty config format**.

**Config file:** `~/.config/ghostty/config` (cmux checks this first)

| Setting | Value |
|---|---|
| Theme | `Detuned` |
| Font | `MesloLGS NF` (Powerlevel10k icons) |
| Font size | `20` (thickened) |
| Cursor | Bar, blinking |
| Window | Maximized on launch |
| Subtitle | Working directory |
| Padding | 10px horizontal, 5px vertical |
| Bold | Treated as bright |
| Shift+Enter | Insert newline (`\x1b\r`) |
| Desktop notifications | Off |
| Auto-update | Off |

**cmux app settings** (shortcuts, sidebar, etc.) live separately in `~/.config/cmux/cmux.json` — not included in this repo.

**Reload after edits:** `cmux reload-config` or `Cmd+Shift+,`

**Install cmux manually:**

```bash
brew tap manaflow-ai/cmux
brew install --cask cmux
```

---

## Zed settings

**Config file:** `~/.config/zed/settings.json`

The repo ships a **terminal-only** Zed config (no API keys or agent settings):

| Setting | Value |
|---|---|
| Terminal font | `MesloLGS NF` (required for Powerlevel10k icons) |
| Terminal font size | `16` |
| Line height | `standard` (better for prompts / box drawing) |
| Cursor | Bar, blinking |
| Shell | `/bin/zsh` |
| Working directory | Current project directory |

**Why icons broke before:** Zed terminal had no `font_family` set. cmux and Zed each need their own font setting (cmux via `~/.config/ghostty/config`, Zed via `settings.json`).

**Test icons in Zed terminal:**

```bash
echo "󰀵  󰉋  󰘬"
```

Merge your own Zed editor/agent settings into `~/.config/zed/settings.json` after setup — the repo config only covers terminal essentials.

---

## Shell config

### Startup order

```
.zprofile  →  Homebrew
     ↓
.zshrc     →  p10k instant prompt → Oh My Zsh → plugins → ~/.p10k.zsh
```

### Prompt — Powerlevel10k

- Theme: `powerlevel10k/powerlevel10k`
- Style: lean, 2-line, Nerd Font icons (`configs/p10k.zsh`)
- Instant prompt at top of `.zshrc` for fast shell startup

### Active Oh My Zsh plugins

```zsh
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
```

`zsh-syntax-highlighting` must stay **last** in the plugins list.

### Installed but not active

These exist under `~/.oh-my-zsh/custom/plugins/` but are **not** loaded:

- `zsh-autocomplete`
- `fast-syntax-highlighting`

---

## How suggestions work

Three layers run together while you type:

```
You type
   ├─ zsh-autosuggestions   → gray ghost text (history)
   ├─ zsh-syntax-highlighting → colored command text
   └─ Tab completion        → menu / path completion
```

### 1. Ghost suggestions — `zsh-autosuggestions`

| | |
|---|---|
| **What you see** | Faded gray text after the cursor |
| **Source** | `history` strategy (most recent matching command) |
| **Color** | `fg=8` (dim gray) |
| **Mode** | Async (zsh 5.0.8+) |

**Accept a suggestion:**

| Key | Action |
|---|---|
| `→` (Right arrow) | Accept full suggestion |
| `End` | Accept full suggestion |
| `Alt+F` / forward-word | Accept one word at a time |

Keep typing to ignore or update the suggestion.

**Optional — also suggest from Tab completions:**

```zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
```

Add to `~/.zshrc` before `source $ZSH/oh-my-zsh.sh`.

### 2. Syntax highlighting — `zsh-syntax-highlighting`

| | |
|---|---|
| **What you see** | Commands, paths, flags colored live |
| **Highlighter** | `main` (default) |
| **Purpose** | Colors only — not suggestions |

### 3. Tab completion — Oh My Zsh + zsh

| Setting | Effect |
|---|---|
| Case-insensitive | `Docker` matches `docker` |
| Partial-word | `doc` → `docker` |
| `menu select` | Arrow keys in completion list |
| `auto_menu` | Second Tab opens full menu |
| `use-cache` | Faster repeat completions |

---

## File map

```
terminal-dotfiles/
├── README.md              # This file
├── setup.sh               # Install + apply configs on a new device
├── remove.sh              # Undo setup / restore backups
├── sync.sh                # Safe machine → repo sync (no secrets)
└── configs/
    ├── cmux-terminal-config  # cmux terminal settings (Ghostty config format)
    ├── zed-settings.json  # Zed terminal font + shell settings
    ├── zshrc              # Main shell config
    ├── zprofile           # Login shell (Homebrew)
    └── p10k.zsh           # Powerlevel10k prompt config
```

---

## Sync guideline

This repo is **public** and **terminal-only**. Follow these rules so personal data never gets pushed.

### Safe to sync (included in repo)

| Repo file | Live file | How to update |
|---|---|---|
| `configs/cmux-terminal-config` | `~/.config/ghostty/config` | Auto-copied by `sync.sh` |
| `configs/p10k.zsh` | `~/.p10k.zsh` | Auto-copied by `sync.sh` |
| `configs/zshrc` | `~/.zshrc` | Edit in repo only |
| `configs/zprofile` | `~/.zprofile` | Edit in repo only |
| `configs/zed-settings.json` | `~/.config/zed/settings.json` | Edit terminal block in repo only |

### Never sync (keep on your machine)

| File | Why |
|---|---|
| Full `~/.config/zed/settings.json` | API keys, agents, MCP, language models |
| Live `~/.zshrc` | Dev tool PATH (pnpm, bun, grok, dex, etc.) |
| `~/.config/cmux/cmux.json` | App shortcuts, automation, personal prefs |
| `~/.claude/`, `~/.cursor/`, tokens | Credentials |
| Backup files (`*.bak.*`) | Old personal configs |

### Push changes (this Mac → GitHub)

```bash
cd terminal-dotfiles
chmod +x sync.sh
./sync.sh          # copies safe files + checks for secrets
git diff           # review before committing
git add -A
git commit -m "Update terminal configs"
git push
```

`sync.sh` copies cmux + p10k configs and blocks push if `zed-settings.json` contains suspicious keys.

### Pull changes (GitHub → another Mac)

```bash
cd terminal-dotfiles
git pull
./setup.sh         # backs up live files, then applies repo configs
```

### Pre-push checklist

- [ ] Ran `./sync.sh` (or manually updated only safe files)
- [ ] `git diff` shows no API keys, tokens, or `/Users/yourname` paths
- [ ] `configs/zed-settings.json` contains **only** `terminal`, `cursor_shape`, `autosave`
- [ ] Did **not** `cp ~/.zshrc configs/zshrc`
- [ ] Did **not** `cp ~/.config/zed/settings.json configs/zed-settings.json`

### Update Zed terminal settings safely

Edit `configs/zed-settings.json` directly — keep it like this:

```json
{
  "autosave": "on_focus_change",
  "cursor_shape": "bar",
  "terminal": {
    "font_family": "MesloLGS NF",
    "font_size": 16.0,
    "line_height": "standard",
    "cursor_shape": "bar",
    "blinking": "on",
    "shell": { "program": "/bin/zsh" },
    "working_directory": "current_project_directory"
  }
}
```

Your full Zed config (agents, API URLs, MCP) stays in `~/.config/zed/settings.json` on each machine only.

### Reconfigure Powerlevel10k

```bash
p10k configure
./sync.sh
git add configs/p10k.zsh && git commit -m "Update p10k prompt" && git push
```

---

## VS Code / Cursor external terminal

If using Cursor or VS Code with an external terminal, point it at **cmux** instead of the built-in panel. cmux does not replace Zed's integrated terminal — Zed still needs `terminal.font_family` in its own settings.