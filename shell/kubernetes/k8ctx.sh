# k8ctx - List and manage kubectl contexts

k8ctx() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
k8ctx - List available Kubernetes contexts

Usage: k8ctx [pattern]

Arguments:
  pattern    Optional grep pattern to filter contexts

Output: One context name per line (suitable for piping/scripting)

Examples:
  k8ctx                 # List all contexts
  k8ctx pop             # List contexts matching 'pop'
  k8ctx | grep prod     # Filter with grep
  k8ctx | wc -l         # Count contexts

See also: k8dcs, k8ctx-from, k8dc-from
EOF
    return 0
  fi

  if [[ -n "$1" ]]; then
    kubectl config get-contexts --no-headers | awk '{print $2}' | grep -i "$1"
  else
    kubectl config get-contexts --no-headers | awk '{print $2}'
  fi
}

# Completion
_k8ctx() {
  _message 'optional pattern'
}

compdef _k8ctx k8ctx
