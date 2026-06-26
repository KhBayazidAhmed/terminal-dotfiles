#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS="$REPO_DIR/configs"

echo "==> Terminal dotfiles setup"
echo "    Repo: $REPO_DIR"

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# cmux (Ghostty-based terminal)
if [[ "$(uname)" == "Darwin" ]]; then
  if ! [[ -d "/Applications/cmux.app" ]]; then
    echo "==> Installing cmux..."
    brew tap manaflow-ai/cmux 2>/dev/null || true
    brew install --cask cmux || echo "    Install cmux manually: https://cmux.com"
  fi

  CMUX_TERMINAL_CONFIG="$HOME/.config/ghostty/config"
  mkdir -p "$(dirname "$CMUX_TERMINAL_CONFIG")"
  if [[ -f "$CMUX_TERMINAL_CONFIG" ]]; then
    cp "$CMUX_TERMINAL_CONFIG" "${CMUX_TERMINAL_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
    echo "    Backed up cmux terminal config"
  fi
  cp "$CONFIGS/cmux-terminal-config" "$CMUX_TERMINAL_CONFIG"
  echo "==> cmux terminal config installed (~/.config/ghostty/config)"

  mkdir -p "$HOME/.local/bin"
  if [[ -x "/Applications/cmux.app/Contents/Resources/bin/cmux" ]]; then
    ln -sf "/Applications/cmux.app/Contents/Resources/bin/cmux" "$HOME/.local/bin/cmux"
    echo "==> cmux CLI linked to ~/.local/bin/cmux"
  fi
fi

# Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "==> Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Plugins & theme
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_plugin() {
  local name="$1" repo="$2" dest="$ZSH_CUSTOM/$3"
  if [[ ! -d "$dest" ]]; then
    echo "==> Installing $name..."
    git clone --depth=1 "$repo" "$dest"
  else
    echo "==> $name already installed"
  fi
}

install_plugin "powerlevel10k" "https://github.com/romkatv/powerlevel10k.git" "themes/powerlevel10k"
install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git" "plugins/zsh-autosuggestions"
install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git" "plugins/zsh-syntax-highlighting"

# Shell configs (backup existing, then copy)
backup_if_exists() {
  local file="$1"
  if [[ -f "$file" ]]; then
    cp "$file" "${file}.bak.$(date +%Y%m%d%H%M%S)"
    echo "    Backed up $file"
  fi
}

backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.zprofile"
backup_if_exists "$HOME/.p10k.zsh"

cp "$CONFIGS/zshrc" "$HOME/.zshrc"
cp "$CONFIGS/zprofile" "$HOME/.zprofile"
cp "$CONFIGS/p10k.zsh" "$HOME/.p10k.zsh"
echo "==> zsh configs installed"

echo ""
echo "Done! Open cmux, or run: exec zsh"
echo "Zed settings are not managed by this repo — configure ~/.config/zed/settings.json yourself."
echo "Docs: $REPO_DIR/README.md"