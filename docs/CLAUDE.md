# Claude Code Multi-Account Setup

Run Claude CLI with different accounts using profile switching.

## How It Works

Claude Code stores credentials in macOS Keychain. These scripts swap the keychain entry before launching Claude, allowing multiple accounts.

```
~/.claude-profiles/
├── loopme-token      # LoopMe account credentials
└── personal-token    # Personal account credentials
```

## Commands

| Command | Description |
|---------|-------------|
| `claude-loopme` | Launch Claude with LoopMe account |
| `claude-personal` | Launch Claude with personal account |
| `claude-save-profile <name>` | Save current credentials to a profile |

## First-Time Setup

### 1. Save LoopMe account

```bash
# Login with LoopMe account
claude
# In Claude: /logout
# Re-authenticate in browser with LoopMe Google account
# Exit Claude (Ctrl+C or /exit)

# Save credentials
claude-save-profile loopme
```

### 2. Save personal account

```bash
# Login with personal account
claude
# In Claude: /logout
# Re-authenticate in browser with personal Google account
# Exit Claude

# Save credentials
claude-save-profile personal
```

### 3. Use profiles

```bash
claude-loopme           # Opens Claude with LoopMe account
claude-personal         # Opens Claude with personal account

# Pass arguments as usual
claude-loopme --help
claude-personal /path/to/project
```

## Browser Authentication Tips

When Claude opens the browser for authentication, it uses whichever Chrome window/profile receives the URL. To control which account authenticates:

1. **Copy URL method**: When prompted, press `c` to copy the OAuth URL instead of auto-opening. Paste it into the correct Chrome profile/window.

2. **Sign out first**: Before authenticating, sign out of claude.ai in the "wrong" browser window.

3. **Use Chrome profiles**: For best isolation, use separate Chrome profiles (not just windows) for each Google account.

## Refreshing Credentials

If a profile's credentials expire:

```bash
# Login fresh and re-save
claude
# /logout, re-authenticate
# exit

claude-save-profile <profile-name>
```

## Adding More Profiles

Edit `~/.dotfiles/shell/claude.sh` to add more profile functions:

```bash
claude-newprofile() {
    _claude_switch_profile "newprofile" && claude "$@"
}
```

Then save credentials: `claude-save-profile newprofile`