#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "Usage: $0 <watershed|cellpose> <one|two|three> [vizgen-filename]" >&2
    exit 2
fi

config_args=("algorithm=$1" "model=$2")
if [[ $# -eq 3 ]]; then
    config_args+=("file=$3")
fi
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

cd "$repo_root"
snakemake \
    --snakefile workflow/Snakefile \
    --configfile config/config.yml \
    --software-deployment-method conda \
    --cores "${THREADS:-32}" \
    --rerun-incomplete \
    --printshellcmds \
    --config "${config_args[@]}"
