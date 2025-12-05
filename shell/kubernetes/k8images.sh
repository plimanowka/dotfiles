# k8images - List Docker images for a deployment across POP clusters
#
# Requires: kubectl
# Depends on: k8dcs.sh (for DC mappings)

k8images() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
k8images - List Docker images for a deployment across POP clusters

Usage: k8images [-n namespace] [-c context] <app-label>

Options:
  -n NAMESPACE  Kubernetes namespace (default: dsp)
  -c CONTEXT    Specific context/POP or DC name (default: all POPs)
  -h, --help    Show this help

Arguments:
  app-label     The 'app' label value of the deployment (e.g., ads-dsp-api)

Output: CONTEXT  IMAGE_TAG

Examples:
  k8images ads-dsp-api                    # Images across all POPs
  k8images -c pop-001-ew1 ads-dsp-api     # Images in specific POP (by context)
  k8images -c eu-west1 ads-dsp-api        # Images in specific POP (by DC name)
  k8images -n default nginx               # Different namespace

Notes:
  - Uses label selector: app=<app-label>
  - Extracts image tag from full image path
  - Queries pods, not deployments (shows actual running images)

Dependencies: kubectl, k8dcs.sh
EOF
    return 0
  fi

  local namespace="dsp" context=""

  # Parse options
  while getopts "n:c:h" opt; do
    case $opt in
      n) namespace=${OPTARG} ;;
      c) context=${OPTARG} ;;
      h) k8images --help; return 0 ;;
      :) >&2 echo "k8images: option -${OPTARG} requires an argument"; return 1 ;;
      *) >&2 echo "k8images: invalid option -${OPTARG}"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))
  OPTIND=1  # Reset for next getopts call

  # Convert DC name to context if needed
  if [[ -n "$context" ]]; then
    context=$(k8ctx-from "$context" 2>/dev/null) || {
      >&2 echo "k8images: invalid context or DC name: $context"
      return 1
    }
  fi

  if [[ -z "$1" ]]; then
    >&2 echo "k8images: missing app label"
    >&2 echo "Usage: k8images [-n namespace] [-c context] <app-label>"
    return 1
  fi

  local app_label="$1"

  # Function to list images for a specific context
  _k8images_for_context() {
    local ctx="$1"
    local images

    # Get all images from pods matching the app label
    images=$(kubectl --context "$ctx" -n "$namespace" get pods \
      -l "app=$app_label" \
      -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.image}{"\n"}{end}{range .spec.initContainers[*]}{.image}{"\n"}{end}{end}' 2>/dev/null)

    if [[ -z "$images" ]]; then
      return
    fi

    # Extract unique image tags and format output
    echo "$images" | while read -r img; do
      [[ -z "$img" ]] && continue
      # Get image name (last part of path before :tag)
      local name=$(echo "$img" | sed 's|.*/||' | sed 's/:.*$//')
      # Extract tag (between : and @, or after : if no @)
      local tag=$(echo "$img" | sed 's/.*:\([^@]*\)@.*/\1/' | sed 's/.*://')
      echo "$ctx $name:$tag"
    done | sort -u
  }

  echo "CONTEXT IMAGE"

  if [[ -n "$context" ]]; then
    # Query specific context
    _k8images_for_context "$context"
  else
    # Query all POPs
    for ctx in $(k8dcs); do
      _k8images_for_context "$ctx"
    done
  fi | column -t
}

# Completion
_k8images() {
  local -a contexts dcs
  contexts=(${(k)_k8_ctx2dc})
  dcs=(${(k)_k8_dc2ctx})

  _arguments \
    '-n[Namespace]:namespace:' \
    "-c[Context/POP or DC name]:context:(${contexts} ${dcs})" \
    '-h[Show help]' \
    '*:app label:'
}

compdef _k8images k8images
