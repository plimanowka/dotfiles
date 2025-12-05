# Secrets Management

Encrypted secrets storage using SOPS + age. Secrets can be safely committed to git.

## How It Works

```
┌─────────────────┐     encrypt      ┌──────────────────────┐
│ ~/.aws/creds    │ ───────────────► │ aws-credentials.enc  │
│ ~/.ssh/id_rsa   │    (sops+age)    │ ssh-id_rsa.enc       │  ← Safe to commit
│ API keys        │                  │ shell-secrets.enc    │
└─────────────────┘                  └──────────────────────┘
                                              │
                         age-key.txt          │ decrypt
                      (KEEP THIS SAFE!)       │
                              │               ▼
                              │      ┌─────────────────┐
                              └────► │ Original files  │
                                     └─────────────────┘
```

## Quick Start

### First-time setup (on your main machine)

```bash
# 1. Import your existing secrets
~/.dotfiles/secrets/secrets-manager.sh import

# 2. Commit encrypted secrets to git
cd ~/.dotfiles
git add secrets/*.enc*
git commit -m "Add encrypted secrets"
git push

# 3. BACKUP YOUR AGE KEY!
# Store ~/.dotfiles/secrets/age-key.txt in:
# - Password manager (1Password, Bitwarden, etc.)
# - Secure note
# - Encrypted USB drive
```

### On a new machine

```bash
# 1. Clone dotfiles
git clone https://github.com/YOU/dotfiles.git ~/.dotfiles

# 2. Copy age key from your backup
# (paste from password manager, etc.)
nano ~/.dotfiles/secrets/age-key.txt

# 3. Run install
~/.dotfiles/install.sh

# 4. Decrypt secrets
~/.dotfiles/secrets/secrets-manager.sh export
```

## Commands

```bash
# Import secrets from system → encrypted files
secrets-manager.sh import

# Export encrypted files → system locations
secrets-manager.sh export

# Encrypt a single file
secrets-manager.sh encrypt ~/.aws/credentials

# Decrypt a single file (to stdout)
secrets-manager.sh decrypt aws-credentials.enc

# Edit encrypted file in place
secrets-manager.sh edit shell-secrets.enc.yaml

# List encrypted secrets
secrets-manager.sh list
```

## What Gets Encrypted

| Source | Encrypted File | Destination |
|--------|---------------|-------------|
| `~/.aws/credentials` | `aws-credentials.enc` | `~/.aws/credentials` |
| `~/.aws/config` | `aws-config.enc` | `~/.aws/config` |
| `~/.config/gcloud/*.json` | `gcp-*.enc.json` | `~/.config/gcloud/` |
| `~/.ssh/id_*` | `ssh-id_*.enc` | `~/.ssh/` |
| Shell env vars | `shell-secrets.enc.yaml` | `~/.dotfiles/shell/secrets.sh` |

## File Structure

```
~/.dotfiles/secrets/
├── .sops.yaml              # SOPS configuration
├── age-key.txt             # Master key (NEVER COMMIT!)
├── secrets-manager.sh      # Management script
├── aws-credentials.enc     # Encrypted AWS creds
├── aws-config.enc          # Encrypted AWS config
├── gcp-service-account.enc.json
├── ssh-id_rsa.enc          # Encrypted SSH key
├── ssh-id_ed25519.enc
└── shell-secrets.enc.yaml  # API keys, tokens
```

## Security Notes

### age-key.txt

- This is your master encryption key
- **NEVER commit to git** (already in .gitignore)
- Without it, secrets CANNOT be decrypted
- Store backup in password manager

### What's safe to commit

- All `*.enc` and `*.enc.yaml` and `*.enc.json` files
- `.sops.yaml` configuration
- `secrets-manager.sh` script

### Rotating secrets

```bash
# 1. Edit the encrypted file directly
secrets-manager.sh edit aws-credentials.enc

# 2. Or update source and re-import
# (edit ~/.aws/credentials, then)
secrets-manager.sh encrypt ~/.aws/credentials aws-credentials
```

### Rotating age key

If your age key is compromised:

```bash
# 1. Generate new key
age-keygen -o ~/.dotfiles/secrets/age-key-new.txt

# 2. Update .sops.yaml with new public key

# 3. Re-encrypt all secrets
for f in ~/.dotfiles/secrets/*.enc*; do
    sops --rotate -i "$f"
done

# 4. Replace old key
mv age-key-new.txt age-key.txt

# 5. Update backup in password manager
```

## Troubleshooting

**"Age key not found"**
- Copy `age-key.txt` from your backup/password manager

**"sops not installed"**
- macOS: `brew install sops age`
- Linux: See install.sh for manual installation

**"Could not decrypt"**
- Verify age-key.txt matches the public key in .sops.yaml
- Check file wasn't corrupted

## Adding New Secret Types

Edit `secrets-manager.sh` to add new secret types in `export_secrets()` and `import_secrets()` functions.

Example for adding a new secret:

```bash
# In import_secrets():
if [[ -f ~/.config/myapp/token ]]; then
    sops -e ~/.config/myapp/token > "$SECRETS_DIR/myapp-token.enc"
    success "myapp token encrypted"
fi

# In export_secrets():
if [[ -f "$SECRETS_DIR/myapp-token.enc" ]]; then
    mkdir -p ~/.config/myapp
    sops -d "$SECRETS_DIR/myapp-token.enc" > ~/.config/myapp/token
    chmod 600 ~/.config/myapp/token
    success "myapp token restored"
fi
```
