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
  echo "    MesloLGS NF is used by cmux + Zed terminal for Powerlevel10k icons."
fi

echo ""
echo "Done! Open cmux or Zed terminal, or run: exec zsh"
echo "Docs: $REPO_DIR/README.md"