#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GHOSTTY_CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

YES=false
PURGE=false

for arg in "$@"; do
  case "$arg" in
    -y|--yes) YES=true ;;
    --purge) PURGE=true ;;
    -h|--help)
      cat <<'EOF'
Usage: ./remove.sh [options]

Undo what setup.sh installed. Restores shell config backups when available.

Options:
  -y, --yes   Skip confirmation prompt
  --purge     Also uninstall Ghostty app and MesloLGS Nerd Font (Homebrew)
  -h, --help  Show this help

Does NOT uninstall Homebrew or Oh My Zsh.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg (try --help)"
      exit 1
      ;;
  esac
done

if [[ "$YES" != true ]]; then
  echo "This will:"
  echo "  - Restore ~/.zshrc, ~/.zprofile, ~/.p10k.zsh from backups (or delete if no backup)"
  echo "  - Restore/remove Ghostty config"
  echo "  - Remove powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting from Oh My Zsh"
  echo "  - Clear Powerlevel10k instant-prompt cache"
  if [[ "$PURGE" == true ]]; then
    echo "  - Uninstall Ghostty + MesloLGS Nerd Font (brew)"
  fi
  echo ""
  read -r -p "Continue? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
fi

restore_latest_backup() {
  local file="$1"
  local latest
  latest="$(ls -t "${file}.bak."* 2>/dev/null | head -1 || true)"

  if [[ -n "$latest" ]]; then
    cp "$latest" "$file"
    echo "==> Restored $file from $(basename "$latest")"
  elif [[ -f "$file" ]]; then
    rm "$file"
    echo "==> Removed $file (no backup found)"
  else
    echo "==> $file not present, skipping"
  fi
}

restore_latest_backup "$HOME/.zshrc"
restore_latest_backup "$HOME/.zprofile"
restore_latest_backup "$HOME/.p10k.zsh"

latest_ghostty="$(ls -t "${GHOSTTY_CONFIG}.bak."* 2>/dev/null | head -1 || true)"
if [[ -n "$latest_ghostty" ]]; then
  mkdir -p "$(dirname "$GHOSTTY_CONFIG")"
  cp "$latest_ghostty" "$GHOSTTY_CONFIG"
  echo "==> Restored Ghostty config from $(basename "$latest_ghostty")"
elif [[ -f "$GHOSTTY_CONFIG" ]]; then
  rm "$GHOSTTY_CONFIG"
  echo "==> Removed Ghostty config (no backup found)"
fi

remove_dir_if_exists() {
  local dir="$1" label="$2"
  if [[ -d "$dir" ]]; then
    rm -rf "$dir"
    echo "==> Removed $label"
  fi
}

remove_dir_if_exists "$ZSH_CUSTOM/themes/powerlevel10k" "powerlevel10k theme"
remove_dir_if_exists "$ZSH_CUSTOM/plugins/zsh-autosuggestions" "zsh-autosuggestions"
remove_dir_if_exists "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"

P10K_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"
if [[ -f "$P10K_CACHE" ]]; then
  rm "$P10K_CACHE"
  echo "==> Cleared p10k instant-prompt cache"
fi

if [[ "$PURGE" == true ]] && command -v brew >/dev/null 2>&1; then
  if brew list --cask ghostty &>/dev/null; then
    brew uninstall --cask ghostty
    echo "==> Uninstalled Ghostty"
  fi
  if brew list --cask font-meslo-lg-nerd-font &>/dev/null; then
    brew uninstall --cask font-meslo-lg-nerd-font
    echo "==> Uninstalled MesloLGS Nerd Font"
  fi
fi

echo ""
echo "Done. Open a new terminal or run: exec zsh"
echo "Homebrew and Oh My Zsh were left installed."