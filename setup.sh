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

# Zed
if [[ "$(uname)" == "Darwin" ]]; then
  if ! [[ -d "/Applications/Zed.app" ]]; then
    echo "==> Installing Zed..."
    brew install --cask zed || echo "    Install Zed manually: https://zed.dev"
  fi

  ZED_CONFIG_DIR="$HOME/.config/zed"
  ZED_SETTINGS="$ZED_CONFIG_DIR/settings.json"
  mkdir -p "$ZED_CONFIG_DIR"
  if [[ -f "$ZED_SETTINGS" ]]; then
    cp "$ZED_SETTINGS" "${ZED_SETTINGS}.bak.$(date +%Y%m%d%H%M%S)"
    echo "    Backed up Zed settings"
    python3 - "$ZED_SETTINGS" "$CONFIGS/zed-settings.json" <<'PY'
import json, sys
from pathlib import Path

target = Path(sys.argv[1])
patch = json.loads(Path(sys.argv[2]).read_text())
current = json.loads(target.read_text())
current.update(patch)
target.write_text(json.dumps(current, indent=2) + "\n")
PY
    echo "==> Zed terminal settings merged into existing config"
  else
    cp "$CONFIGS/zed-settings.json" "$ZED_SETTINGS"
    echo "==> Zed settings installed (~/.config/zed/settings.json)"
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

# Nerd Font (required for Powerlevel10k icons)
if [[ "$(uname)" == "Darwin" ]]; then
  if ! brew list --cask font-meslo-lg-nerd-font &>/dev/null; then
    echo "==> Installing MesloLGS Nerd Font..."
    brew install --cask font-meslo-lg-nerd-font || true
  fi
  echo "    MesloLGS NF is used by Ghostty + Zed terminal for Powerlevel10k icons."
fi

echo ""
echo "Done! Open Ghostty or Zed terminal, or run: exec zsh"
echo "Docs: $REPO_DIR/README.md"