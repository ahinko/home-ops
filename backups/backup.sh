#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOBS_FILE="${SCRIPT_DIR}/backup_jobs.yaml"

if [[ ! -f "$JOBS_FILE" ]]; then
    echo "ERROR: backup_jobs.yaml not found at ${JOBS_FILE}"
    exit 1
fi

if ! command -v yq &>/dev/null; then
    echo "ERROR: yq is required but not installed"
    exit 1
fi

job_count=$(yq '.jobs | length' "$JOBS_FILE")
errors=()

for ((i = 0; i < job_count; i++)); do
    host=$(yq ".jobs[$i].host" "$JOBS_FILE")
    source_path=$(yq ".jobs[$i].source_path" "$JOBS_FILE")
    destination_path=$(yq ".jobs[$i].destination_path" "$JOBS_FILE")

    echo "========================================"
    echo "Job $((i + 1))/${job_count}: ${host}:${source_path} -> ${destination_path}"
    echo "========================================"

    # Verify source path exists on remote host
    if ! ssh "$host" "test -d '${source_path}'"; then
        errors+=("Job $((i + 1)): source path ${host}:${source_path} does not exist")
        echo "SKIP: source path does not exist on remote host"
        echo ""
        continue
    fi

    # Verify destination path exists locally
    if [[ ! -d "$destination_path" ]]; then
        errors+=("Job $((i + 1)): destination path ${destination_path} does not exist")
        echo "SKIP: destination path does not exist locally"
        echo ""
        continue
    fi

    rsync -avh --progress --delete --rsync-path="/usr/bin/rsync" "${host}:${source_path}/" "${destination_path}/"
    echo ""
done

if [[ ${#errors[@]} -gt 0 ]]; then
    echo "========================================"
    echo "ERRORS:"
    echo "========================================"
    for err in "${errors[@]}"; do
        echo "  - ${err}"
    done
    exit 1
fi

echo "All backup jobs completed successfully."
