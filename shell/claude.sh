# Claude Code multi-account support (one CLAUDE_CONFIG_DIR per account)
#
# ~/.claude         Claude Desktop + plain `claude` (whichever account is logged in
#                   there). Owns the shared ways-of-working (CLAUDE.md, rules, skills,
#                   commands, settings, plugins; git-tracked, see /wow-sync) and every
#                   project's auto-memory.
# ~/.claude-<name>  one per account: own login (keychain entry per dir), transcripts
#                   and .claude.json; everything shared is symlinked back into
#                   ~/.claude, so a lesson saved under one account is live in all.
#
# Setup, once per account: run `claude-plimanowka` / `claude-zamelduj` /
# `claude-loopme`, then /login in it.
# Launchers re-link on every start (picks up new skills and new projects' memory).

CLAUDE_HOME="$HOME/.claude"
CLAUDE_SHARED=(rules commands agents output-styles settings.json statusline-command.sh plugins)

_claude-acct-link() {
    local acct="$1" dir="$HOME/.claude-$1" item src p name
    if [[ -z "$acct" ]]; then
        echo "Usage: _claude-acct-link <account>   (links ~/.claude into ~/.claude-<account>)"
        return 1
    fi
    mkdir -p "$dir/skills" "$dir/projects"

    # Import, not symlink: Edit/Write refuse to write through a symlinked CLAUDE.md
    [[ -e "$dir/CLAUDE.md" ]] || echo "@$CLAUDE_HOME/CLAUDE.md" > "$dir/CLAUDE.md"

    for item in "${CLAUDE_SHARED[@]}"; do
        src="$CLAUDE_HOME/$item"
        [[ -e "$src" ]] || continue
        if [[ -e "$dir/$item" && ! -L "$dir/$item" ]]; then
            echo "claude-acct: $dir/$item is a real file, not a link (diverged? diff it with $src)" >&2
            continue
        fi
        ln -sfn "$src" "$dir/$item"
    done

    # ponytail: per-skill links, a symlinked skills/ dir stops loading (claude-code#38051).
    # skills/synced = claude.ai skills, each account syncs its own bucket.
    for src in "$CLAUDE_HOME"/skills/*(N/); do
        name="${src:t}"
        [[ "$name" == synced || -e "$dir/skills/$name" || -L "$dir/skills/$name" ]] || ln -s "$src" "$dir/skills/$name"
    done
    for p in "$dir"/skills/*(N-@); do rm "$p"; done  # skill deleted from ~/.claude

    # Memory a new project got under this account moves to ~/.claude, then gets linked back
    for p in "$dir"/projects/*/memory(N/); do
        name="${p:h:t}"
        if [[ -e "$CLAUDE_HOME/projects/$name/memory" ]]; then
            echo "claude-acct: $name has memory in both $dir and $CLAUDE_HOME, merge by hand" >&2
        else
            mkdir -p "$CLAUDE_HOME/projects/$name" && mv "$p" "$CLAUDE_HOME/projects/$name/memory"
        fi
    done
    for p in "$CLAUDE_HOME"/projects/*/memory(N); do
        name="${p:h:t}"
        [[ -e "$dir/projects/$name/memory" || -L "$dir/projects/$name/memory" ]] && continue
        mkdir -p "$dir/projects/$name" && ln -s "$p" "$dir/projects/$name/memory"
    done

    # User-scope MCP servers live in .claude.json (per account): seed once, after /login
    if [[ -f "$dir/.claude.json" ]] && ! jq -e '.mcpServers | length > 0' "$dir/.claude.json" >/dev/null; then
        jq --argjson m "$(jq '.mcpServers // {}' "$HOME/.claude.json")" '.mcpServers = $m' \
            "$dir/.claude.json" > "$dir/.claude.json.tmp" && mv "$dir/.claude.json.tmp" "$dir/.claude.json"
    fi
}

# _claude-acct <account> [claude args...]
_claude-acct() {
    local acct="$1"
    _claude-acct-link "$acct" || return
    shift
    CLAUDE_CONFIG_DIR="$HOME/.claude-$acct" command claude "$@"
}
claude-plimanowka() { _claude-acct plimanowka "$@"; }
claude-zamelduj()   { _claude-acct zamelduj "$@"; }
claude-loopme()     { _claude-acct loopme "$@"; }

# Company code always runs on the company account, even as plain `claude`
claude() {
    if [[ -z "$CLAUDE_CONFIG_DIR" && "$PWD/" == "$HOME/dev/loopme/"* ]]; then
        claude-loopme "$@"
    else
        command claude "$@"
    fi
}
