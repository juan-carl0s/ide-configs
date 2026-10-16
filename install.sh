#!/usr/bin/env bash
# Restore the Zed and VS Code config stored in this repo onto this machine.
# Nothing is deleted: any existing file that differs is first saved as <file>.bak-<timestamp>.
set -euo pipefail
shopt -s nullglob

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZED_CONFIG="$HOME/.config/zed"
VSCODE_USER="$HOME/Library/Application Support/Code/User"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

restore_file() {
  local source_path="$1" dest_path="$2"
  mkdir -p "$(dirname "$dest_path")"
  if [[ -e "$dest_path" ]] && ! cmp -s "$source_path" "$dest_path"; then
    cp "$dest_path" "$dest_path.bak-$TIMESTAMP"
    echo "saved    $dest_path.bak-$TIMESTAMP"
  fi
  cp "$source_path" "$dest_path"
  echo "restored $dest_path"
}

echo "== Zed =="
for source_path in "$REPO_DIR"/zed/*.json "$REPO_DIR"/zed/snippets/*; do
  relative_path="${source_path#"$REPO_DIR"/zed/}"
  restore_file "$source_path" "$ZED_CONFIG/$relative_path"
done

echo "== VS Code =="
for source_path in "$REPO_DIR"/vscode/*.json "$REPO_DIR"/vscode/snippets/*; do
  relative_path="${source_path#"$REPO_DIR"/vscode/}"
  restore_file "$source_path" "$VSCODE_USER/$relative_path"
done

if command -v code >/dev/null 2>&1; then
  echo "== VS Code extensions =="
  while IFS= read -r extension_id; do
    [[ -n "$extension_id" ]] && code --install-extension "$extension_id"
  done < "$REPO_DIR/vscode/extensions.txt"
else
  echo "skipped VS Code extensions ('code' CLI not on PATH; run 'Shell Command: Install code in PATH' in VS Code)" >&2
fi

echo
echo "Zed extensions have no install CLI. Zed installs the ones under \"auto_install_extensions\""
echo "in zed/settings.json on its next start; install any others from zed/extensions.txt via cmd-shift-x."
