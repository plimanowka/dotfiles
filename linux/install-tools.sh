#!/bin/bash
# Linux-specific tool installation
# Called by main install.sh

set -e

# Colors (inherit from parent or define)
RED=${RED:-'\033[0;31m'}
GREEN=${GREEN:-'\033[0;32m'}
YELLOW=${YELLOW:-'\033[1;33m'}
BLUE=${BLUE:-'\033[0;34m'}
NC=${NC:-'\033[0m'}

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }

LINUX_DIR="$(dirname "$0")"

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)  ARCH_ALT="amd64" ;;
    aarch64|arm64) ARCH_ALT="arm64" ;;
    *) ARCH_ALT="amd64" ;;
esac

# ============================================
# bat (cat replacement)
# ============================================
install_bat() {
    if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
        info "Installing bat..."
        if command -v apt-get &>/dev/null; then
            # Ubuntu/Debian - package is named 'bat' but binary is 'batcat'
            sudo apt-get install -y bat 2>/dev/null && {
                # Create symlink for 'bat' command
                sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
            }
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y bat
        fi
        success "bat installed"
    else
        success "bat already installed"
    fi
}

# ============================================
# ripgrep (grep replacement)
# ============================================
install_ripgrep() {
    if ! command -v rg &>/dev/null; then
        info "Installing ripgrep..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get install -y ripgrep
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y ripgrep
        fi
        success "ripgrep installed"
    else
        success "ripgrep already installed"
    fi
}

# ============================================
# Starship
# ============================================
install_starship() {
    if ! command -v starship &>/dev/null; then
        info "Installing starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        success "Starship installed"
    else
        success "Starship already installed"
    fi
}

# ============================================
# micro editor
# ============================================
install_micro() {
    if ! command -v micro &>/dev/null; then
        info "Installing micro..."
        cd /tmp
        curl https://getmic.ro | bash
        sudo mv micro /usr/local/bin/
        success "micro installed"
    else
        success "micro already installed"
    fi
}

# ============================================
# SOPS
# ============================================
install_sops() {
    if ! command -v sops &>/dev/null; then
        info "Installing sops..."
        SOPS_VERSION=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | jq -r .tag_name)
        curl -LO "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.${ARCH_ALT}"
        sudo mv "sops-${SOPS_VERSION}.linux.${ARCH_ALT}" /usr/local/bin/sops
        sudo chmod +x /usr/local/bin/sops
        success "SOPS installed"
    else
        success "SOPS already installed"
    fi
}

# ============================================
# age
# ============================================
install_age() {
    if ! command -v age &>/dev/null; then
        info "Installing age..."
        # Try apt first, fall back to manual install
        if command -v apt-get &>/dev/null; then
            sudo apt-get install -y age 2>/dev/null || _install_age_manual
        else
            _install_age_manual
        fi
        success "age installed"
    else
        success "age already installed"
    fi
}

_install_age_manual() {
    AGE_VERSION=$(curl -s https://api.github.com/repos/FiloSottile/age/releases/latest | jq -r .tag_name)
    cd /tmp
    curl -LO "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-${ARCH_ALT}.tar.gz"
    tar xzf "age-${AGE_VERSION}-linux-${ARCH_ALT}.tar.gz"
    sudo mv age/age age/age-keygen /usr/local/bin/
    rm -rf age "age-${AGE_VERSION}-linux-${ARCH_ALT}.tar.gz"
}

# ============================================
# thefuck
# ============================================
install_thefuck() {
    if ! command -v thefuck &>/dev/null; then
        info "Installing thefuck..."
        pip3 install --user thefuck || warn "thefuck installation failed"
    else
        success "thefuck already installed"
    fi
}

# ============================================
# GitHub CLI
# ============================================
install_gh() {
    if ! command -v gh &>/dev/null; then
        info "Installing GitHub CLI..."
        if command -v apt-get &>/dev/null; then
            (
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y gh
            )
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y 'dnf-command(config-manager)'
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo dnf install -y gh
        fi
        success "GitHub CLI installed"
    else
        success "GitHub CLI already installed"
    fi
}

# ============================================
# glow (markdown renderer)
# ============================================
install_glow() {
    if ! command -v glow &>/dev/null; then
        info "Installing glow..."
        if command -v apt-get &>/dev/null; then
            # Charmbracelet repo for glow
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
            sudo apt-get update
            sudo apt-get install -y glow
        elif command -v dnf &>/dev/null; then
            echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
            sudo dnf install -y glow
        fi
        success "glow installed"
    else
        success "glow already installed"
    fi
}

# ============================================
# poppler (PDF tools)
# ============================================
install_poppler() {
    if ! command -v pdftoppm &>/dev/null; then
        info "Installing poppler-utils..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get install -y poppler-utils
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y poppler-utils
        fi
        success "poppler installed"
    else
        success "poppler already installed"
    fi
}

# ============================================
# ImageMagick
# ============================================
install_imagemagick() {
    if ! command -v magick &>/dev/null && ! command -v convert &>/dev/null; then
        info "Installing ImageMagick..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get install -y imagemagick
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y ImageMagick
        fi
        success "ImageMagick installed"
    else
        success "ImageMagick already installed"
    fi
}

# ============================================
# Main
# ============================================
main() {
    install_bat
    install_ripgrep
    install_starship
    install_micro
    install_sops
    install_age
    install_thefuck
    install_gh
    install_glow
    install_poppler
    install_imagemagick
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
