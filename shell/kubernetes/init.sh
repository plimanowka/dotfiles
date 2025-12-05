# Kubernetes tools initialization
#
# This file sources all kubernetes tools from the kubernetes/ directory.
# Source this file from .zshrc after compinit.

# krew kubectl plugin manager
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Get the directory where this script is located
_K8S_TOOLS_DIR="${0:A:h}"

# Source all kubernetes tools (order matters: k8dcs first as others depend on it)
source "$_K8S_TOOLS_DIR/k8dcs.sh"      # DC/context mappings (base)
source "$_K8S_TOOLS_DIR/k8ctx.sh"      # List contexts
source "$_K8S_TOOLS_DIR/k8pops.sh"     # Run kubectl across POPs
source "$_K8S_TOOLS_DIR/k8pods.sh"     # List pods across clusters
source "$_K8S_TOOLS_DIR/k8deps.sh"     # List deployments across clusters
source "$_K8S_TOOLS_DIR/k8images.sh"   # List images across clusters
source "$_K8S_TOOLS_DIR/k8logs.sh"     # Collect logs across clusters

unset _K8S_TOOLS_DIR
