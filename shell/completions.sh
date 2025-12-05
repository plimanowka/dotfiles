# Zsh completion setup
# This file should be sourced AFTER all fpath modifications

# Homebrew completions
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

# Custom completions
fpath+=~/.zfunc

# Initialize completion system (only once!)
autoload -Uz compinit
compinit

# Completion styling
zstyle ':completion:*' menu select

# Load dynamic completions from tools
# These need to be sourced AFTER compinit

# kubectl
if command -v kubectl &>/dev/null; then
  source <(kubectl completion zsh)
fi

# gcloud
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi
