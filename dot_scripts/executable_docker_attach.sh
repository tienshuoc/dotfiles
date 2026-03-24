#!/usr/bin/env bash
#
# attach.sh - Helper script to attach to running docker environments on sc-vnc hosts
#
# Usage:
#   ./attach.sh              - List docker sessions and attach to selected one
#   ./attach.sh -a, --attach - Attach to the original session (e.g., to kill container)
#   ./attach.sh -h, --help   - Show this help message
#
# What it does:
#   1. Checks if already inside a docker container (hostname contains "DOCKER")
#   2. Lists all docker containers owned by current user
#   3. For each container, fetches: name, repo, branch, and uptime (in parallel)
#   4. Displays a formatted table using fzf for selection
#   5. Attaches to the selected container
#

# Exit immediately if a command exits with a non-zero status
set -e

# Function to display help message
help() {
    echo "
Helper script to attach to a running docker env on the sc-vnc hosts
  IF multiple envs exist, print the names, and software repos
  IF NO envs exist, prompt to make one
  IF HOSTNAME contains DOCKER, nothing to attach to

  use -a|--attach to attach instead of exec ( attach to the original session, usually to kill the container )"
}

# EXEC=1: Use 'docker exec' to create a new shell session (default)
# EXEC=0: Use 'docker attach' to attach to the original session (for killing container)
EXEC=1

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    opt="$1"
    case $opt in
    -a | --attach)
        EXEC=0
        ;;
    -h | --help)
        help
        exit 1
        ;;
    *)
        echo "FAIL: UNKOWN FLAG $opt"
        exit 1
        ;;
    esac
done

# Check if already inside a docker container - if so, nothing to attach to
if [[ "$(hostname)" == *"DOCKER"* ]]; then
    echo "FAIL: ALREADY ATTACHED"
    exit 1
fi

# Get list of all docker containers owned by current user
# Uses docker-wrapper script with sudo for the docker group
ENVS=($(sudo -g docker /usr/bin/docker-wrapper ps --filter "name=$USER" --format "{{.Names}}"))

#
# get_repo_mapping() - Fetches container details and displays them in a formatted table
#
# This function performs the following steps:
#   1. Launches docker inspect calls in parallel for all containers
#   2. Launches docker exec (git branch) calls in parallel for all containers
#   3. Waits for all background jobs to complete
#   4. Collects results and formats them into a table
#   5. Pipes to 'column' command for automatic alignment
#
# The parallel execution significantly speeds up the process when multiple
# containers are running, as all API calls happen simultaneously instead of
# sequentially.
#
get_repo_mapping() {
    # Store all container names in an array
    arr=("$@")
    arr_len=${#ENVS[@]}

    # Get current time in UTC epoch seconds (for calculating uptime)
    local now
    now=$(date -u +%s)

    # -------------------------------------------------------------------------
    # Step 1: Launch docker inspect calls in parallel
    # -------------------------------------------------------------------------
    # Each inspect call fetches: container name, repo path, and started time
    # Running in parallel means all containers are inspected simultaneously
    for ((i = 0; i < ${arr_len}; i++)); do
        (
            # Run in a subshell to isolate variables
            local inspect_json
            inspect_json=$(sudo -g docker /usr/bin/docker-wrapper inspect "${arr[$i]}")
            echo "$inspect_json"
        ) > "/tmp/inspect_${i}.out" &  # & runs in background, output to temp file
    done

    # -------------------------------------------------------------------------
    # Step 2: Launch docker exec (git branch) calls in parallel
    # -------------------------------------------------------------------------
    # Each exec runs 'git rev-parse --abbrev-ref HEAD' inside the container
    # to get the current git branch
    for ((i = 0; i < ${arr_len}; i++)); do
        (
            sudo -g docker /usr/bin/docker-wrapper exec -w /opt/software "${arr[$i]}" git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?"
        ) > "/tmp/branch_${i}.out" &
    done

    # -------------------------------------------------------------------------
    # Step 3: Wait for all background jobs to complete
    # -------------------------------------------------------------------------
    # This blocks until all inspect and exec calls have finished
    wait

    # -------------------------------------------------------------------------
    # Step 4: Collect results and calculate column widths
    # -------------------------------------------------------------------------
    # Store all container data in arrays and calculate max width for each column
    local -a names=() repos=() uptimes=() branches=()

    # Define header strings
    local header_idx="IDX"
    local header_name="NAME"
    local header_uptime="UPTIME"
    local header_repo="REPO"
    local header_branch="BRANCH"

    # Use header string lengths as minimum column widths
    local max_idx=${#header_idx}
    local max_name=${#header_name}
    local max_uptime=${#header_uptime}
    local max_repo=${#header_repo}
    local max_branch=${#header_branch}

    for ((i = 0; i < ${arr_len}; i++)); do
        # Read inspect results from temp file
        local inspect_json
        inspect_json=$(cat "/tmp/inspect_${i}.out" 2>/dev/null || echo "[]")

        # Parse JSON to extract container details
        local container_name repo started_at
        container_name=$(echo "$inspect_json" | jq -r '.[].Name | sub("^/"; "")')
        repo=$(echo "$inspect_json" | jq -r '.[].Config.Env[]|select(match("^REPO_DIR"))|.[index("=")+1:]')
        started_at=$(echo "$inspect_json" | jq -r '.[].State.StartedAt')

        # Calculate uptime from container's started time
        local uptime="?"
        if [[ "$started_at" != "null" && -n "$started_at" ]]; then
            local started
            started=$(date -u -d "$started_at" +%s 2>/dev/null || echo "$now")
            local diff=$((now - started))
            if [[ $diff -lt 60 ]]; then
                uptime="${diff}s"
            elif [[ $diff -lt 3600 ]]; then
                uptime="$((diff / 60))m"
            elif [[ $diff -lt 86400 ]]; then
                uptime="$((diff / 3600))h $(((diff % 3600) / 60))m"
            else
                uptime="$((diff / 86400))d $(((diff % 86400) / 3600))h"
            fi
        fi

        # Read branch result from temp file
        local branch
        branch=$(cat "/tmp/branch_${i}.out" 2>/dev/null || echo "?")

        # Store in arrays
        names+=("$container_name")
        repos+=("$repo")
        uptimes+=("$uptime")
        branches+=("$branch")

        # Update max widths (add 1 for visual spacing)
        local idx_len=${#i} name_len=${#container_name} uptime_len=${#uptime} repo_len=${#repo} branch_len=${#branch}
        ((idx_len > max_idx)) && max_idx=$idx_len
        ((name_len > max_name)) && max_name=$name_len
        ((uptime_len > max_uptime)) && max_uptime=$uptime_len
        ((repo_len > max_repo)) && max_repo=$repo_len
        ((branch_len > max_branch)) && max_branch=$branch_len
    done

    # -------------------------------------------------------------------------
    # Step 5: Print header and data rows with aligned columns
    # -------------------------------------------------------------------------
    # Build format string for data rows
    local fmt_row="\e[32m%-${max_idx}s\e[0m  \e[97m%-${max_name}s\e[0m  \e[36m%-${max_uptime}s\e[0m  \e[90m%-${max_repo}s\e[0m   \e[95m%s\e[0m\n"

    # Build header string with center-aligned columns (inline padding in printf)
    local pad_left_idx=$(( (max_idx - ${#header_idx}) / 2 ))
    local pad_right_idx=$(( max_idx - ${#header_idx} - pad_left_idx ))
    local pad_left_name=$(( (max_name - ${#header_name}) / 2 ))
    local pad_right_name=$(( max_name - ${#header_name} - pad_left_name ))
    local pad_left_uptime=$(( (max_uptime - ${#header_uptime}) / 2 ))
    local pad_right_uptime=$(( max_uptime - ${#header_uptime} - pad_left_uptime ))
    local pad_left_repo=$(( (max_repo - ${#header_repo}) / 2 ))
    local pad_right_repo=$(( max_repo - ${#header_repo} - pad_left_repo ))
    local pad_left_branch=$(( (max_branch - ${#header_branch}) / 2 ))
    local pad_right_branch=$(( max_branch - ${#header_branch} - pad_left_branch ))

    local header_row
    header_row=$(printf "%${pad_left_idx}s${header_idx}%${pad_right_idx}s  %${pad_left_name}s${header_name}%${pad_right_name}s  %${pad_left_uptime}s${header_uptime}%${pad_right_uptime}s  %${pad_left_repo}s${header_repo}%${pad_right_repo}s  %${pad_left_branch}s${header_branch}%${pad_right_branch}s\n")
    echo "$header_row" > /tmp/header_row.txt

    # Write repos to temp file for later retrieval (avoids redundant docker inspect)
    printf '%s\n' "${repos[@]}" > /tmp/repos.txt

    # Print each data row only (no header - it's in fzf's --header now)
    for ((i = 0; i < ${arr_len}; i++)); do
        printf "$fmt_row" "$i" "${names[$i]}" "${uptimes[$i]}" "${repos[$i]}" "${branches[$i]}"
    done

    # Clean up temp files
    rm -f /tmp/inspect_*.out /tmp/branch_*.out
}

# Run fzf to let user select a container
# First run get_repo_mapping to generate the header file and data, then use in fzf
# --delimiter " " uses space to split fields for selection
# --header-lines=0 means no header lines in data (header is in --header)
# --header reads the calculated header from temp file
# --ansi enables ANSI color codes in output
# --height limits fzf window size
# --reverse shows list from top to bottom
get_repo_mapping "${ENVS[@]}" > /tmp/data_rows.txt
HEADER_CONTENT=$(cat /tmp/header_row.txt)
SELECTION=$(fzf --delimiter " " --header-lines=0 --header=$'Which container?\n'"$HEADER_CONTENT" --ansi --height 20% --reverse < /tmp/data_rows.txt)

# Check if user made a selection
if [[ -z "$SELECTION" ]]; then
  rm -f /tmp/header_row.txt /tmp/data_rows.txt /tmp/repos.txt
  echo "FAIL: No OPTION passed"
  exit 1
fi

# Extract the selected index from the fzf output
# Note: We read REPO_DIR from temp file (cached from earlier) to avoid extra docker inspect
OPTION=$(echo $SELECTION | cut -d " " -f 1)
REPO_DIR=$(sed -n "$((OPTION + 1))p" /tmp/repos.txt)

# Clean up temp files
rm -f /tmp/header_row.txt /tmp/data_rows.txt /tmp/repos.txt

# Build the docker command prefix
DOCKER_CMD="sudo -g docker /usr/bin/docker-wrapper"

# Attach or exec into the selected container
if [ $EXEC -eq 0 ]; then
    # Attach mode: attach to the container's original process (for killing it)
    ${DOCKER_CMD} attach ${ENVS[$OPTION]}
else
    # Exec mode (default): exec into container and run the setup script
    ${DOCKER_CMD} exec -w $REPO_DIR -it ${ENVS[$OPTION]} $REPO_DIR/docker/bash_with_setup.sh
fi
