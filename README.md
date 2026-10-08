# Snakemake Vizgen Cell Segmentation

A Snakemake workflow for segmenting MERFISH data and regenerating cell-level outputs with the [Vizgen Post-processing Tool (VPT)](https://vizgen.github.io/vizgen-postprocessing/).

## Requirements

- Docker, or Conda/Mamba and Bash
- The raw Vizgen data arranged as described below
- Enough memory and disk space for the image tiles and intermediate outputs

This workflow separates its software environments because the current Snakemake release requires Python 3.11+, while VPT and the Cellpose 2 plugin currently require Python 3.10 or older:

- `environment.yml`: Python 3.11 and Snakemake 9.27.0
- `workflow/envs/vpt.yml`: Python 3.10, VPT 1.3.3, and the Cellpose 2 plugin 1.0.1

Snakemake creates the VPT environment for workflow rules. These versions are the latest releases compatible with the upstream Python requirements; VPT's plugin dependencies constrain some underlying scientific libraries to older versions.

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

From the repository root, run:

```bash
bash workflow/run.sh watershed three input.vzg
```

For Cellpose, use `bash workflow/run.sh cellpose one input.vzg` (or `two` or `three`). The script runs the complete workflow, including signal summaries and the final `.vzg` update. Snakemake uses the per-rule Conda environment in `workflow/envs/vpt.yml`.

The scripts use `snakemake` from the active environment, or fall back to a Snakemake executable in a repository-local `env/` virtual environment.

To check the planned jobs without running them:

```bash
bash workflow/test_run.sh watershed three input.vzg
```

Both scripts accept an algorithm and model; the Vizgen filename is optional. The model argument is ignored for watershed.

Create a `samplesheet.csv` from the configured input directory and algorithm with:

```bash
python workflow/create_samplesheet.py
```

The sheet includes one row for each immediate sample directory containing `images/`. `path_to_sample` is relative to the repository when possible, and `cellpose_configuration` is blank for watershed runs. Override the defaults with `--config <path>` or `--output <path>`.

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
