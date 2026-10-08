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
if command -v snakemake >/dev/null 2>&1; then
    snakemake_cmd=(snakemake)
elif [[ -x "$repo_root/env/Scripts/snakemake.exe" ]]; then
    snakemake_cmd=("$repo_root/env/Scripts/snakemake.exe")
elif [[ -x "$repo_root/env/bin/snakemake" ]]; then
    snakemake_cmd=("$repo_root/env/bin/snakemake")
else
    echo "Snakemake was not found. Create and activate the vizgen-snakemake environment as described in README.md." >&2
    exit 127
fi

"${snakemake_cmd[@]}" \
    --snakefile workflow/Snakefile \
    --configfile config/config.yml \
    --software-deployment-method conda \
    --cores "${THREADS:-32}" \
    --rerun-incomplete \
    --printshellcmds \
    --config "${config_args[@]}"
