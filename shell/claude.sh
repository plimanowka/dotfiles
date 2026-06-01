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

claude() {
    command claude --permission-mode auto "$@"
}

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

# Local LiteLLM proxy exposing an Anthropic-compatible endpoint on
# http://0.0.0.0:4000. It forwards the client's Authorization header straight
# through to Anthropic, so callers (e.g. kpi-agent's local profile) send a
# Claude OAuth token as the bearer and the proxy never stores a key itself.
#
#   claude-proxy            # run on default port 4000
#   claude-proxy --port 8080
#   claude-proxy --detailed_debug
#
# Extra args are passed straight to `litellm`.
claude-proxy() {
    local config="$HOME/.config/shell/litellm/claude-proxy-config.yaml"

    if ! command -v litellm >/dev/null 2>&1; then
        echo "litellm not found. Install with one of:"
        echo "  uv tool install 'litellm[proxy]'"
        echo "  pipx install 'litellm[proxy]'"
        return 1
    fi

    if [[ ! -f "$config" ]]; then
        echo "Config not found: $config"
        return 1
    fi

    litellm --config "$config" "$@"
}

# Export the loopme Claude OAuth token into the current shell as
# ANTHROPIC_OAUTH_TOKEN, so callers that read it (e.g. kpi-agent's local
# profile -> claude-proxy) pick it up without copy-pasting the token.
#   claude-as-loopme        # sets ANTHROPIC_OAUTH_TOKEN for this shell
claude-as-loopme() {
    local token_file="$CLAUDE_PROFILES_DIR/loopme-oauth"
    if [[ ! -f "$token_file" ]]; then
        echo "No loopme token found. Run: claude-save-token loopme <token>"
        return 1
    fi
    export ANTHROPIC_OAUTH_TOKEN="$(cat "$token_file")"
    echo "ANTHROPIC_OAUTH_TOKEN set from loopme profile."
}
