#!/bin/bash
set -e

# ============================================
# Dotfiles Bootstrap Script (macOS + Linux)
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
section() { echo -e "\n${CYAN}=== $1 ===${NC}\n"; }

DOTFILES_DIR="$HOME/.dotfiles"
OS="$(uname -s)"

# ============================================
# Pre-flight checks
# ============================================
case "$OS" in
    Darwin) IS_MACOS=true; IS_LINUX=false ;;
    Linux)  IS_MACOS=false; IS_LINUX=true ;;
    *)      error "Unsupported OS: $OS" ;;
esac

section "Dotfiles Setup ($OS)"
echo "This will install and configure:"
echo "  - Package manager & packages"
echo "  - Zsh shell configuration"
echo "  - Starship prompt"
echo "  - micro editor"
$IS_MACOS && echo "  - Karabiner Elements config"
echo "  - Secrets management (SOPS + age)"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# ============================================
# Package Manager
# ============================================
section "Package Manager"

if $IS_MACOS; then
    # Homebrew for macOS
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
        success "Homebrew installed"
    else
        success "Homebrew already installed"
    fi

    info "Installing packages from Brewfile..."
    brew bundle --file="$DOTFILES_DIR/macos/Brewfile" || warn "Some packages may have failed"
    success "Homebrew packages installed"

    ZSH_HIGHLIGHT_PATH="/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
else
    # Linux package installation
    if command -v apt-get &>/dev/null; then
        info "Installing packages via apt..."
        sudo apt-get update
        sudo apt-get install -y \
            zsh \
            git \
            curl \
            wget \
            jq \
            tree \
            htop \
            fzf \
            bat \
            ripgrep \
            zsh-syntax-highlighting

        # Install starship
        if ! command -v starship &>/dev/null; then
            info "Installing starship..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi

        # Install micro
        if ! command -v micro &>/dev/null; then
            info "Installing micro..."
            curl https://getmic.ro | bash
            sudo mv micro /usr/local/bin/
        fi

        # Install sops
        if ! command -v sops &>/dev/null; then
            info "Installing sops..."
            SOPS_VERSION=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | jq -r .tag_name)
            curl -LO "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64"
            sudo mv "sops-${SOPS_VERSION}.linux.amd64" /usr/local/bin/sops
            sudo chmod +x /usr/local/bin/sops
        fi

        # Install age
        if ! command -v age &>/dev/null; then
            info "Installing age..."
            sudo apt-get install -y age || {
                AGE_VERSION=$(curl -s https://api.github.com/repos/FiloSottile/age/releases/latest | jq -r .tag_name)
                curl -LO "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz"
                tar xzf "age-${AGE_VERSION}-linux-amd64.tar.gz"
                sudo mv age/age age/age-keygen /usr/local/bin/
                rm -rf age "age-${AGE_VERSION}-linux-amd64.tar.gz"
            }
        fi

        # Install thefuck
        if ! command -v thefuck &>/dev/null; then
            pip3 install --user thefuck || warn "thefuck installation failed"
        fi

        # Install GitHub CLI
        if ! command -v gh &>/dev/null; then
            info "Installing GitHub CLI..."
            (
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y gh
            )
            success "GitHub CLI installed"
        fi

        success "Linux packages installed"
        ZSH_HIGHLIGHT_PATH="/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

    elif command -v dnf &>/dev/null; then
        info "Installing packages via dnf..."
        sudo dnf install -y zsh git curl wget jq tree htop
        # Add more packages as needed
        ZSH_HIGHLIGHT_PATH="/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    else
        warn "Unknown package manager. Install packages manually."
        ZSH_HIGHLIGHT_PATH=""
    fi
fi

# ============================================
# SDKMAN
# ============================================
section "SDKMAN"

if [[ ! -d "$HOME/.sdkman" ]]; then
    info "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
    success "SDKMAN installed"
else
    success "SDKMAN already installed"
fi

# ============================================
# Krew (kubectl plugin manager)
# ============================================
section "Krew"

if command -v kubectl &>/dev/null; then
    if [[ ! -d "$HOME/.krew" ]]; then
        info "Setting up krew..."
        (
            cd "$(mktemp -d)"
            KREW_OS="$(uname | tr '[:upper:]' '[:lower:]')"
            KREW_ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/arm64/arm64/' -e 's/aarch64/arm64/')"
            KREW="krew-${KREW_OS}_${KREW_ARCH}"
            curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz"
            tar zxvf "${KREW}.tar.gz"
            ./"${KREW}" install krew
        ) >/dev/null 2>&1
        success "krew installed"
    else
        success "krew already installed"
    fi
else
    warn "kubectl not found, skipping krew"
fi

# ============================================
# Shell Configuration
# ============================================
section "Shell Configuration"

# Create symlink for shell configs
SHELL_CONFIG_DIR="$HOME/.config/shell"
if [[ -L "$SHELL_CONFIG_DIR" ]]; then
    success "Shell config symlink exists"
elif [[ -d "$SHELL_CONFIG_DIR" ]]; then
    backup_dir="$SHELL_CONFIG_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    warn "Backing up existing shell config to $backup_dir"
    mv "$SHELL_CONFIG_DIR" "$backup_dir"
    ln -s "$DOTFILES_DIR/shell" "$SHELL_CONFIG_DIR"
    success "Shell config symlinked"
else
    mkdir -p "$HOME/.config"
    ln -s "$DOTFILES_DIR/shell" "$SHELL_CONFIG_DIR"
    success "Shell config symlinked"
fi

# Create ~/.zfunc for custom completions
mkdir -p "$HOME/.zfunc"

# ============================================
# .zshrc
# ============================================
section "Zsh Configuration"

if [[ -f "$HOME/.zshrc" ]]; then
    backup_file="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$HOME/.zshrc" "$backup_file"
    warn "Existing .zshrc backed up to $backup_file"
fi

info "Installing .zshrc..."

# Determine paths based on OS
if $IS_MACOS; then
    LIBPQ_PATH='export PATH="/opt/homebrew/opt/libpq/bin:$PATH"'
else
    LIBPQ_PATH='# libpq path (set if needed)'
fi

cat > "$HOME/.zshrc" << ZSHRC
# Starship prompt
export STARSHIP_CONFIG=~/.config/shell/starship.toml
eval "\$(starship init zsh)"

# iTerm2 shell integration (macOS)
test -e "\${HOME}/.iterm2_shell_integration.zsh" && source "\${HOME}/.iterm2_shell_integration.zsh"

# Aliases
source ~/.config/shell/aliases.sh

# thefuck
source ~/.config/shell/thefuck.sh

# PATH additions
export PATH="\$PATH:\$HOME/.local/bin"              # pipx
$LIBPQ_PATH

# Tool PATH setup (before completions)
source ~/.config/shell/gcloud.sh

# Completions - must come before function definitions that use compdef
source ~/.config/shell/completions.sh

# Tool configs and helper functions (after compinit, so compdef works)
source ~/.config/shell/kubernetes.sh
source ~/.config/shell/showimg.sh
source ~/.config/shell/show.sh

# Secrets (API keys, tokens, etc.)
[[ -f ~/.config/shell/secrets.sh ]] && source ~/.config/shell/secrets.sh

# SDKMAN - must be near the end
source ~/.config/shell/sdkman.sh

# Syntax highlighting (must be last)
[[ -f "$ZSH_HIGHLIGHT_PATH" ]] && source "$ZSH_HIGHLIGHT_PATH"
ZSHRC
success ".zshrc installed"

# ============================================
# micro editor
# ============================================
section "micro Editor"

mkdir -p "$HOME/.config/micro"
if [[ ! -f "$HOME/.config/micro/settings.json" ]]; then
    info "Creating micro config..."
    cat > "$HOME/.config/micro/settings.json" << 'EOF'
{
    "colorscheme": "gruvbox",
    "tabsize": 2,
    "tabstospaces": true,
    "autoindent": true,
    "savecursor": true,
    "saveundo": true,
    "scrollbar": true,
    "softwrap": true,
    "wordwrap": true,
    "clipboard": "external",
    "mouse": true,
    "relativeruler": false,
    "ruler": true,
    "statusformatl": "$(filename) $(modified)($(line),$(col)) | $(status.paste)| ft:$(opt:filetype) | $(opt:fileformat)",
    "statusformatr": "$(bind:ToggleKeyMenu): key menu"
}
EOF
    success "micro config created"
else
    success "micro config already exists"
fi

# ============================================
# Karabiner Elements (macOS only)
# ============================================
if $IS_MACOS; then
    section "Karabiner Elements"

    KARABINER_DIR="$HOME/.config/karabiner"
    mkdir -p "$KARABINER_DIR"
    if [[ -f "$DOTFILES_DIR/macos/karabiner.json" ]]; then
        if [[ -f "$KARABINER_DIR/karabiner.json" ]]; then
            warn "Karabiner config exists, skipping (check $DOTFILES_DIR/macos/karabiner.json)"
        else
            cp "$DOTFILES_DIR/macos/karabiner.json" "$KARABINER_DIR/"
            success "Karabiner config installed"
        fi
    fi
fi

# ============================================
# macOS Defaults
# ============================================
if $IS_MACOS; then
    section "macOS Settings"

    info "Configuring macOS defaults..."
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    success "macOS defaults configured"
fi

# ============================================
# Secrets Setup
# ============================================
section "Secrets Management"

if [[ -f "$DOTFILES_DIR/secrets/age-key.txt" ]]; then
    success "Age key exists"
    if [[ -f "$DOTFILES_DIR/secrets/shell-secrets.enc.yaml" ]]; then
        info "Encrypted secrets found. Run to decrypt:"
        echo "  ~/.dotfiles/secrets/secrets-manager.sh export"
    fi
else
    warn "No age key found. To set up secrets:"
    echo "  1. Generate key: age-keygen -o ~/.dotfiles/secrets/age-key.txt"
    echo "  2. Import secrets: ~/.dotfiles/secrets/secrets-manager.sh import"
    echo "  3. Or copy age-key.txt from backup/password manager"
fi

# Create secrets.sh template if needed
if [[ ! -f "$DOTFILES_DIR/shell/secrets.sh" ]]; then
    info "Creating secrets.sh template..."
    cat > "$DOTFILES_DIR/shell/secrets.sh" << 'EOF'
# Secrets - do not commit to version control
# Run: ~/.dotfiles/secrets/secrets-manager.sh export
# to populate this file from encrypted secrets

# export EXAMPLE_API_KEY="your-key-here"
EOF
    success "secrets.sh template created"
fi

# ============================================
# Set default shell to zsh
# ============================================
if [[ "$SHELL" != *"zsh"* ]]; then
    section "Default Shell"
    info "Changing default shell to zsh..."
    if $IS_LINUX; then
        chsh -s "$(which zsh)" || warn "Could not change shell. Run: chsh -s \$(which zsh)"
    else
        chsh -s /bin/zsh || warn "Could not change shell"
    fi
fi

# ============================================
# Done
# ============================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Set up secrets:"
echo "     - Copy age-key.txt from backup, OR"
echo "     - Run: ~/.dotfiles/secrets/secrets-manager.sh import"
echo "  3. Install a Nerd Font: https://www.nerdfonts.com/"
if $IS_MACOS; then
echo "  4. Configure iTerm2:"
echo "     - Set Left Option Key to Esc+ (Profiles → Keys → General)"
fi
echo ""
echo "Secrets management:"
echo "  ~/.dotfiles/secrets/secrets-manager.sh --help"
echo ""
echo "Documentation:"
echo "  show ~/.dotfiles/docs/README.md"
echo "  show ~/.dotfiles/docs/EDIT.md"
echo ""
