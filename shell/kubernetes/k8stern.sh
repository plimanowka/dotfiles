# k8stern - Stream live logs across POP clusters using stern
#
# Requires: stern (brew install stern)
# Depends on: k8dcs.sh (for DC mappings)

k8stern() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
k8stern - Stream live logs across POP clusters using stern

Usage: k8stern [-c context] [-n namespace] [-l selector] [-s since]
               [-o output] [stern-flags...] <pod-query>

Options:
  -c CONTEXT    Specific context/POP or DC name (default: all POPs)
  -n NAMESPACE  Kubernetes namespace (default: all namespaces)
  -l SELECTOR   Label selector (e.g., track=canary)
  -s SINCE      Only show logs newer than duration (e.g., 5m, 1h)
  -o OUTPUT     Stern output format: default, raw, json, extjson (default: default)
  -h, --help    Show this help

Extra flags after '--' are passed directly to stern.

Examples:
  k8stern ads-dsp-api                           # Tail across all POPs
  k8stern -c pop-001-ew1 ads-dsp-api            # Single POP (by context)
  k8stern -c eu-west1 ads-dsp-api               # Single POP (by DC name)
  k8stern -n dsp -s 5m ads-dsp-api              # Last 5m, dsp namespace
  k8stern -n dsp ads-dsp-api -- --tail 100      # Extra stern flags after --

Search (batch mode with --no-follow):
  k8stern -n dsp ads-dsp-api -- --no-follow --tail 10000 | grep ERROR
  k8stern -n dsp ads-dsp-api -- --no-follow --tail 10000 | grep ERROR | cut -c1-$COLUMNS
  k8stern -n dsp ads-dsp-api -- --no-follow -i "OutOfMemory"

Stop: Ctrl-C (kills all stern processes)

Dependencies: stern, k8dcs.sh
EOF
    return 0
  fi

  if ! command -v stern &>/dev/null; then
    >&2 echo "k8stern: 'stern' not found. Install with: brew install stern"
    return 1
  fi

  local context="" namespace="" selector="" since="" output="default"

  # Parse options
  while getopts "c:n:l:s:o:h" opt; do
    case $opt in
      c) context=${OPTARG} ;;
      n) namespace=${OPTARG} ;;
      l) selector=${OPTARG} ;;
      s) since=${OPTARG} ;;
      o) output=${OPTARG} ;;
      h) k8stern --help; return 0 ;;
      :) >&2 echo "k8stern: option -${OPTARG} requires an argument"; return 1 ;;
      *) >&2 echo "k8stern: invalid option -${OPTARG}"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))
  OPTIND=1  # Reset for next getopts call

  # Convert DC name to context if needed
  if [[ -n "$context" ]]; then
    context=$(k8ctx-from "$context" 2>/dev/null) || {
      >&2 echo "k8stern: invalid context or DC name: $context"
      return 1
    }
  fi

  if [[ -z "$1" ]]; then
    >&2 echo "k8stern: missing pod query"
    >&2 echo "Usage: k8stern [-c context] [-n namespace] [-l selector] [-s since] <pod-query>"
    return 1
  fi

  local pod_query="$1"; shift
  # Strip '--' separator if present, pass rest through to stern
  [[ "$1" == "--" ]] && shift
  local extra_args=("$@")

  # Build common stern args
  local stern_args=()
  [[ -n "$namespace" ]] && stern_args+=(-n "$namespace") || stern_args+=(-A)
  [[ -n "$selector" ]]  && stern_args+=(-l "$selector")
  [[ -n "$since" ]]     && stern_args+=(-s "$since")
  stern_args+=("${extra_args[@]}")

  if [[ -n "$context" ]]; then
    # Single context - direct execution, use -o for output format
    local dc=$(k8dc-from "$context" 2>/dev/null || echo "$context")
    >&2 echo "k8stern: streaming $pod_query from $dc ($context)"
    stern "$pod_query" --context "$context" -o "$output" "${stern_args[@]}"
  else
    # All POPs
    local contexts=($(k8dcs))
    local no_follow=false
    [[ " ${stern_args[*]} " == *" --no-follow "* ]] && no_follow=true

    >&2 echo "k8stern: streaming $pod_query across ${#contexts[@]} POPs"
    [[ -n "$selector" ]] && >&2 echo "k8stern: selector=$selector"

    if $no_follow; then
      # Batch mode: run each context sequentially in foreground
      for ctx in "${contexts[@]}"; do
        local dc=$(k8dc-from "$ctx" 2>/dev/null || echo "$ctx")
        >&2 echo "k8stern: querying $dc..."
        stern "$pod_query" --context "$ctx" \
          -o "$output" "${stern_args[@]}" 2>/dev/null \
          | sed "s/^/[${dc}] /"
      done
    else
      # Live mode: background per context, interleaved output
      >&2 echo "k8stern: Ctrl-C to stop"

      for ctx in "${contexts[@]}"; do
        local dc=$(k8dc-from "$ctx" 2>/dev/null || echo "$ctx")
        stern "$pod_query" --context "$ctx" \
          --color always -o "$output" "${stern_args[@]}" \
          | sed -u "s/^/[${dc}] /" &
      done

      trap 'pkill -P $$ stern 2>/dev/null; wait 2>/dev/null; trap - INT TERM; return' INT TERM
      wait 2>/dev/null
      trap - INT TERM
    fi
  fi
}

# Completion
_k8stern() {
  local -a contexts dcs outputs
  contexts=(${(k)_k8_ctx2dc})
  dcs=(${(k)_k8_dc2ctx})
  outputs=(default raw json extjson ppextjson)

  _arguments \
    "-c[Context/POP or DC name]:context:(${contexts} ${dcs})" \
    '-n[Namespace]:namespace:' \
    '-l[Label selector]:selector:' \
    '-s[Since duration]:since:' \
    "-o[Output format]:output:(${outputs})" \
    '-h[Show help]' \
    '*:pod query:'
}

compdef _k8stern k8stern
