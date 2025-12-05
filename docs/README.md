# Dotfiles

Automated macOS/Linux setup with modular zsh configuration, developer tools, and encrypted secrets management.

## Quick Install (New Machine)

**Step 1:** Save your `age-key.txt` from password manager to `~/age-key.txt` on the new machine.

**Step 2:** Run this:

```bash
git clone https://github.com/plimanowka/dotfiles.git ~/.dotfiles && ~/.dotfiles/install.sh && mkdir -p ~/.dotfiles/secrets && mv ~/age-key.txt ~/.dotfiles/secrets/ && ~/.dotfiles/secrets/secrets-manager.sh export && cd ~/.dotfiles && git remote set-url origin git@github.com:plimanowka/dotfiles.git
```

That's it! This will:
1. Clone the repo via HTTPS (no SSH needed)
2. Install all packages (brew/apt), zsh config, tools
3. Move your age key to the secrets directory
4. Decrypt all secrets (SSH keys, AWS/GCP creds, API tokens)
5. Switch git remote to SSH (now that keys are restored)

---

## What's Included

### Shell
- **Starship prompt** - Fast, customizable prompt with git status, k8s context
- **Zsh syntax highlighting** - Commands colored as you type
- **thefuck** - Auto-correct previous command typos
- **micro editor** - Modern terminal editor with IDE-like keybindings

### CLI Tools
- **awscli** - AWS command line
- **bat** - Cat with syntax highlighting
- **btop/htop** - System monitors
- **jq/yq** - JSON/YAML processors
- **glow** - Markdown renderer

### Kubernetes
- **kubectl** - Kubernetes CLI
- **k9s** - Kubernetes TUI
- **krew** - kubectl plugin manager
- **stern** - Multi-pod log tailing

### Development
- **gradle/maven** - Java build tools
- **pipx/uv** - Python package managers
- **opentofu** - Infrastructure as code
- **sops** - Secrets management

### GUI Apps (Casks)
- **iTerm2** - Terminal emulator
- **draw.io** - Diagramming
- **Karabiner Elements** - Keyboard customization
- **Wireshark** - Network analysis

### Secrets Management
- **SOPS + age** - Encrypted secrets storage
- **AWS/GCP credentials** - Safely stored in git
- **SSH keys** - Encrypted backup
- **API tokens** - Centralized management

See `SECRETS.md` for details.

## Directory Structure

```
~/.dotfiles/
├── shell/              # Zsh runtime configs (symlinked to ~/.config/shell)
│   ├── aliases.sh      # Shell aliases
│   ├── completions.sh  # Zsh completions setup
│   ├── gcloud.sh       # Google Cloud SDK
│   ├── kubernetes.sh   # kubectl, krew, kpops, k8ctx
│   ├── sdkman.sh       # SDKMAN setup
│   ├── secrets.sh      # API keys (gitignored)
│   ├── show.sh         # Universal file viewer
│   ├── showimg.sh      # Image display
│   ├── starship.toml   # Prompt config
│   └── thefuck.sh      # Command correction
├── macos/              # macOS-specific setup
│   ├── Brewfile        # Homebrew packages
│   └── karabiner.json  # Keyboard config
├── linux/              # Linux-specific setup
│   ├── apt-packages.txt    # Debian/Ubuntu packages
│   ├── dnf-packages.txt    # Fedora/RHEL packages
│   └── install-tools.sh    # Tool installers (starship, micro, etc.)
├── secrets/            # Encrypted secrets (safe to commit)
│   ├── .sops.yaml      # SOPS configuration
│   ├── age-key.txt     # Master key (NEVER COMMIT!)
│   ├── secrets-manager.sh
│   └── *.enc*          # Encrypted files
├── docs/               # Documentation
│   ├── README.md       # This file
│   ├── EDIT.md         # micro editor cheat sheet
│   ├── SECRETS.md      # Secrets management guide
│   └── HOW-I-DID-THIS.md
├── install.sh          # Main setup script (macOS + Linux)
└── .gitignore
```

## Custom Commands

### kpops
Run kubectl across all `pop-*` contexts:
```bash
kpops get pods
kpops --help
```

### k8ctx
List Kubernetes contexts:
```bash
k8ctx
k8ctx | grep prod
```

### show
Universal file viewer:
```bash
show README.md          # Rendered markdown
show document.pdf       # PDF pages as images
show config.json        # Syntax highlighted
show photo.jpg          # Image in terminal
```

### edit
Terminal editor (micro):
```bash
edit file.txt
```
See `EDIT.md` for keybindings.

## Customization

### Adding Packages
Edit `~/.dotfiles/macos/Brewfile`, then:
```bash
brew bundle --file=~/.dotfiles/macos/Brewfile
```

### Shell Aliases
Edit `~/.dotfiles/shell/aliases.sh`

### Prompt
Edit `~/.dotfiles/shell/starship.toml`
See: https://starship.rs/config/

### Secrets
Add API keys to `~/.dotfiles/shell/secrets.sh` (gitignored)

## Manual Setup

Some things still need manual configuration:

1. **iTerm2**: Set Left Option Key to `Esc+` (Profiles → Keys → General)
2. **Nerd Font**: Install from https://www.nerdfonts.com/
3. **Karabiner**: May need to grant accessibility permissions

## Updating

```bash
cd ~/.dotfiles
git pull
brew bundle --file=macos/Brewfile
```

## Troubleshooting

**Icons not showing:** Install a Nerd Font and set it in iTerm2 preferences.

**Completions not working:** Run `rm -f ~/.zcompdump*` and restart terminal.

**Alt keys produce symbols:** Set Left Option Key to `Esc+` in iTerm2 (Profiles → Keys → General).
