# Kubernetes CLI Tools

Custom shell functions for working with multiple Kubernetes clusters.

## Overview

These tools are designed for environments with multiple POP (Point of Presence) clusters, providing easy ways to query and manage resources across all clusters simultaneously.

## Installation

Tools are automatically loaded when you source `.zshrc`. Dependencies:
- `kubectl` - Kubernetes CLI
- `yq` - YAML processor (`brew install yq`)
- `parallel` - GNU parallel for concurrent queries (`brew install parallel`)

## Configuration

Cluster mappings are stored in `~/.kube/pop-clusters.yaml`. This file defines context-to-datacenter mappings used by all k8 tools.

### Config File Format

```yaml
# ~/.kube/pop-clusters.yaml
clusters:
  # Format: context_name: datacenter_name
  # Contexts starting with 'pop-' are included in k8dcs output
  pop-001-ew1: eu-west1
  pop-001-ew3: eu-west3
  pop-001-uw1: us-west1
  pop-002-uw1: us-west2
  pop-001-ue4: us-east1
  pop-002-ue4: us-east2
  pop-001-ae1: asia-east1
  # Non-pop contexts (excluded from k8dcs but available for mapping)
  core-002-ew4: core
```

### Creating the Config File

Create the file with your cluster mappings:

```bash
cat > ~/.kube/pop-clusters.yaml << 'EOF'
clusters:
  my-cluster-1: us-east-1
  my-cluster-2: eu-west-1
EOF
```

### Environment Variable

Override the config location with `K8_CLUSTERS_CONFIG`:

```bash
export K8_CLUSTERS_CONFIG=/path/to/custom-clusters.yaml
```

### Reloading After Edits

After editing the config file, reload without restarting shell:

```bash
k8dcs-reload
```

## Available Commands

### k8pops

Run kubectl commands across POP clusters.

```bash
k8pops [-c context] <kubectl-command> [args...]
```

**Options:**
| Option | Description |
|--------|-------------|
| `-c CONTEXT` | Specific context/POP or DC name (default: all POPs) |

**Examples:**
```bash
k8pops get pods                      # List pods in all POPs
k8pops -c eu-west1 get pods          # List pods in specific POP (by DC name)
k8pops -c pop-001-ew1 get pods       # List pods in specific POP (by context)
k8pops get nodes -o wide             # List nodes with details
k8pops logs -l app=nginx --tail=10   # Tail logs across POPs
k8pops get deployments -n dsp        # Deployments in dsp namespace
```

Uses GNU `parallel` for concurrent execution across all contexts from `~/.kube/pop-clusters.yaml`.

---

### k8ctx

List available kubectl contexts.

```bash
k8ctx [pattern]
```

**Examples:**
```bash
k8ctx                 # List all contexts
k8ctx pop             # List contexts matching 'pop'
k8ctx | wc -l         # Count contexts
```

---

### k8dcs

List all POP context names (excludes non-pop clusters).

```bash
k8dcs
```

Returns space-separated list of POP contexts (from `~/.kube/pop-clusters.yaml`) for use in scripts:
```bash
for ctx in $(k8dcs); do
  kubectl --context $ctx get nodes
done
```

---

### k8dcs-reload

Reload cluster mappings after editing the config file.

```bash
k8dcs-reload
```

---

### k8ctx-from / k8dc-from

Convert between context names and datacenter/region names.

```bash
k8ctx-from <dc-or-context>   # Returns context name
k8dc-from <dc-or-context>    # Returns datacenter name
```

Mappings are defined in `~/.kube/pop-clusters.yaml`.

**Examples:**
```bash
k8ctx-from eu-west1      # Returns: pop-001-ew1
k8dc-from pop-001-ew1    # Returns: eu-west1
```

**Note:** All tools that accept `-c context` also accept DC names:
```bash
k8images -c pop-001-ew1 my-app   # By context name
k8images -c eu-west1 my-app      # By DC name (auto-converted)
k8logs -c us-west1 my-app        # Works the same way
```

---

### k8pods

List pods across POP clusters with filtering.

```bash
k8pods [-c context] [-n namespace] [-t timeout] [-r] <pod-name-pattern>
```

**Options:**
| Option | Description |
|--------|-------------|
| `-c CONTEXT` | Specific context/POP or DC name (default: all POPs) |
| `-n NAMESPACE` | Filter by namespace (e.g., `dsp`, `default`) |
| `-t TIMEOUT` | kubectl timeout in seconds (default: 10) |
| `-r` | Raw output - no headers (for scripting) |

**Output columns:** DC, CLUSTER, NAMESPACE, NAME, STATUS, AGE

**Examples:**
```bash
k8pods dsp-api                    # All pods matching 'dsp-api'
k8pods -c eu-west1 dsp-api        # Pods in specific POP (by DC name)
k8pods -c pop-001-ew1 dsp-api     # Pods in specific POP (by context)
k8pods -n dsp dsp-api             # Only in dsp namespace
k8pods -t 5 domain-api            # With 5s timeout
k8pods -r dsp-api | wc -l         # Count pods (raw output)
```

---

### k8deps

List deployments across POP clusters with filtering.

```bash
k8deps [-c context] [-n namespace] [-t timeout] [-r] <deployment-name-pattern>
```

**Options:** Same as `k8pods`

**Output columns:** DC, CLUSTER, NAMESPACE, DEPLOYMENT, READY, UP-TO-DATE, AVAILABLE, AGE

**Examples:**
```bash
k8deps dsp-api                    # All deployments matching 'dsp-api'
k8deps -c eu-west1 dsp-api        # Deployments in specific POP (by DC name)
k8deps -c pop-001-ew1 dsp-api     # Deployments in specific POP (by context)
k8deps -n dsp dsp-api             # Only in dsp namespace
k8deps -r pacing | grep -v '0/0'  # Find running deployments
```

---

### k8images

List Docker images for a deployment across POP clusters.

```bash
k8images [-n namespace] [-c context] <app-label>
```

**Options:**
| Option | Description |
|--------|-------------|
| `-n NAMESPACE` | Kubernetes namespace (default: `dsp`) |
| `-c CONTEXT` | Specific context/POP or DC name (default: all POPs) |

**Output columns:** CONTEXT, IMAGE

**Examples:**
```bash
k8images ads-dsp-api                    # Images across all POPs
k8images -c pop-001-ew1 ads-dsp-api     # By context name
k8images -c eu-west1 ads-dsp-api        # By DC name
k8images -n default nginx               # Different namespace
```

Uses label selector `app=<app-label>` to find pods.

---

### k8logs

Collect pod logs across POP clusters, saving to files.

```bash
k8logs [-a app] [-n namespace] [-c context] [-s since] [-o outdir] [-A] <app-label>
```

**Options:**
| Option | Description |
|--------|-------------|
| `-a APP` | App label (alternative to positional arg) |
| `-n NAMESPACE` | Kubernetes namespace (default: `dsp`) |
| `-c CONTEXT` | Specific context/POP or DC name (default: current context) |
| `-s SINCE` | Time duration for kubectl --since (e.g., `1h`, `30m`) |
| `-o OUTDIR` | Output directory (default: `./logs`) |
| `-A` | Query ALL POP clusters (uses k8dcs) |

**Output:** Creates log files at `<outdir>/<context>/<app>_<context>_<timestamp>.log`

**Examples:**
```bash
k8logs ads-dsp-api                    # Logs from current context
k8logs -c pop-001-ew1 ads-dsp-api     # By context name
k8logs -c eu-west1 ads-dsp-api        # By DC name
k8logs -A ads-dsp-api                 # Logs from ALL POPs
k8logs -s 1h ads-dsp-api              # Logs from last hour
k8logs -o /tmp/logs -A ads-dsp-api    # Custom output directory
```

Uses label selector `app=<app-label>` to find pods. Fetches logs from all containers in parallel within each context.

---

## File Structure

```
~/.kube/
└── pop-clusters.yaml    # Cluster configuration (context:datacenter mappings)

~/.config/shell/kubernetes/
├── init.sh        # Loads all tools, sets up PATH for krew
├── k8dcs.sh       # DC/context mappings (reads from config)
├── k8ctx.sh       # List contexts
├── k8pops.sh      # Run kubectl across POPs
├── k8pods.sh      # List pods across clusters
├── k8deps.sh      # List deployments across clusters
├── k8images.sh    # List images across clusters
└── k8logs.sh      # Collect logs across clusters
```

## Tips

### Parallel Queries
`k8pods` and `k8deps` use GNU `parallel` for concurrent queries. Install with:
```bash
brew install parallel
```

### Shell Completions
All commands have zsh completions. Type `<command> -<TAB>` to see options.

### Help
All commands support `-h` or `--help`:
```bash
k8pods --help
k8deps -h
```

### Timeouts
If clusters are slow or unreachable, use `-t` to set timeout:
```bash
k8pods -t 5 dsp-api   # 5 second timeout
```

### Raw Output for Scripting
Use `-r` flag for machine-readable output (no headers):
```bash
k8pods -r dsp-api | awk '{print $4}' | xargs -I{} kubectl delete pod {}
```
