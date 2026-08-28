# snakemake-vizgen-cell-segmentation

A Snakemake pipeline for performing cell segmentation on MERFISH spatial transcriptomics data.

```text
              CONFIGURATION
                    │
                    ▼
          Select segmentation model
                    │
                    ▼
┌──────────────────────────────────────────┐
│              FOR EACH SAMPLE             │
│                                          │
│  Images ──→ Cell segmentation            │
│                  │                       │
│                  ▼                       │
│          Cell boundaries                 │
│                  │                       │
│                  ▼                       │
│  Transcripts ──→ Cell assignment         │
│                  │                       │
│                  ▼                       │
│          Cell × gene matrix              │
│                  │                       │
│                  ├──→ Cell metadata       │
│                  │                       │
│  Images ─────────┴──→ Signal summaries   │
│                                          │
└──────────────────────┬───────────────────┘
                       ▼
                 Updated .vgz
```


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

## Workflow rules

### `identify_cell_boundaries`

**Purpose:** Identify cell boundaries from MERFISH imaging data using the selected segmentation algorithm.

This rule takes the raw MERFISH images and the micron-to-mosaic pixel transformation and runs the VizGen Post-processing Tool to generate cell boundary information. The workflow supports both watershed and Cellpose-based segmentation.

**Inputs**

* Raw MERFISH imaging data
* Micron-to-mosaic pixel transformation file

**Outputs**

* Cell boundaries in micron space
* Cell boundaries in mosaic space
* Segmentation specification
* Segmentation result tiles

---

### `partition_transcripts_cells`

**Purpose:** Assign detected transcripts to segmented cells and generate a cell-by-gene matrix.

This rule combines the detected transcript locations with the cell boundaries generated during segmentation. Each transcript is assigned to the appropriate cell based on its spatial location.

**Inputs**

* Detected transcripts
* Cell boundaries

**Outputs**

* Cell-by-gene expression matrix
* Transcript-level cell assignments

---

### `calc_cell_metadata`

**Purpose:** Calculate metadata for each segmented cell.

This rule uses the cell boundaries and cell-by-gene matrix to derive cell-level metadata that can be used for downstream analysis and quality control.

**Inputs**

* Cell boundaries
* Cell-by-gene matrix

**Outputs**

* Cell metadata

---

### `calc_cell_sum_signal`

**Purpose:** Calculate the summed imaging signal associated with each segmented cell.

This rule combines the original MERFISH images, spatial transformation information, and cell boundaries to quantify imaging signal within each cell.

**Inputs**

* Raw MERFISH imaging data
* Micron-to-mosaic pixel transformation file
* Cell boundaries

**Outputs**

* Cell-level summed signal

---

### `update_vizgen`

**Purpose:** Integrate the segmentation and cell-level analysis results back into the original VizGen dataset.

This final rule combines the original `.vgz` file with the generated cell boundaries, cell-by-gene matrix, and cell metadata to produce an updated VizGen dataset.

**Inputs**

* Original VizGen `.vgz` file
* Cell boundaries
* Cell-by-gene matrix
* Cell metadata

**Output**

* Updated `.vgz` file

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
