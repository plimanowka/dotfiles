#!/bin/bash
# Secrets manager - encrypt/decrypt secrets with SOPS + age

set -e

SECRETS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGE_KEY="$SECRETS_DIR/age-key.txt"
SOPS_CONFIG="$SECRETS_DIR/.sops.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check dependencies
check_deps() {
    command -v sops &>/dev/null || error "sops not installed. Run: brew install sops"
    command -v age &>/dev/null || error "age not installed. Run: brew install age"
    [[ -f "$AGE_KEY" ]] || error "Age key not found: $AGE_KEY"
}

usage() {
    cat <<EOF
Secrets Manager - Encrypt/decrypt secrets with SOPS + age

Usage: $(basename "$0") <command> [options]

Commands:
  encrypt <file>      Encrypt a file (creates .enc version)
  decrypt <file>      Decrypt a .enc file
  edit <file>         Edit encrypted file in place
  export              Decrypt all secrets to their destinations
  import              Collect secrets from system and encrypt
  list                List encrypted secrets

Examples:
  $(basename "$0") encrypt ~/.aws/credentials
  $(basename "$0") decrypt aws-credentials.enc
  $(basename "$0") export
  $(basename "$0") import

Secrets are stored encrypted in: $SECRETS_DIR
Age key location: $AGE_KEY

IMPORTANT: Keep age-key.txt safe! Without it, secrets cannot be decrypted.
           Store a backup in a secure location (password manager, etc.)
EOF
}

# Encrypt a file
encrypt_file() {
    local src="$1"
    local name="${2:-$(basename "$src")}"
    local dest="$SECRETS_DIR/${name}.enc"

    [[ -f "$src" ]] || error "File not found: $src"

    export SOPS_AGE_KEY_FILE="$AGE_KEY"
    sops --config "$SOPS_CONFIG" -e "$src" > "$dest"
    success "Encrypted: $src -> $dest"
}

# Decrypt a file
decrypt_file() {
    local src="$1"
    local dest="$2"

    [[ -f "$src" ]] || error "File not found: $src"

    export SOPS_AGE_KEY_FILE="$AGE_KEY"
    if [[ -n "$dest" ]]; then
        sops --config "$SOPS_CONFIG" -d "$src" > "$dest"
        success "Decrypted: $src -> $dest"
    else
        sops --config "$SOPS_CONFIG" -d "$src"
    fi
}

# Edit encrypted file
edit_file() {
    local src="$1"
    [[ -f "$src" ]] || error "File not found: $src"

    export SOPS_AGE_KEY_FILE="$AGE_KEY"
    sops --config "$SOPS_CONFIG" "$src"
}

# Export all secrets to their destinations
export_secrets() {
    info "Exporting secrets..."
    export SOPS_AGE_KEY_FILE="$AGE_KEY"

    # AWS credentials
    if [[ -f "$SECRETS_DIR/aws-credentials.enc" ]]; then
        mkdir -p ~/.aws
        sops -d "$SECRETS_DIR/aws-credentials.enc" > ~/.aws/credentials
        chmod 600 ~/.aws/credentials
        success "AWS credentials -> ~/.aws/credentials"
    fi

    # AWS config
    if [[ -f "$SECRETS_DIR/aws-config.enc" ]]; then
        mkdir -p ~/.aws
        sops -d "$SECRETS_DIR/aws-config.enc" > ~/.aws/config
        chmod 600 ~/.aws/config
        success "AWS config -> ~/.aws/config"
    fi

    # GCP service account
    if [[ -f "$SECRETS_DIR/gcp-service-account.enc.json" ]]; then
        mkdir -p ~/.config/gcloud
        sops -d "$SECRETS_DIR/gcp-service-account.enc.json" > ~/.config/gcloud/service-account.json
        chmod 600 ~/.config/gcloud/service-account.json
        success "GCP service account -> ~/.config/gcloud/service-account.json"
    fi

    # SSH keys
    for keyfile in "$SECRETS_DIR"/ssh-*.enc; do
        [[ -f "$keyfile" ]] || continue
        local keyname=$(basename "$keyfile" .enc)
        keyname=${keyname#ssh-}  # Remove ssh- prefix
        mkdir -p ~/.ssh
        sops -d "$keyfile" > ~/.ssh/"$keyname"
        chmod 600 ~/.ssh/"$keyname"
        success "SSH key -> ~/.ssh/$keyname"
    done

    # Shell secrets (API keys, etc.)
    if [[ -f "$SECRETS_DIR/shell-secrets.enc.yaml" ]]; then
        # Extract and create secrets.sh
        sops -d "$SECRETS_DIR/shell-secrets.enc.yaml" | \
            grep -E "^[A-Z_]+:" | \
            sed 's/: /="/; s/$/"/' | \
            sed 's/^/export /' > ~/.dotfiles/shell/secrets.sh
        success "Shell secrets -> ~/.dotfiles/shell/secrets.sh"
    fi

    success "All secrets exported!"
}

# Import secrets from system
import_secrets() {
    info "Importing secrets..."
    export SOPS_AGE_KEY_FILE="$AGE_KEY"

    # AWS credentials
    if [[ -f ~/.aws/credentials ]]; then
        sops --config "$SOPS_CONFIG" -e ~/.aws/credentials > "$SECRETS_DIR/aws-credentials.enc"
        success "~/.aws/credentials -> aws-credentials.enc"
    fi

    # AWS config
    if [[ -f ~/.aws/config ]]; then
        sops --config "$SOPS_CONFIG" -e ~/.aws/config > "$SECRETS_DIR/aws-config.enc"
        success "~/.aws/config -> aws-config.enc"
    fi

    # GCP service accounts (look for JSON files)
    for sa in ~/.config/gcloud/*.json; do
        [[ -f "$sa" ]] || continue
        local name=$(basename "$sa" .json)
        sops --config "$SOPS_CONFIG" -e "$sa" > "$SECRETS_DIR/gcp-${name}.enc.json"
        success "$sa -> gcp-${name}.enc.json"
    done

    # SSH private keys
    for key in ~/.ssh/id_*; do
        [[ -f "$key" ]] || continue
        [[ "$key" == *.pub ]] && continue  # Skip public keys
        local keyname=$(basename "$key")
        sops --config "$SOPS_CONFIG" -e "$key" > "$SECRETS_DIR/ssh-${keyname}.enc"
        success "$key -> ssh-${keyname}.enc"
    done

    # Shell secrets
    if [[ -f ~/.dotfiles/shell/secrets.sh ]]; then
        # Convert to YAML format for sops
        grep "^export " ~/.dotfiles/shell/secrets.sh | \
            sed 's/^export //; s/=/: /' > /tmp/shell-secrets.yaml
        sops --config "$SOPS_CONFIG" -e /tmp/shell-secrets.yaml > "$SECRETS_DIR/shell-secrets.enc.yaml"
        rm /tmp/shell-secrets.yaml
        success "Shell secrets -> shell-secrets.enc.yaml"
    fi

    success "Import complete! Encrypted files in: $SECRETS_DIR"
    warn "Remember to commit encrypted files to git"
}

# List encrypted secrets
list_secrets() {
    echo "Encrypted secrets in $SECRETS_DIR:"
    echo ""
    for f in "$SECRETS_DIR"/*.enc "$SECRETS_DIR"/*.enc.json "$SECRETS_DIR"/*.enc.yaml; do
        [[ -f "$f" ]] || continue
        echo "  $(basename "$f")"
    done
}

# Main
check_deps

case "${1:-}" in
    encrypt)
        [[ -n "${2:-}" ]] || error "Usage: $0 encrypt <file> [name]"
        encrypt_file "$2" "${3:-}"
        ;;
    decrypt)
        [[ -n "${2:-}" ]] || error "Usage: $0 decrypt <file> [output]"
        decrypt_file "$2" "${3:-}"
        ;;
    edit)
        [[ -n "${2:-}" ]] || error "Usage: $0 edit <file>"
        edit_file "$2"
        ;;
    export)
        export_secrets
        ;;
    import)
        import_secrets
        ;;
    list)
        list_secrets
        ;;
    *)
        usage
        ;;
esac
