# Claude Code Multi-Account Setup

Several Claude accounts in parallel, one `CLAUDE_CONFIG_DIR` per account (`shell/claude.sh`).
All accounts share the same ways-of-working and project memory.

## Layout

```
~/.claude                Claude Desktop + plain `claude`; owns the shared ways-of-working
                         (CLAUDE.md, rules, skills, commands, settings, plugins) and all
                         project memory. Git repo, synced across machines by /wow-sync.
~/.claude-<account>/     own login (keychain entry per dir), transcripts, .claude.json;
                         shared items are symlinks back into ~/.claude
```

## Commands

| Command | Account |
|---------|---------|
| `claude-plimanowka` | plimanowka (gmail) |
| `claude-zamelduj` | zamelduj |
| `claude-loopme` | loopme (work) |
| `claude` in `~/dev/loopme/**` | loopme, automatically |

Each launcher re-links on start: new skills and new projects' memory show up in every account.

## First-Time Setup

Run the launcher, then `/login` with that account; check with `/status`. The first session may ask
to approve rules loaded from outside the project directory.

## Gotchas

- Claude Desktop supports one account at a time; it always uses `~/.claude`.
- A launcher warning "is a real file, not a link" means Claude replaced a shared file (usually
  `settings.json`) in that account's dir: diff it with `~/.claude/...`, merge, delete, re-run.
- "memory in both": the same project got memory under two accounts before linking; merge into
  `~/.claude/projects/<dir>/memory`, delete the other, re-run.
- New machine: see "New machine" in `~/.claude/skills/wow-sync/SKILL.md`.
