#!/bin/bash

# ==============================================================================
# Git Sync Tool
# A robust script to synchronize GitHub repositories locally.
# Features: Auto-discovery via GitHub CLI, Mirroring support, Lockfile protection,
# and Pre-flight SSH checks.
# ==============================================================================

# --- Configuration & Defaults ---
VERSION="1.0.0"
LOCK_FILE="/tmp/gitsync.lock"

# Flags
MODE_MIRROR=false
MODE_LOCAL_ONLY=false
INCLUDE_ARCHIVED=false
ORG_NAME=""
TARGET_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions ---

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    cat <<EOF
Usage: gitsync [options...] <target_directory>
Synchronize GitHub repositories to a local directory. Supports auto-discovery and mirroring.

Options:
   -o {org_name}     GitHub Organization or User name (Required for auto-discovery).
   -l                Local mode: Only sync repositories already present in target_directory.
   -m                Mirror mode: Clone/Sync as bare repositories (--mirror).
   -A                Include archived repositories (Disabled by default).
   -h                Show this help message.

Examples:
   gitsync -o my-company -m /backups/github
   gitsync -l /home/user/projects
EOF
    exit 1
}

# --- Core Logic ---

sync_repo() {
    local repo_dir=$1
    local repo_url=$2
    local repo_name=$(basename "$repo_dir")

    if [ -d "$repo_dir" ]; then
        # --- UPDATE EXISTING ---
        echo -n "Syncing $repo_name... "
        (
            cd "$repo_dir" || return
            
            if [ "$MODE_MIRROR" = true ]; then
                # Mirror update (bare repo)
                if git remote update --prune > /dev/null 2>&1; then
                    echo -e "${GREEN}✓ Updated (Mirror)${NC}"
                else
                    echo -e "${RED}✗ Failed${NC}"
                fi
            else
                # Standard update (working tree)
                git fetch --all --prune --tags > /dev/null 2>&1
                if ! git diff-index --quiet HEAD --; then
                     git stash > /dev/null 2>&1 # Stash local changes if any
                fi
                if git pull --rebase > /dev/null 2>&1; then
                    echo -e "${GREEN}✓ Updated (Rebase)${NC}"
                else
                    echo -e "${RED}✗ Failed${NC}"
                fi
            fi
        )
    else
        # --- CLONE NEW ---
        echo -n "Cloning $repo_name... "
        local cmd="git clone"
        [ "$MODE_MIRROR" = true ] && cmd="$cmd --mirror"
        
        if $cmd "$repo_url" "$repo_dir" > /dev/null 2>&1; then
             echo -e "${GREEN}✓ Cloned${NC}"
        else
             echo -e "${RED}✗ Clone Failed${NC}"
        fi
    fi
}

# --- Main Execution ---

# 1. Parse Arguments
while getopts ":o:lmAh" opt; do
  case ${opt} in
    o) ORG_NAME=$OPTARG ;;
    l) MODE_LOCAL_ONLY=true ;;
    m) MODE_MIRROR=true ;;
    A) INCLUDE_ARCHIVED=true ;;
    h) usage ;;
    \?) log_error "Invalid option: -$OPTARG"; usage ;;
    :) log_error "Option -$OPTARG requires an argument."; usage ;;
  esac
done
shift $((OPTIND -1))

TARGET_DIR=$1

# 2. Basic Validation
if [ -z "$TARGET_DIR" ]; then
    log_error "Target directory is required."
    usage
fi

if [ ! -d "$TARGET_DIR" ]; then
    log_warn "Creating directory: $TARGET_DIR"
    mkdir -p "$TARGET_DIR" || { log_error "Failed to create directory."; exit 1; }
fi

# 3. LOCKFILE Check (Prevent overlapping cron jobs)
exec 200>"$LOCK_FILE"
flock -n 200 || { log_error "Script is already running (Lockfile active). Aborting."; exit 1; }

# 4. SSH Connection Check (Fail Fast)
# We test connection to GitHub before attempting any operations.
# We use BatchMode=yes to fail immediately if password is requested.
log_info "Verifying SSH connection to GitHub..."
SSH_OUTPUT=$(ssh -T -o BatchMode=yes -o StrictHostKeyChecking=no git@github.com 2>&1)

# GitHub returns exit code 1 on success (shell disallowed), but prints a specific success message.
if [[ "$SSH_OUTPUT" != *"successfully authenticated"* ]]; then
    log_error "SSH Authentication Failed."
    echo "  Detail: Please ensure your public SSH key is added to GitHub."
    echo "  System Output: $SSH_OUTPUT"
    exit 1
fi

# 5. Dependency Check (Auto-Discovery Mode Only)
if [ "$MODE_LOCAL_ONLY" = false ]; then
    if [ -z "$ORG_NAME" ]; then
        log_error "Organization name (-o) is required for auto-discovery."
        exit 1
    fi
    command -v gh >/dev/null 2>&1 || { log_error "'gh' CLI required."; exit 1; }
    command -v jq >/dev/null 2>&1 || { log_error "'jq' required."; exit 1; }
    
    if ! gh auth status >/dev/null 2>&1; then
        log_error "GitHub CLI not authenticated. Run 'gh auth login'."
        exit 1
    fi
fi

# 6. Start Sync Process
cd "$TARGET_DIR" || exit 1
log_info "Starting sync in: $TARGET_DIR"

if [ "$MODE_LOCAL_ONLY" = true ]; then
    # --- Local Mode ---
    log_info "Mode: LOCAL (No API calls)"
    for d in */; do
        [ -d "$d" ] || continue
        d=${d%/}
        # Check if valid repo (Standard .git or Bare HEAD)
        if [ -d "$d/.git" ] || ([ "$MODE_MIRROR" = true ] && [ -f "$d/HEAD" ]); then
            sync_repo "$d" ""
        fi
    done
else
    # --- Auto-Discovery Mode ---
    log_info "Mode: AUTO-DISCOVERY (Org: $ORG_NAME)"
    
    # Build gh arguments
    GH_ARGS=("$ORG_NAME" "--limit" "2000" "--json" "name,sshUrl")
    if [ "$INCLUDE_ARCHIVED" = false ]; then
        GH_ARGS+=("--no-archived")
    fi

    # Fetch List
    REPO_LIST=$(gh repo list "${GH_ARGS[@]}" 2>/dev/null)

    if [ -z "$REPO_LIST" ]; then
        log_error "No repositories found or API error."
        exit 1
    fi

    # Iterate JSON
    echo "$REPO_LIST" | jq -r '.[] | "\(.name) \(.sshUrl)"' | while read -r repo_name repo_url; do
        sync_repo "$repo_name" "$repo_url"
    done
fi

log_success "Sync Complete."
