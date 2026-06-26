# Terminal Dotfiles

Personal terminal setup: **Ghostty** + **zsh** + **Oh My Zsh** + **Powerlevel10k** + suggestion plugins.

Repo: [github.com/KhBayazidAhmed/terminal-dotfiles](https://github.com/KhBayazidAhmed/terminal-dotfiles)

---

## Quick setup on a new device

```bash
git clone https://github.com/KhBayazidAhmed/terminal-dotfiles.git
cd terminal-dotfiles
chmod +x setup.sh
./setup.sh
```

Then open **Ghostty** (or run `exec zsh` in any terminal).

## Remove config

Undo everything `setup.sh` applied:

```bash
cd terminal-dotfiles
chmod +x remove.sh
./remove.sh
```

| Option | What it does |
|---|---|
| `./remove.sh` | Restore shell + Ghostty backups, remove plugins/theme, clear p10k cache |
| `./remove.sh -y` | Same, no confirmation prompt |
| `./remove.sh --purge` | Also uninstall Ghostty app + Nerd Font via Homebrew |

**Not removed:** Homebrew, Oh My Zsh, the cloned repo folder.

`setup.sh` saves timestamped backups before overwriting (e.g. `~/.zshrc.bak.20260626120000`). `remove.sh` restores the newest backup for each file.

### Manual remove (no script)

```bash
# Restore latest backup (example for .zshrc)
cp "$(ls -t ~/.zshrc.bak.* | head -1)" ~/.zshrc

rm -f ~/.p10k.zsh
rm -f ~/Library/Application\ Support/com.mitchellh.ghostty/config
rm -rf ~/.oh-my-zsh/custom/themes/powerlevel10k
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
rm -f ~/.cache/p10k-instant-prompt-*.zsh

exec zsh
```

### What `setup.sh` does

1. Installs **Homebrew** (if missing)
2. Installs **Ghostty** via Homebrew cask (macOS)
3. Copies Ghostty config to `~/Library/Application Support/com.mitchellh.ghostty/config`
4. Installs **Oh My Zsh** (if missing)
5. Clones **powerlevel10k**, **zsh-autosuggestions**, **zsh-syntax-highlighting**
6. Backs up and installs `~/.zshrc`, `~/.zprofile`, `~/.p10k.zsh`
7. Installs **MesloLGS Nerd Font** (for prompt icons)

### After setup

Set Ghostty font to **MesloLGS Nerd Font** if prompt icons show as boxes.

This repo is **terminal-only** — no dev tool PATH or completions (pnpm, bun, rust, grok, dex, etc.). Add those in a separate shell config on each machine if you need them.

---

## Ghostty settings

**Config file:** `~/Library/Application Support/com.mitchellh.ghostty/config`

| Setting | Value |
|---|---|
| Theme | `Detuned` |
| Font size | `20` (thickened) |
| Cursor | Bar, blinking |
| Window | Maximized on launch |
| Subtitle | Working directory |
| Padding | 10px horizontal, 5px vertical |
| Bold | Treated as bright |
| Shift+Enter | Insert newline (`\x1b\r`) |
| Desktop notifications | Off |
| Auto-update | Off |

**Environment:** `TERM=xterm-ghostty`, `TERM_PROGRAM=ghostty`

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
├── setup.sh               # One-command new device setup
├── remove.sh              # Undo setup / restore backups
└── configs/
    ├── ghostty-config     # Ghostty terminal settings
    ├── zshrc              # Main shell config
    ├── zprofile           # Login shell (Homebrew)
    └── p10k.zsh           # Powerlevel10k prompt config
```

---

## Sync changes to GitHub

After editing configs on your machine:

```bash
cd terminal-dotfiles

# Update repo copies from live configs
cp ~/Library/Application\ Support/com.mitchellh.ghostty/config configs/ghostty-config
cp ~/.p10k.zsh configs/p10k.zsh
# Edit configs/zshrc and configs/zprofile directly — do not copy from ~/.zshrc
# (your live shell may have extra dev-tool PATH entries)

git add -A
git commit -m "Update terminal configs"
git push
```

On another device:

```bash
cd terminal-dotfiles
git pull
./setup.sh
```

---

## VS Code / Cursor terminal setting

If using Cursor or VS Code with an external terminal:

```json
"terminal.explorerKind": "external"
```

This opens **Ghostty** instead of the built-in terminal panel.