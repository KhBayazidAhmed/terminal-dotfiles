#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMUX_TERMINAL_CONFIG="$HOME/.config/ghostty/config"
ZED_SETTINGS="$HOME/.config/zed/settings.json"
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
  --purge     Also uninstall cmux, Zed, and FiraCode Nerd Font (Homebrew)
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
  echo "  - Restore/remove cmux terminal config"
  echo "  - Restore/remove Zed config"
  echo "  - Remove powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting from Oh My Zsh"
  echo "  - Clear Powerlevel10k instant-prompt cache"
  echo "  - Remove ~/.local/bin/cmux symlink"
  if [[ "$PURGE" == true ]]; then
    echo "  - Uninstall cmux + Zed + FiraCode Nerd Font (brew)"
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

restore_latest_backup "$CMUX_TERMINAL_CONFIG"

latest_zed="$(ls -t "${ZED_SETTINGS}.bak."* 2>/dev/null | head -1 || true)"
if [[ -n "$latest_zed" ]]; then
  mkdir -p "$(dirname "$ZED_SETTINGS")"
  cp "$latest_zed" "$ZED_SETTINGS"
  echo "==> Restored Zed settings from $(basename "$latest_zed")"
elif [[ -f "$ZED_SETTINGS" ]]; then
  rm "$ZED_SETTINGS"
  echo "==> Removed Zed settings (no backup found)"
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

if [[ -L "$HOME/.local/bin/cmux" ]]; then
  rm "$HOME/.local/bin/cmux"
  echo "==> Removed cmux CLI symlink"
fi

P10K_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"
if [[ -f "$P10K_CACHE" ]]; then
  rm "$P10K_CACHE"
  echo "==> Cleared p10k instant-prompt cache"
fi

if [[ "$PURGE" == true ]] && command -v brew >/dev/null 2>&1; then
  if brew list --cask cmux &>/dev/null; then
    brew uninstall --cask cmux
    echo "==> Uninstalled cmux"
  fi
  if brew list --cask zed &>/dev/null; then
    brew uninstall --cask zed
    echo "==> Uninstalled Zed"
  fi
  if brew list --cask font-fira-code-nerd-font &>/dev/null; then
    brew uninstall --cask font-fira-code-nerd-font
    echo "==> Uninstalled FiraCode Nerd Font"
  fi
fi

echo ""
echo "Done. Open a new terminal or run: exec zsh"
echo "Homebrew and Oh My Zsh were left installed."