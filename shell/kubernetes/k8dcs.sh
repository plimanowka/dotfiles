# Kubernetes context/datacenter mapping utilities
#
# Provides bidirectional mapping between k8s context names and datacenter/region names.
# Used by other k8s tools (k8pods, k8deps, k8images, k8logs) for consistent DC naming.
#
# Configuration: ~/.kube/pop-clusters.yaml
# Requires: yq (brew install yq)

_K8_CLUSTERS_CONFIG="${K8_CLUSTERS_CONFIG:-$HOME/.kube/pop-clusters.yaml}"

# Load cluster mappings from config file
_k8_load_clusters() {
  declare -gA _k8_ctx2dc
  declare -gA _k8_dc2ctx
  _k8_ctx2dc=()
  _k8_dc2ctx=()

  if [[ ! -f "$_K8_CLUSTERS_CONFIG" ]]; then
    >&2 echo "k8dcs: config not found: $_K8_CLUSTERS_CONFIG"
    >&2 echo "Create it with context:datacenter mappings. See K8S-TOOLS.md for format."
    return 1
  fi

  if ! command -v yq &>/dev/null; then
    >&2 echo "k8dcs: yq not found. Install with: brew install yq"
    return 1
  fi

  # Read clusters from YAML config
  local ctx dc
  while IFS=': ' read -r ctx dc; do
    [[ -z "$ctx" || -z "$dc" ]] && continue
    _k8_ctx2dc[$ctx]=$dc
    _k8_dc2ctx[$dc]=$ctx
  done < <(yq -r '.clusters | to_entries | .[] | "\(.key): \(.value)"' "$_K8_CLUSTERS_CONFIG" 2>/dev/null)

  if [[ ${#_k8_ctx2dc[@]} -eq 0 ]]; then
    >&2 echo "k8dcs: no clusters found in $_K8_CLUSTERS_CONFIG"
    return 1
  fi
}

# Load clusters on source
_k8_load_clusters

# Reload clusters from config (useful after editing config)
k8dcs-reload() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
k8dcs-reload - Reload cluster mappings from config file

Usage: k8dcs-reload

Reloads ~/.kube/pop-clusters.yaml after you've edited it.
EOF
    return 0
  fi

  _k8_load_clusters && echo "Reloaded ${#_k8_ctx2dc[@]} clusters from $_K8_CLUSTERS_CONFIG"
}

# Get context name from DC name or context name
# Usage: k8ctx-from <dc-or-context>
k8ctx-from() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
k8ctx-from - Convert datacenter name to kubectl context name

Usage: k8ctx-from <dc-or-context>

Examples:
  k8ctx-from eu-west1      # Returns: pop-001-ew1
  k8ctx-from pop-001-ew1   # Returns: pop-001-ew1 (passthrough)

Returns the kubectl context name for a given datacenter or context.
EOF
    return 0
  fi

  local ctx=${_k8_dc2ctx[$1]}
  [[ -z "$ctx" && -n "${_k8_ctx2dc[$1]}" ]] && ctx=$1
  if [[ -n "$ctx" ]]; then
    echo $ctx
  else
    >&2 echo "k8ctx-from: '$1' is not a valid context or DC name"
    return 1
  fi
}

# Get datacenter name from context name or DC name
# Usage: k8dc-from <dc-or-context>
k8dc-from() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
k8dc-from - Convert kubectl context name to datacenter name

Usage: k8dc-from <dc-or-context>

Examples:
  k8dc-from pop-001-ew1   # Returns: eu-west1
  k8dc-from eu-west1      # Returns: eu-west1 (passthrough)

Returns the datacenter/region name for a given context or datacenter.
EOF
    return 0
  fi

  local dc=${_k8_ctx2dc[$1]}
  [[ -z "$dc" && -n "${_k8_dc2ctx[$1]}" ]] && dc=$1
  if [[ -n "$dc" ]]; then
    echo $dc
  else
    >&2 echo "k8dc-from: '$1' is not a valid context or DC name"
    return 1
  fi
}

# List all POP context names
# Usage: k8dcs
k8dcs() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
k8dcs - List all POP kubectl context names

Usage: k8dcs

Output: Space-separated list of all POP context names
        (excludes non-pop contexts like core-*)

Configuration: ~/.kube/pop-clusters.yaml

Use with other commands:
  for ctx in $(k8dcs); do kubectl --context $ctx get nodes; done
EOF
    return 0
  fi

  # Return only pop-* contexts, not core or others
  echo "${(k)_k8_ctx2dc}" | tr ' ' '\n' | grep '^pop-' | sort | tr '\n' ' '
  echo  # newline at end
}

# Completions
_k8ctx-from() {
  local -a contexts dcs
  contexts=(${(k)_k8_ctx2dc})
  dcs=(${(k)_k8_dc2ctx})
  _describe -t contexts 'context or datacenter' contexts dcs
}

_k8dc-from() {
  local -a contexts dcs
  contexts=(${(k)_k8_ctx2dc})
  dcs=(${(k)_k8_dc2ctx})
  _describe -t contexts 'context or datacenter' contexts dcs
}

compdef _k8ctx-from k8ctx-from
compdef _k8dc-from k8dc-from
