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

# Ghostty
if [[ "$(uname)" == "Darwin" ]] && ! [[ -d "/Applications/Ghostty.app" ]]; then
  echo "==> Installing Ghostty..."
  brew install --cask ghostty || echo "    Install Ghostty manually: https://ghostty.org"
fi

mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
GHOSTTY_CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
if [[ -f "$GHOSTTY_CONFIG" ]]; then
  cp "$GHOSTTY_CONFIG" "${GHOSTTY_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
  echo "    Backed up Ghostty config"
fi
cp "$CONFIGS/ghostty-config" "$GHOSTTY_CONFIG"
echo "==> Ghostty config installed"

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

# Nerd Font (required for Powerlevel10k icons)
if [[ "$(uname)" == "Darwin" ]]; then
  if ! brew list --cask font-meslo-lg-nerd-font &>/dev/null; then
    echo "==> Installing MesloLGS Nerd Font..."
    brew install --cask font-meslo-lg-nerd-font || true
  fi
  echo "    Set Ghostty font to 'MesloLGS Nerd Font' if icons look broken."
fi

echo ""
echo "Done! Open a new Ghostty window or run: exec zsh"
echo "Docs: $REPO_DIR/README.md"