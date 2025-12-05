# micro - Terminal Editor Cheat Sheet

A modern terminal editor with IDE-like keybindings.

## Getting Help Inside micro

| Key | Action |
|-----|--------|
| `Alt+G` | Toggle key menu in status bar |
| `Ctrl+E` then `help` | Open help document |
| `Ctrl+E` then `help keybindings` | Full keybinding list |
| `Ctrl+E` then `help commands` | All commands |
| `Ctrl+E` then `help options` | All settings |

**Note:** micro doesn't have a traditional menu bar. Use:
- `Ctrl+E` → command bar (type commands)
- `Alt+G` → shows available keys in status bar

## Basic

| Key | Action |
|-----|--------|
| `Ctrl+S` | Save |
| `Ctrl+Q` | Quit |
| `Ctrl+Z` | Undo |
| `Ctrl+Y` | Redo |

## Navigation

| Key | Action |
|-----|--------|
| `Alt+←/→` | Word left/right |
| `Home/End` | Line start/end |
| `Ctrl+Home/End` | File start/end |
| `Ctrl+↑/↓` | Scroll without moving cursor |
| `Ctrl+G` | Go to line |
| `Ctrl+L` | Go to line (same) |

## Selection & Clipboard

| Key | Action |
|-----|--------|
| `Shift+arrows` | Select |
| `Shift+Alt+←/→` | Select word |
| `Shift+Home/End` | Select to line start/end |
| `Ctrl+A` | Select all |
| `Ctrl+C` | Copy |
| `Ctrl+X` | Cut |
| `Ctrl+V` | Paste |
| `Ctrl+D` | Duplicate line (no selection) |

## Multi-cursor (VSCode-style)

| Key | Action |
|-----|--------|
| `Ctrl+D` | Select next occurrence |
| `Alt+Shift+↑/↓` | Add cursor above/below |
| `Ctrl+Click` | Add cursor at click |
| `Escape` | Remove all cursors except primary |

## Search & Replace

| Key | Action |
|-----|--------|
| `Ctrl+F` | Find |
| `Ctrl+N` | Find next |
| `Ctrl+P` | Find previous |
| `Ctrl+H` | Find & replace |

## Lines

| Key | Action |
|-----|--------|
| `Ctrl+D` | Duplicate line |
| `Ctrl+K` | Delete line |
| `Alt+↑/↓` | Move line up/down |

## Panes & Tabs

| Key | Action |
|-----|--------|
| `Ctrl+E` | Command bar |
| `Ctrl+W` | Next split |
| `Ctrl+T` | New tab |
| `Alt+,` | Previous tab |
| `Alt+.` | Next tab |

## Commands (via `Ctrl+E`)

```
vsplit filename    # Vertical split
hsplit filename    # Horizontal split
tab filename       # Open in new tab
set option value   # Change setting
help               # Show help
```

## Mouse

- Click to position cursor
- Drag to select
- Double-click to select word
- Triple-click to select line
- Ctrl+Click for multi-cursor
- Scroll wheel works

## Tips

1. Press `Alt+G` to toggle key menu (shows bindings in status bar)
2. Use `Ctrl+E` then type `help keybindings` for full list
3. Config file: `~/.config/micro/settings.json`
4. Install plugins: `micro -plugin install pluginname`

## Useful Plugins

Install via `Ctrl+E` → `plugin install name`:

- `filemanager` - sidebar file tree
- `jump` - quick file navigation
- `quoter` - surround with quotes/brackets
- `manipulator` - case conversion tools
