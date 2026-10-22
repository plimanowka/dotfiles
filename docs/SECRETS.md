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
                    sops/age/keys.txt         │ decrypt
                   (this machine's key)       │
                              │               ▼
                              │      ┌─────────────────┐
                              └────► │ Original files  │
                                     └─────────────────┘
```

Every file is encrypted to all recipients listed in `.sops.yaml` (repo root), so any one of
their private keys can decrypt it:

| Recipient | Private key lives in |
|-----------|----------------------|
| One key per machine | that machine's SOPS default key file (see below) |
| Offline backup key | printout + private 1Password, never on disk |
| Shared key `age1lzu42…` (legacy) | key files of machines without their own key yet; remove once every machine has one |

The same recipient list is used by the zamelduj repo.

SOPS default key file: `~/Library/Application Support/sops/age/keys.txt` on macOS,
`~/.config/sops/age/keys.txt` on Linux (`$XDG_CONFIG_HOME/sops/age/keys.txt` if set,
`$SOPS_AGE_KEY_FILE` overrides). One file can hold several keys.

## Quick Start

### On a new machine

```bash
# 1. Clone dotfiles
git clone https://github.com/YOU/dotfiles.git ~/.dotfiles

# 2. Run install
~/.dotfiles/install.sh

# 3. Give the machine its own key (see "Adding a machine"), or to decrypt right away,
#    append the offline backup key to the SOPS default key file

# 4. Decrypt secrets
~/.dotfiles/secrets/secrets-manager.sh export
```

### Adding a machine

```bash
# On the new machine (macOS path; Linux: ~/.config/sops/age)
mkdir -p ~/Library/Application\ Support/sops/age
age-keygen -o ~/Library/Application\ Support/sops/age/keys.txt   # prints the public key

# On a machine that can decrypt: add the public key to .sops.yaml, then
cd ~/.dotfiles
for f in secrets/*.enc*; do sops updatekeys -y "$f"; done
git commit -am "Add <machine> age recipient" && git push

# Back on the new machine
git pull && ~/.dotfiles/secrets/secrets-manager.sh export
```

Removing a machine works the same way (drop its line from `.sops.yaml`, run `updatekeys`).
That does NOT revoke access to ciphertext already in git history — rotate the actual secret
values if the removed key may be compromised.

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
~/.dotfiles/
├── .sops.yaml                  # Recipients (age public keys)
└── secrets/
    ├── secrets-manager.sh      # Management script
    ├── aws-credentials.enc     # Encrypted AWS creds
    ├── aws-config.enc          # Encrypted AWS config
    ├── gcp-*.enc.json
    ├── ssh-id_ed25519_*.enc    # Encrypted SSH keys
    └── shell-secrets.enc.yaml  # API keys, tokens
```

## Security Notes

### Private keys

- Never inside the repo checkout (old `secrets/age-key.txt` stays in .gitignore as a guard)
- Lose every machine key → decrypt with the offline backup key
- Lose the backup too → secrets CANNOT be decrypted

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

### Rotating a compromised key

```bash
# 1. Remove its public key from .sops.yaml (add a fresh one if it was a machine key)

# 2. Re-key and rotate the data key of every file
for f in secrets/*.enc*; do
    sops updatekeys -y "$f" && sops --rotate -i "$f"
done

# 3. Rotate the secret values themselves — old ciphertext stays in git history
```

## Troubleshooting

**"Age key not found"**
- No key in the SOPS default key file — see "Adding a machine"

**"sops not installed"**
- macOS: `brew install sops age`
- Linux: See install.sh for manual installation

**"Could not decrypt"**
- `age-keygen -y <key file>` must print a public key listed in `.sops.yaml`
- A recipient added to `.sops.yaml` only applies after `sops updatekeys`

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
