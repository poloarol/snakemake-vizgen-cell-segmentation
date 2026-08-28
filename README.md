# snakemake-vizgen-cell-segmentation

A Snakemake pipeline for performing cell segmentation on MERFISH spatial transcriptomics data.

MERFISH / Vizgen data
        │
        ▼
identify_cell_boundaries
        │
        ▼
partition_transcripts_cells
        │
        ├───────────────┐
        ▼               ▼
calc_cell_metadata   calc_cell_sum_signal
        │               │
        └───────┬───────┘
                ▼
          update_vizgen
                │
                ▼
       updated .vgz file

## Features

This Snakemake pipeline is a wrapper around the [VizGen Post-processing Tool](https://vizgen.github.io/vizgen-postprocessing/index.html) for performing cell segmentation on MERFISH spatial transcriptomics data.

## Build Docker image

Build the Docker image:

```bash
docker build -t vizgen-segmentation .
```

Test the Docker image:

```bash
docker run vizgen-segmentation
```

Mount a local directory inside the Docker container:

```bash
docker run --rm -it \
    --entrypoint /bin/bash \
    -v <path-to-folder>:<docker-folder-name> \
    vizgen-segmentation
```

## Run pipeline tests

### Watershed segmentation

```bash
bash run_test.sh watershed zero
```

### Cellpose segmentation

Experimental nuclei-only model:

```bash
bash run_test.sh cellpose three
```

## Run the pipeline with a desired VPT model

### Watershed segmentation

```bash
bash run.sh watershed zero <vgz-file-name>
```

### Cellpose segmentation

Experimental nuclei-only model:

```bash
bash run.sh cellpose three <vgz-file-name>
```

Experimental cytoplasm model with nuclei Z3:

```bash
bash run.sh cellpose two <vgz-file-name>
```

Experimental cytoplasm model with nuclei Z3:

```bash
bash run.sh cellpose one <vgz-file-name>
```

## Rule inputs and outputs

### `identify_cell_boundaries`

**Input**

* `<path-to-raw-sample>/images/*.tif`
* `<path-to-raw-samples>/images/micron_to_mosaic_pixel_transform.csv`

**Output**

* `<path-to-output-folder>/cellpose_micron_space.parquet`
* `<path-to-output-folder>/cellpose_mosaic_space.parquet`
* `<path-to-output-folder>/segmentation_specification.json`
* `<path-to-output-folder>/results_tiles/0.parquet`
* `<path-to-output-folder>/results_tiles/1.parquet`
* `<path-to-output-folder>/results_tiles/2.parquet`

### `partition_transcripts_cells`

**Input**

* `<path-to-raw-samples>/detected_transcripts.csv`
* `<path-to-output-folder>/cellpose_micron_space.parquet`

**Output**

* `<path-to-output-folder>/cell_by_gene.csv`
* `<path-to-output-folder>/detected_transcripts.csv`

### `calc_cell_metadata`

**Input**

* `<path-to-output-folder>/cellpose_micron_space.parquet`
* `<path-to-output-folder>/cell_by_gene.csv`

**Output**

* `<path-to-output-folder>/cell_metadata.csv`

### `calc_cell_sum_signal`

**Input**

* `<path-to-raw-sample>/images/*.tif`
* `<path-to-raw-samples>/images/micron_to_mosaic_pixel_transform.csv`
* `<path-to-output-folder>/cellpose_micron_space.parquet`

**Output**

* `<path-to-output-folder>/sum_signal.csv`

### `update_vizgen`

**Input**

* `<path-to-output-folder>/cellpose_micron_space.parquet`
* `<path-to-output-folder>/cell_by_gene.csv`
* `<path-to-output-folder>/cell_metadata.csv`
* `<path-to-raw-sample>/<project_name>-vizgen-file.vgz`

**Output**

* `<path-to-output-folder>/yy-mm-dd_<project_name>_updated.vgz`

## Output structure

The pipeline produces the following directory structure:

```text
<path-to-output>/
└── <sample-name>/
    ├── results_tiles/
    │   ├── 0.parquet
    │   ├── 1.parquet
    │   └── 2.parquet
    ├── cellpose_micron_space.parquet
    ├── cellpose_mosaic_space.parquet
    ├── segmentation_specification.json
    ├── cell_by_gene.csv
    ├── detected_transcripts.csv
    ├── cell_metadata.csv
    ├── sum_signal.csv
    └── <yy_mm_dd_hh_mm_ss>_<project_name>_updated.vgz
```
