#!/usr/bin/env bash
# Copy the live Zed and VS Code config into this repo so it can be committed.
# Only the copies inside the repo are written; the editors' own files are never touched.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZED_CONFIG="$HOME/.config/zed"
ZED_EXTENSIONS="$HOME/Library/Application Support/Zed/extensions/installed"
VSCODE_USER="$HOME/Library/Application Support/Code/User"

ZED_FILES=(settings.json keymap.json tasks.json)
VSCODE_FILES=(settings.json keybindings.json)

copy_file() {
  local source_path="$1" dest_path="$2"
  if [[ ! -f "$source_path" ]]; then
    echo "skipped $source_path (not found)" >&2
    return
  fi
  mkdir -p "$(dirname "$dest_path")"
  cp "$source_path" "$dest_path"
  echo "copied  $source_path"
}

# --delete makes the repo an exact mirror, so a snippet file removed in the editor
# also disappears from the backup instead of lingering forever.
sync_dir() {
  local source_dir="$1" dest_dir="$2"
  if [[ ! -d "$source_dir" ]]; then
    echo "skipped $source_dir (not found)" >&2
    return
  fi
  mkdir -p "$dest_dir"
  rsync -a --delete "$source_dir/" "$dest_dir/"
  echo "synced  $source_dir/"
}

echo "== Zed =="
for file in "${ZED_FILES[@]}"; do
  copy_file "$ZED_CONFIG/$file" "$REPO_DIR/zed/$file"
done
sync_dir "$ZED_CONFIG/snippets" "$REPO_DIR/zed/snippets"
# Zed has no CLI for listing extensions; each installed extension is a folder here.
if [[ -d "$ZED_EXTENSIONS" ]]; then
  find "$ZED_EXTENSIONS" -mindepth 1 -maxdepth 1 -exec basename {} \; | sort > "$REPO_DIR/zed/extensions.txt"
  echo "listed  $(wc -l < "$REPO_DIR/zed/extensions.txt" | tr -d ' ') Zed extensions"
fi

echo "== VS Code =="
for file in "${VSCODE_FILES[@]}"; do
  copy_file "$VSCODE_USER/$file" "$REPO_DIR/vscode/$file"
done
sync_dir "$VSCODE_USER/snippets" "$REPO_DIR/vscode/snippets"
# Versions are left out on purpose: a restore should pull current releases, and
# unpinned IDs keep the diff quiet when extensions auto-update.
if command -v code >/dev/null 2>&1; then
  code --list-extensions | sort > "$REPO_DIR/vscode/extensions.txt"
  echo "listed  $(wc -l < "$REPO_DIR/vscode/extensions.txt" | tr -d ' ') VS Code extensions"
else
  echo "skipped VS Code extension list ('code' CLI not on PATH)" >&2
fi

# Settings files occasionally pick up API keys from extensions; catch them before a commit.
secret_pattern='(api[_-]?key|secret|password|bearer |access[_-]?token|auth[_-]?token|sk-[A-Za-z0-9]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|xox[abp]-)'
if grep -rniE "$secret_pattern" "$REPO_DIR/zed" "$REPO_DIR/vscode"; then
  echo
  echo "WARNING: possible secrets above. Review before committing." >&2
  exit 1
fi

echo
echo "Done. Review with: git -C \"$REPO_DIR\" diff"
