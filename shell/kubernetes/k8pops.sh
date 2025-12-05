# k8pops - Run kubectl commands across POP clusters
#
# Requires: kubectl, parallel (brew install parallel)
# Depends on: k8dcs.sh (for cluster list and DC mappings)

unalias k8pops 2>/dev/null

k8pops() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
k8pops - Run kubectl commands across POP clusters

Usage: k8pops [-c context] <kubectl-command> [args...]

Options:
  -c CONTEXT    Specific context/POP or DC name (default: all POPs)
  -h, --help    Show this help

Executes kubectl command on POP contexts (from ~/.kube/pop-clusters.yaml).
Uses GNU parallel for concurrent execution when querying all POPs.

Examples:
  k8pops get pods                      # List pods in all POPs
  k8pops -c eu-west1 get pods          # List pods in specific POP (by DC name)
  k8pops -c pop-001-ew1 get pods       # List pods in specific POP (by context)
  k8pops get nodes -o wide             # List nodes with details
  k8pops logs -l app=nginx --tail=10   # Tail logs across POPs
  k8pops get deployments -n dsp        # Deployments in dsp namespace
  k8pops top pods -n dsp               # Resource usage

See also: k8pods, k8deps (for formatted multi-cluster queries)

Dependencies: kubectl, parallel (for multi-cluster)
EOF
    return 0
  fi

  local context=""

  # Parse options
  while getopts "c:h" opt; do
    case $opt in
      c) context=${OPTARG} ;;
      h) k8pops --help; return 0 ;;
      :) >&2 echo "k8pops: option -${OPTARG} requires an argument"; return 1 ;;
      *) >&2 echo "k8pops: invalid option -${OPTARG}"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))
  OPTIND=1  # Reset for next getopts call

  # Convert DC name to context if needed
  if [[ -n "$context" ]]; then
    context=$(k8ctx-from "$context" 2>/dev/null) || {
      >&2 echo "k8pops: invalid context or DC name: $context"
      return 1
    }
  fi

  if [[ $# -eq 0 ]]; then
    >&2 echo "k8pops: missing kubectl command"
    >&2 echo "Usage: k8pops [-c context] <kubectl-command> [args...]"
    return 1
  fi

  if [[ -n "$context" ]]; then
    # Single context - direct execution
    echo "=== $context ==="
    kubectl --context "$context" "$@"
  else
    # All POPs - parallel execution
    if ! command -v parallel &>/dev/null; then
      >&2 echo "k8pops: 'parallel' not found. Install with: brew install parallel"
      return 1
    fi

    # Build the kubectl command with placeholder for context
    local cmd="kubectl --context {} $*"

    # Execute across all POPs in parallel
    k8dcs | tr -s '[:blank:]' '\n' | grep -v '^$' | parallel --tag "$cmd"
  fi
}

# Completion
_k8pops() {
  local -a contexts dcs kubectl_cmds
  contexts=(${(k)_k8_ctx2dc})
  dcs=(${(k)_k8_dc2ctx})
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

  _arguments \
    "-c[Context/POP or DC name]:context:(${contexts} ${dcs})" \
    '-h[Show help]' \
    '1:kubectl command:->cmd' \
    '*::kubectl args:->args'

  case $state in
    cmd)
      _describe -t commands 'kubectl commands' kubectl_cmds
      ;;
    args)
      _kubectl
      ;;
  esac
}

compdef _k8pops k8pops
