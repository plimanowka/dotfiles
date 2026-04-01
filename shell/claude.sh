# Claude Code multi-account support
# Uses long-lived OAuth tokens (from `claude setup-token`) with
# CLAUDE_CODE_OAUTH_TOKEN env var. Each terminal gets its own token,
# so concurrent sessions with different accounts work.
#
# Setup:
#   1. claude auth login   (login as personal)
#   2. claude setup-token  (copy the token)
#   3. claude-save-token personal <token>
#   4. claude auth logout && claude auth login  (login as loopme)
#   5. claude setup-token  (copy the token)
#   6. claude-save-token loopme <token>

CLAUDE_PROFILES_DIR="$HOME/.claude-profiles"

claude-save-token() {
    local profile="$1"
    local token="$2"

    if [[ -z "$profile" || -z "$token" ]]; then
        echo "Usage: claude-save-token <profile-name> <token>"
        echo "Example: claude-save-token personal sk-ant-oat01-..."
        return 1
    fi

    mkdir -p "$CLAUDE_PROFILES_DIR"
    chmod 700 "$CLAUDE_PROFILES_DIR"

    local token_file="$CLAUDE_PROFILES_DIR/${profile}-oauth"
    printf '%s' "$token" > "$token_file"
    chmod 600 "$token_file"
    echo "Saved OAuth token for profile: $profile"
}

claude-personal() {
    local token_file="$CLAUDE_PROFILES_DIR/personal-oauth"
    if [[ ! -f "$token_file" ]]; then
        echo "No personal token found. Run: claude-save-token personal <token>"
        return 1
    fi
    CLAUDE_CODE_OAUTH_TOKEN="$(cat "$token_file")" CLAUDE_PROFILE="personal" claude "$@"
}

claude-loopme() {
    local token_file="$CLAUDE_PROFILES_DIR/loopme-oauth"
    if [[ ! -f "$token_file" ]]; then
        echo "No loopme token found. Run: claude-save-token loopme <token>"
        return 1
    fi
    CLAUDE_CODE_OAUTH_TOKEN="$(cat "$token_file")" CLAUDE_PROFILE="loopme" claude "$@"
}
