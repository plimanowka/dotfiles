# Kubernetes tools setup

# krew kubectl plugin manager
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Run kubectl command on all pop-* contexts
unalias kpops 2>/dev/null
kpops() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
kpops - Run kubectl commands across all pop-* contexts

Usage: kpops <kubectl-command> [args...]

Examples:
  kpops get pods
  kpops get nodes -o wide
  kpops logs -l app=nginx --tail=10

Runs: kubectl foreach /^pop/ -- <command>
EOF
    return 0
  fi
  kubectl foreach /^pop/ -- "$@"
}

# List available kubectl contexts
k8ctx() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
k8ctx - List available Kubernetes contexts

Usage: k8ctx

Output: One context name per line (suitable for piping/scripting)
EOF
    return 0
  fi
  kubectl config get-contexts --no-headers | awk '{print $2}'
}

# Completions (loaded after compinit via completions.sh)
_kpops() {
  # Complete like kubectl, skipping the 'foreach /^pop/ --' part
  local -a kubectl_cmds
  kubectl_cmds=(
    'get:Display resources'
    'describe:Show details of a resource'
    'logs:Print container logs'
    'exec:Execute command in a container'
    'apply:Apply configuration'
    'delete:Delete resources'
    'scale:Scale a deployment'
    'rollout:Manage rollouts'
    'top:Display resource usage'
    'port-forward:Forward ports to a pod'
  )

  if (( CURRENT == 2 )); then
    _describe -t commands 'kubectl commands' kubectl_cmds
  else
    # Defer to kubectl completion for subsequent args
    shift words
    (( CURRENT-- ))
    _kubectl
  fi
}

_k8ctx() {
  # No arguments to complete
  _message 'no arguments'
}

compdef _kpops kpops
compdef _k8ctx k8ctx
