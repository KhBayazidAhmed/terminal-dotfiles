#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS="$REPO_DIR/configs"

echo "==> Safe sync: machine → repo"
echo "    Only copies terminal-safe files. Never touches secrets."
echo ""

copy_if_exists() {
  local src="$1" dest="$2" label="$3"
  if [[ -f "$src" ]]; then
    cp "$src" "$dest"
    echo "    ✓ $label"
  else
    echo "    ⊘ $label (not found, skipped)"
  fi
}

copy_if_exists "$HOME/.config/ghostty/config" "$CONFIGS/cmux-terminal-config" "cmux terminal config"
copy_if_exists "$HOME/.p10k.zsh" "$CONFIGS/p10k.zsh" "Powerlevel10k prompt"

echo ""
echo "==> Checking configs/zed-settings.json for secrets..."

if grep -qiE 'api_key|api_url|api_token|password|secret|token|ctx7sk|openai_compatible|language_models|context_servers|agent_servers' "$CONFIGS/zed-settings.json" 2>/dev/null; then
  echo "ERROR: configs/zed-settings.json may contain private data."
  echo "       Keep only the terminal block (font, shell, cursor)."
  echo "       Do NOT copy your full ~/.config/zed/settings.json."
  exit 1
fi
echo "    ✓ zed-settings.json looks safe"

echo ""
echo "==> Manual files (edit in repo, do not copy from live machine):"
echo "    • configs/zshrc"
echo "    • configs/zprofile"
echo "    • configs/zed-settings.json  (terminal keys only)"
echo ""
echo "Next steps:"
echo "  git diff"
echo "  git add -A && git commit -m 'Update terminal configs' && git push"
echo ""
echo "On another device:"
echo "  git pull && ./setup.sh"