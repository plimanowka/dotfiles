# k8logs - Collect pod logs across POP clusters
#
# Requires: kubectl
# Depends on: k8dcs.sh (for DC mappings)

k8logs() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
k8logs - Collect pod logs across POP clusters

Usage: k8logs [-a app] [-n namespace] [-c context] [-s since] [-o outdir] [-A]
              <app-label>

Options:
  -a APP        App label to query (default: from positional arg)
  -n NAMESPACE  Kubernetes namespace (default: dsp)
  -c CONTEXT    Specific context/POP or DC name (default: current context)
  -s SINCE      Time duration for --since (e.g., 1h, 30m, 2d)
  -o OUTDIR     Output directory (default: ./logs)
  -A            Query ALL POP clusters (uses k8dcs)
  -h, --help    Show this help

Arguments:
  app-label     The 'app' label value (e.g., ads-dsp-api)

Output: Creates log files at:
  <outdir>/<context>/<app>_<context>_<timestamp>.log

Examples:
  k8logs ads-dsp-api                    # Logs from current context
  k8logs -c pop-001-ew1 ads-dsp-api     # Logs from specific POP (by context)
  k8logs -c eu-west1 ads-dsp-api        # Logs from specific POP (by DC name)
  k8logs -A ads-dsp-api                 # Logs from ALL POPs
  k8logs -s 1h ads-dsp-api              # Logs from last hour
  k8logs -o /tmp/logs -A ads-dsp-api    # Custom output directory

Notes:
  - Uses label selector: app=<app-label>
  - Fetches logs from all containers in matching pods
  - Creates one file per context with all pods combined
  - Parallel fetching within each context for speed

Dependencies: kubectl, k8dcs.sh
EOF
    return 0
  fi

  local app="" namespace="dsp" context="" since="" outdir="./logs" all_pops=false

  # Parse options
  while getopts "a:n:c:s:o:Ah" opt; do
    case $opt in
      a) app=${OPTARG} ;;
      n) namespace=${OPTARG} ;;
      c) context=${OPTARG} ;;
      s) since=${OPTARG} ;;
      o) outdir=${OPTARG} ;;
      A) all_pops=true ;;
      h) k8logs --help; return 0 ;;
      :) >&2 echo "k8logs: option -${OPTARG} requires an argument"; return 1 ;;
      *) >&2 echo "k8logs: invalid option -${OPTARG}"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))
  OPTIND=1  # Reset for next getopts call

  # Convert DC name to context if needed
  if [[ -n "$context" ]]; then
    context=$(k8ctx-from "$context" 2>/dev/null) || {
      >&2 echo "k8logs: invalid context or DC name: $context"
      return 1
    }
  fi

  # App from positional arg if not set via -a
  [[ -z "$app" && -n "$1" ]] && app="$1"

  if [[ -z "$app" ]]; then
    >&2 echo "k8logs: missing app label"
    >&2 echo "Usage: k8logs [-a app] [-n namespace] [-c context] [-s since] [-A] <app-label>"
    return 1
  fi

  local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
  local contexts=()

  # Determine which contexts to query
  if $all_pops; then
    # Use k8dcs for all POP clusters
    contexts=($(k8dcs))
  elif [[ -n "$context" ]]; then
    contexts=("$context")
  else
    contexts=("$(kubectl config current-context)")
  fi

  # Function to collect logs for a single context
  _k8logs_for_context() {
    local ctx="$1"
    local ctx_outdir="$outdir/$ctx"
    local logfile

    if [[ -n "$since" ]]; then
      logfile="$ctx_outdir/${app}_${ctx}_${timestamp}_since_${since}.log"
    else
      logfile="$ctx_outdir/${app}_${ctx}_${timestamp}.log"
    fi

    echo "Collecting logs from $ctx..."

    # Get pods matching the app label
    local pods
    pods=$(kubectl --context="$ctx" -n "$namespace" get pods -l "app=$app" -o name 2>/dev/null)

    if [[ -z "$pods" ]]; then
      echo "  No pods found for app=$app in $ctx"
      return
    fi

    # Create output directories
    mkdir -p "$ctx_outdir/temp/pod"

    # Fetch logs in parallel (use ${(f)pods} to split on newlines in zsh)
    local pod
    for pod in ${(f)pods}; do
      local pod_temp="$ctx_outdir/temp/${pod//\//_}.tmp"
      (
        if [[ -n "$since" ]]; then
          kubectl --context="$ctx" -n "$namespace" logs "$pod" --all-containers=true --since="$since" 2>&1
        else
          kubectl --context="$ctx" -n "$namespace" logs "$pod" --all-containers=true 2>&1
        fi
      ) > "$pod_temp" &
    done
    wait

    # Combine logs into single file
    for pod in ${(f)pods}; do
      local pod_temp="$ctx_outdir/temp/${pod//\//_}.tmp"
      {
        printf "===== %s logs started =====\n\n" "$pod"
        cat "$pod_temp"
        printf "\n\n===== %s logs ended =====\n\n" "$pod"
      } >> "$logfile"
      rm -f "$pod_temp"
    done

    rm -rf "$ctx_outdir/temp"
    echo "  Saved: $logfile"
  }

  echo "k8logs: app=$app namespace=$namespace"
  echo "Output: $outdir"
  echo ""

  for ctx in "${contexts[@]}"; do
    _k8logs_for_context "$ctx"
  done

  echo ""
  echo "Done. Logs saved to: $outdir"
}

# Completion
_k8logs() {
  local -a contexts dcs
  contexts=(${(k)_k8_ctx2dc})
  dcs=(${(k)_k8_dc2ctx})

  _arguments \
    '-a[App label]:app:' \
    '-n[Namespace]:namespace:' \
    "-c[Context/POP or DC name]:context:(${contexts} ${dcs})" \
    '-s[Since duration]:since:' \
    '-o[Output directory]:outdir:_files -/' \
    '-A[All POP clusters]' \
    '-h[Show help]' \
    '*:app label:'
}

compdef _k8logs k8logs
