#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

cd "$repo_root"
export PIP_CONSTRAINT="$repo_root/workflow/envs/pip-constraints.txt"
slurm_jobs=""
profile_args=()
workflow_args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --slurm)
            if [[ $# -lt 2 || ! "$2" =~ ^[1-9][0-9]*$ ]]; then
                echo "Usage: $0 [--slurm max-jobs] [--profile profile] [workflow arguments]" >&2
                exit 2
            fi
            if [[ -n "$slurm_jobs" ]]; then
                echo "--slurm may only be specified once" >&2
                exit 2
            fi
            slurm_jobs="$2"
            shift 2
            ;;
        --profile)
            if [[ $# -lt 2 || -z "$2" ]]; then
                echo "--profile requires a profile path" >&2
                exit 2
            fi
            profile_args=(--profile "$2")
            shift 2
            ;;
        *)
            workflow_args+=("$1")
            shift
            ;;
    esac
done
set -- "${workflow_args[@]}"

if [[ $# -eq 0 || "${1:-}" == "--samplesheet" ]]; then
    if [[ "${1:-}" == "--samplesheet" ]]; then
        shift
    fi
    samplesheet_path="${1:-samplesheet.csv}"
    if [[ $# -gt 0 ]]; then
        shift
    fi
    if [[ $# -gt 1 ]]; then
        echo "Usage: $0 [--slurm max-jobs] [--profile profile] --samplesheet [samplesheet.csv] [vizgen-filename]" >&2
        exit 2
    fi
    if [[ ! -f "$samplesheet_path" ]]; then
        echo "Samplesheet not found: $samplesheet_path" >&2
        exit 2
    fi
    config_args=("samplesheet=$samplesheet_path")
    if [[ $# -eq 1 ]]; then
        config_args+=("file=$1")
    fi
else
    if [[ $# -lt 2 || $# -gt 3 ]]; then
        echo "Usage: $0 [--slurm max-jobs] [--profile profile] <watershed|cellpose> <one|two|three> [vizgen-filename]" >&2
        echo "   or: $0 [--slurm max-jobs] [--profile profile] --samplesheet [samplesheet.csv] [vizgen-filename]" >&2
        exit 2
    fi
    config_args=("algorithm=$1" "model=$2")
    if [[ $# -eq 3 ]]; then
        config_args+=("file=$3")
    fi
fi

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

execution_args=(--cores "${THREADS:-32}")
if [[ -n "$slurm_jobs" ]]; then
    slurm_cpus_per_job="${SLURM_CPUS_PER_JOB:-32}"
    if [[ ! "$slurm_cpus_per_job" =~ ^[1-9][0-9]*$ ]]; then
        echo "SLURM_CPUS_PER_JOB must be a positive integer" >&2
        exit 2
    fi
    slurm_cores=$((slurm_jobs * slurm_cpus_per_job))
    execution_args=(--slurm --jobs "$slurm_jobs" --cores "$slurm_cores")
fi

"${snakemake_cmd[@]}" \
    --snakefile workflow/Snakefile \
    --configfile config/config.yml \
    "${execution_args[@]}" \
    "${profile_args[@]}" \
    --rerun-incomplete \
    --printshellcmds \
    --config "${config_args[@]}"
