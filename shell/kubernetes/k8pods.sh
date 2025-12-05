# k8pods - List pods across POP clusters
#
# Requires: kubectl, parallel (brew install parallel)
# Depends on: k8dcs.sh (for DC mappings)

k8pods() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
k8pods - List pods across POP clusters

Usage: k8pods [-c context] [-n namespace] [-t timeout] [-r] <pod-name-pattern>

Options:
  -c CONTEXT    Specific context/POP or DC name (default: all POPs)
  -n NAMESPACE  Filter by namespace (e.g., dsp, default)
                If omitted, searches all namespaces
  -t TIMEOUT    kubectl timeout in seconds (default: 5)
  -r            Raw output - no headers (for scripting)
  -h, --help    Show this help

Output columns: DC, CLUSTER, NAMESPACE, NAME, STATUS, AGE

Examples:
  k8pods dsp-api                    # All pods matching 'dsp-api' across all POPs
  k8pods -c eu-west1 dsp-api        # Pods in specific POP (by DC name)
  k8pods -c pop-001-ew1 dsp-api     # Pods in specific POP (by context)
  k8pods -n dsp dsp-api             # Only in dsp namespace
  k8pods -t 5 domain-api            # With 5s timeout
  k8pods -r dsp-api | wc -l         # Count pods (raw output)

Dependencies: kubectl, parallel, k8dcs.sh
EOF
    return 0
  fi

  local context="" namespace="" timeout="5" raw=""

  # Parse options
  while getopts "c:n:t:rh" opt; do
    case $opt in
      c) context=${OPTARG} ;;
      n) namespace=${OPTARG} ;;
      t) timeout=${OPTARG} ;;
      r) raw="true" ;;
      h) k8pods --help; return 0 ;;
      :) >&2 echo "k8pods: option -${OPTARG} requires an argument"; return 1 ;;
      *) >&2 echo "k8pods: invalid option -${OPTARG}"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))
  OPTIND=1  # Reset for next getopts call

  # Convert DC name to context if needed
  if [[ -n "$context" ]]; then
    context=$(k8ctx-from "$context" 2>/dev/null) || {
      >&2 echo "k8pods: invalid context or DC name: $context"
      return 1
    }
  fi

  if [[ -z "$1" ]]; then
    >&2 echo "k8pods: missing pod name pattern"
    >&2 echo "Usage: k8pods [-c context] [-n namespace] [-t timeout] [-r] <pod-name-pattern>"
    return 1
  fi

  local pattern="$1"

  # Check dependencies (only for multi-cluster)
  if [[ -z "$context" ]] && ! command -v parallel &>/dev/null; then
    >&2 echo "k8pods: 'parallel' not found. Install with: brew install parallel"
    return 1
  fi

  # Always use -A and filter by namespace (consistent column output)
  local ns_filter=""
  [[ -n "$namespace" ]] && ns_filter="$namespace"

  # Header line (returns string, not printed directly)
  _k8pods_header() {
    if [[ -n "$raw" ]]; then
      echo ""
    elif [[ -t 1 ]]; then
      echo $'\033[1;37mDC CLUSTER NAMESPACE NAME STATUS AGE\033[0m'
    else
      echo "DC CLUSTER NAMESPACE NAME STATUS AGE"
    fi
  }

  # Query function for a single context
  _k8pods_one() {
    local ctx="$1"
    local dc=$(k8dc-from "$ctx" 2>/dev/null || echo "$ctx")
    kubectl --context "$ctx" --request-timeout "${timeout}s" get pods -A 2>/dev/null \
      | grep -v "^NAMESPACE" \
      | tr -s '[:blank:]' ' ' \
      | { [[ -n "$ns_filter" ]] && grep -i "^$ns_filter " || cat; } \
      | grep -i "$pattern" \
      | awk -v dc="$dc" -v ctx="$ctx" '{print dc, ctx, $1, $2, $4, $6}'
  }

  # Color function for output (use_color flag controls behavior)
  _k8pods_color() {
    local use_color="$1"
    if [[ "$use_color" != "true" ]]; then
      cat  # Pass through uncolored
    else
      awk '
        BEGIN {
          cyan="\033[36m"; blue="\033[34m"; yellow="\033[33m"
          green="\033[32m"; red="\033[31m"; gray="\033[90m"
          reset="\033[0m"
        }
        {
          # Color by column: DC, CLUSTER, NAMESPACE, NAME, STATUS, AGE
          status_color = ($5 == "Running") ? green : red
          printf "%s%s%s %s%s%s %s%s%s %s %s%s%s %s%s%s\n",
            cyan, $1, reset,
            blue, $2, reset,
            yellow, $3, reset,
            $4,
            status_color, $5, reset,
            gray, $6, reset
        }
      '
    fi
  }

  # Output with optional pager for long results
  _k8pods_output() {
    local formatted="$1"
    local is_tty="$2"
    local header=$(_k8pods_header)

    if [[ "$is_tty" != "true" ]] || [[ -n "$raw" ]]; then
      # Not a terminal or raw mode - just output
      [[ -n "$header" ]] && echo "$header"
      echo -n "$formatted"
    else
      local line_count=$(echo -n "$formatted" | wc -l)
      local term_height=${LINES:-24}
      # Combine header + colored data
      local full_output="${header}"$'\n'$(echo -n "$formatted" | _k8pods_color "true")
      if (( line_count > term_height - 2 )); then
        # Long output - use pager (-X keeps output on screen after quit, -F quits if fits)
        echo "$full_output" | less -RXF
      else
        echo "$full_output"
      fi
    fi
  }

  # Detect if stdout is a terminal (before any subshells)
  local is_tty="false"
  [[ -t 1 ]] && is_tty="true"

  if [[ -n "$context" ]]; then
    # Single context - direct query
    local result=$(_k8pods_one "$context" | column -t)
    _k8pods_output "$result" "$is_tty"
  else
    # All POPs - query in parallel
    local ctx_list=($(k8dcs))
    local total=${#ctx_list[@]}

    [[ "$is_tty" == "true" ]] && printf '\033[90mQuerying %d clusters in parallel...\033[0m\n' "$total" >&2

    # Build context->dc sed replacements
    local sed_cmds=""
    for ctx in "${ctx_list[@]}"; do
      local dc=$(k8dc-from "$ctx" 2>/dev/null || echo "$ctx")
      sed_cmds+="s/^$ctx /$dc /;"
    done

    # Use parallel for concurrent queries, then replace ctx with dc
    local output=$(printf '%s\n' "${ctx_list[@]}" | parallel --will-cite -j "$total" "
      kubectl --context {} --request-timeout ${timeout}s get pods -A 2>/dev/null \
        | grep -v '^NAMESPACE' \
        | tr -s '[:blank:]' ' ' \
        | { [[ -n '$ns_filter' ]] && grep -i '^$ns_filter ' || cat; } \
        | grep -i '$pattern' \
        | awk -v ctx={} '{print ctx, ctx, \$1, \$2, \$4, \$6}'
    " | sed "$sed_cmds")

    [[ "$is_tty" == "true" ]] && printf '\r\033[K' >&2  # Clear progress line

    if [[ -n "$output" ]]; then
      local formatted=$(echo "$output" | column -t)
      _k8pods_output "$formatted" "$is_tty"
    fi
  fi
}

# Completion
_k8pods() {
  local -a contexts dcs
  contexts=(${(k)_k8_ctx2dc})
  dcs=(${(k)_k8_dc2ctx})

  _arguments \
    "-c[Context/POP or DC name]:context:(${contexts} ${dcs})" \
    '-n[Namespace]:namespace:' \
    '-t[Timeout seconds]:timeout:' \
    '-r[Raw output]' \
    '-h[Show help]' \
    '*:pod pattern:'
}

compdef _k8pods k8pods
