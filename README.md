# ide-configs

Backup of my Zed and VS Code configuration (settings, keybindings, tasks, snippets, extension lists) for macOS.

## How it works

The repo holds **copies** of the live config files. Two scripts move them in each direction:

```
 live editor config                          this repo                 GitHub
 ~/.config/zed/                --backup.sh-->  zed/        --git push-->  (private)
 ~/Library/Application Support/                vscode/
   Code/User/                  <--install.sh--
```

- `backup.sh` mirrors live config into the repo, regenerates both extension lists, and fails if anything looks like a secret.
- `install.sh` restores the repo onto a machine. It never deletes files; any existing file that differs is saved as `<file>.bak-<timestamp>` first. It also installs VS Code extensions through the `code` CLI.

## Layout

| Repo path | Source on macOS | What it is |
| --- | --- | --- |
| `zed/settings.json` | `~/.config/zed/settings.json` | Editor settings |
| `zed/keymap.json` | `~/.config/zed/keymap.json` | Keybindings (ported from VS Code, each annotated) |
| `zed/tasks.json` | `~/.config/zed/tasks.json` | Go test tasks bound in `keymap.json` |
| `zed/snippets/` | `~/.config/zed/snippets/` | Snippets |
| `zed/extensions.txt` | `~/Library/Application Support/Zed/extensions/installed/` | Installed extension IDs |
| `vscode/settings.json` | `~/Library/Application Support/Code/User/settings.json` | Editor settings |
| `vscode/keybindings.json` | `~/Library/Application Support/Code/User/keybindings.json` | Keybindings |
| `vscode/snippets/` | `~/Library/Application Support/Code/User/snippets/` | Snippets |
| `vscode/extensions.txt` | `code --list-extensions` | Installed extension IDs |

## Usage

Take a new snapshot after changing editor config:

```sh
./backup.sh
git diff            # review what changed
git commit -am "Update editor config" && git push
```

Restore on a new machine:

```sh
git clone git@github.com:juan-carl0s/ide-configs.git
cd ide-configs && ./install.sh
```

Zed has no CLI for installing extensions. Zed installs everything listed under `auto_install_extensions` in `zed/settings.json` on its next start; `zed/extensions.txt` is the reference list for anything else.

## Not backed up (on purpose)

- Caches, history, and per-workspace state (`History/`, `workspaceStorage/`, `globalStorage/`, `~/Library/Application Support/Zed/`): machine-specific and large.
- Zed prompts library (`~/.config/zed/prompts/`): a binary LMDB database that git cannot diff.
- `*.bak*` files: older copies of the files above.
- `~/.vscode/argv.json`: holds only a per-machine crash-reporter ID.
