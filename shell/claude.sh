# Claude Code multi-account support
# See docs/CLAUDE.md for setup instructions

CLAUDE_PROFILES_DIR="$HOME/.claude-profiles"

_claude_switch_profile() {
    local profile="$1"
    local token_file="$CLAUDE_PROFILES_DIR/${profile}-token"

    if [[ ! -f "$token_file" ]]; then
        echo "Profile '$profile' not found. Run setup first:"
        echo "  See: ~/.dotfiles/docs/CLAUDE.md"
        return 1
    fi

    # Swap keychain credential
    security delete-generic-password -s "Claude Code-credentials" 2>/dev/null
    security add-generic-password -s "Claude Code-credentials" -a "$(whoami)" \
        -w "$(cat "$token_file")" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        echo "Switched to Claude profile: $profile"
    else
        echo "Failed to switch profile"
        return 1
    fi
}

claude-loopme() {
    _claude_switch_profile "loopme" && claude "$@"
}

claude-personal() {
    _claude_switch_profile "personal" && claude "$@"
}

# Save current Claude credentials to a profile
claude-save-profile() {
    local profile="$1"

    if [[ -z "$profile" ]]; then
        echo "Usage: claude-save-profile <profile-name>"
        echo "Example: claude-save-profile loopme"
        return 1
    fi

    mkdir -p "$CLAUDE_PROFILES_DIR"
    chmod 700 "$CLAUDE_PROFILES_DIR"

    local token_file="$CLAUDE_PROFILES_DIR/${profile}-token"

    if ! security find-generic-password -s "Claude Code-credentials" -w > "$token_file" 2>/dev/null; then
        echo "No Claude credentials found in keychain."
        echo "Login first with: claude"
        return 1
    fi

    chmod 600 "$token_file"
    echo "Saved current Claude credentials to profile: $profile"
}