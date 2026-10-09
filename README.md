# Snakemake Vizgen Cell Segmentation

A Snakemake workflow for segmenting MERFISH data and regenerating cell-level outputs with the [Vizgen Post-processing Tool (VPT)](https://vizgen.github.io/vizgen-postprocessing/).

## Requirements

- Docker, or Conda/Mamba and Bash
- The raw Vizgen data arranged as described below
- Enough memory and disk space for the image tiles and intermediate outputs

`environment.yml` creates a single Python 3.10 environment containing Snakemake 7.32.4 (the last release supporting Python 3.10), VPT, and the Cellpose 2 plugin, which currently requires Python 3.10 or older. The workflow rules run `vpt` directly from this environment; Snakemake does not create per-rule Conda environments (the `conda:` directives in the Snakefile are disabled).

The environment build constrains setuptools below 82 because an upstream build script imports `pkg_resources`, which setuptools 82 and newer no longer provide. The workflow run script and Docker image apply this constraint automatically.

## Input data

Set `data.input` in [config/config.yml](config/config.yml) to the directory containing one subdirectory per sample. Each sample directory must contain:

```text
<sample>/
├── images/
│   ├── micron_to_mosaic_pixel_transform.csv
│   └── mosaic_<stain>_z<index>.tif
├── detected_transcripts.csv
└── <optional Vizgen .vzg file>
```

The workflow discovers sample directories containing `images/`, then checks for the required transform and transcript files. Place the output directory outside the sample directories; the default is `/data/output`.

A test dataset can be downloaded [[here](https://vizgen.com/vpt/)]

## Configure and run

The configuration file includes defaults for the input/output directories, watershed algorithm, Cellpose models, and thread count. Change the paths in `config/config.yml` for your data. To use a `.vzg` input, pass its filename; it must be present in each sample directory.

### Docker

Build the image:

```bash
docker build -t vizgen-segmentation .
```

Run watershed segmentation and update each sample's `input.vzg`:

```bash
docker run --rm \
  -v "/path/to/data:/data" \
  vizgen-segmentation \
  --config algorithm=watershed model=three file=input.vzg
```

Use `--config algorithm=cellpose model=one` (or `two` or `three`) to select a Cellpose model. Omit `file=...` to produce the segmentation and cell-level tables without updating a `.vzg` file.

### Conda/Mamba

Create and activate the Snakemake environment:

```bash
mamba env create --file environment.yml
mamba activate vizgen-snakemake
```

From the repository root, the default mode runs from the existing `samplesheet.csv`:

```bash
bash workflow/run.sh
```

To make the mode explicit or use another sheet, pass `--samplesheet` and optionally its path. A Vizgen filename can follow the sheet path:

```bash
bash workflow/run.sh --samplesheet path/to/samplesheet.csv input.vzg
```

The samplesheet must include `sample_name`, `path_to_sample`, `algorithm`, and `cellpose_configuration` columns. Paths in `path_to_sample` are resolved relative to the repository root unless absolute. A single run must use the same algorithm and, for Cellpose, the same configured Cellpose model for every row. The script runs the complete workflow, including signal summaries and the final `.vzg` update when a filename is provided. Rule logs are written to `<output>/<sample>/logs/`.

The scripts use `snakemake` from the active environment, or fall back to a Snakemake executable in a repository-local `env/` virtual environment.

### Slurm clusters

The Snakemake environment uses Snakemake 7.32.4, the last release supporting Python 3.10 (needed by `vpt-plugin-cellpose2`), which includes built-in Slurm support. From a Slurm login node with the workflow and input/output filesystems available to compute nodes, submit jobs with a concurrency limit:

```bash
bash workflow/run.sh --slurm 20
```

This submits up to 20 jobs at a time from the default samplesheet. Samplesheet paths, a custom sheet, and the optional Vizgen filename work the same way:

```bash
bash workflow/run.sh --slurm 20 --samplesheet path/to/samplesheet.csv input.vzg
```

The original positional invocation is also supported with `--slurm`, for example `bash workflow/run.sh --slurm 20 watershed three`. `max-jobs` is the maximum number of jobs Snakemake may have running or submitted concurrently. The workflow uses `threads` in `config/config.yml` for CPU requests on the boundary-identification and VZG-update jobs; the Slurm scheduler's aggregate CPU limit defaults to `max-jobs * 32` to match the current `threads: 32` default. Set `SLURM_CPUS_PER_JOB` if you change that thread count. Use `--profile <path>` to apply cluster-specific settings such as account, partition, and default memory/runtime resources:

```bash
bash workflow/run.sh --slurm 20 --profile profiles/slurm
```

The `--slurm` mode uses Snakemake's built-in Slurm support, while ordinary invocations continue to run locally.

To check the planned jobs without running them:

```bash
bash workflow/test_run.sh
```

On a cluster, you can preview the Slurm plan and job limit without submitting anything:

```bash
bash workflow/test_run.sh --slurm 20
```

This requires Snakemake's Slurm support but does not submit jobs because the script always uses `--dry-run`. It accepts the same `--profile` option as the run script for checking cluster-specific configuration:

```bash
bash workflow/test_run.sh --slurm 20 --profile profiles/slurm
```

The dry-run script also accepts a custom samplesheet path and optional Vizgen filename in the same form:

```bash
bash workflow/test_run.sh --slurm 20 --samplesheet path/to/samplesheet.csv input.vzg
```

For compatibility, both scripts retain the original positional form, which discovers samples under `data.input` in `config/config.yml`:

```bash
bash workflow/run.sh watershed three input.vzg
bash workflow/test_run.sh cellpose one
```

The positional form can also be combined with `--slurm` and `--profile`, for example `bash workflow/test_run.sh --slurm 20 watershed three`. The model argument is ignored for watershed, and the Vizgen filename is optional in either mode.

Create a `samplesheet.csv` from the configured input directory for watershed with:

```bash
python workflow/create_samplesheet.py --algorithm watershed
```

For Cellpose, select the model while generating the sheet:

```bash
python workflow/create_samplesheet.py --algorithm cellpose --model three
```

The sheet includes one row for each immediate sample directory containing `images/`. `path_to_sample` is relative to the repository when possible, and `cellpose_configuration` is blank for watershed runs. Override the defaults with `--config <path>` or `--output <path>`. Review the generated sheet before launching the samplesheet-based run.

## Segmentation models

| Algorithm | Model | Configuration |
| --- | --- | --- |
| `watershed` | `one`, `two`, or `three` (ignored) | `utils/watershed_default.json` |
| `cellpose` | `one` | `utils/cellpose_default_1_Zlevel.json` |
| `cellpose` | `two` | `utils/cellpose_default_3_Zlevel.json` |
| `cellpose` | `three` | `utils/cellpose_default_3_Zlevel_nuclei_only.json` |

## Workflow outputs

For each sample, outputs are written under `<data.output>/<algorithm-or-model>/<sample>/`:

```text
watershed/                         # or cellpose_one, cellpose_two, cellpose_three
└── <sample>/
    ├── watershed_micron_space.parquet
    ├── watershed_mosaic_space.parquet
    ├── segmentation_specification.json
    ├── result_tiles/
    ├── cell_by_gene.csv
    ├── detected_transcripts.csv
    ├── cell_metadata.csv
    ├── sum_signals.csv
    └── updated.vzg                 # when a Vizgen filename is supplied
```

Cellpose boundary files use the `cellpose_` prefix. The workflow targets the files produced by the selected segmentation configuration, and the stable `updated.vzg` filename lets Snakemake correctly determine when the update needs to be rerun.

## Workflow steps

1. `identify_cell_boundaries` runs the selected VPT segmentation algorithm.
2. `partition_transcripts_cells` assigns transcripts to cells and creates the cell-by-gene matrix.
3. `calc_cell_metadata` derives per-cell metadata.
4. `calc_cell_sum_signal` measures image signal per cell.
5. `update_vizgen` updates the input `.vzg` when a filename is supplied.
