# Claude Code Multi-Account Setup

Run Claude CLI with different accounts using long-lived OAuth tokens.
Supports concurrent sessions — run `claude-personal` and `claude-loopme` in separate terminals simultaneously.

## How It Works

Each account gets a long-lived OAuth token (valid for 1 year) via `claude setup-token`.
The wrapper functions set `CLAUDE_CODE_OAUTH_TOKEN` per-process, so no shared state conflicts.

```
~/.claude-profiles/
├── loopme-oauth      # LoopMe account token
└── personal-oauth    # Personal account token
```

## Commands

| Command | Description |
|---------|-------------|
| `claude-loopme` | Launch Claude with LoopMe account |
| `claude-personal` | Launch Claude with personal account |
| `claude-save-token <name> <token>` | Save an OAuth token to a profile |

## First-Time Setup

### 1. Generate personal token

```bash
claude auth login          # authenticate with personal Google account
claude setup-token         # authenticate again in browser, copies token
# Copy the sk-ant-oat01-... token from the output

claude-save-token personal sk-ant-oat01-...
```

### 2. Generate LoopMe token

```bash
claude auth logout
claude auth login          # authenticate with LoopMe Google account
claude setup-token         # authenticate again in browser
# Copy the sk-ant-oat01-... token from the output

claude-save-token loopme sk-ant-oat01-...
```

### 3. Use profiles

```bash
claude-personal            # Opens Claude with personal account
claude-loopme              # Opens Claude with LoopMe account

# Both can run simultaneously in different terminals!
claude-personal --help
claude-loopme /path/to/project
```

## Refreshing Tokens

Tokens are valid for 1 year. When one expires:

```bash
claude auth login          # login with the right account
claude setup-token         # generate a new token
claude-save-token <profile> <new-token>
```
