# snakemake-vizgen-cell-segmentation
A snakemake pipeline to perform cell segmentation on MERFISH spatial transcriptomics data.

## Fetaures
This snakemake pipeline is a wrapper around the [VizGen Post-processing Tool](https://vizgen.github.io/vizgen-postprocessing/index.html),
to perfrom cell segmentation on MERFISH spatial transcriptomics data.

### Build Docker image
- Create image: `docker build -t vizgen-segmentation .`
- Test image: `docker run vizgen-segmentation`
- Mount disk: `docker run --rm -it --entrypoint /bin/bash -v <path-to-folder>:<docker-folder-name> vizgen-segmentation`

### Run test on pipeline

- Using watershed segmentation algorithm: `bash run_test.sh watershed zero`
- Using cellpose model for segmentation:
    - experimental model nuclei-only: `bash run_test.sh cellpose three`


### Run the pipeline with desired VPT model

- Using watershed segmentation algorithm: `bash run.sh watershed zero <vgz-file-name>`
- Using cellpose model for segmentation:
    - experimental model nuclei-only: `bash run.sh cellpose three `
    - experimental model cytoplasm with nuclei Z3: `bash run.sh cellpose two <vgz-file-name>`
    - experimental model cytoplasm with nuclei Z3: `bash run.sh cellpose one <vgz-file-name>`


### Rules input/output
[X] rule identify_cell_boundaries:
    - input
        - <path-to-raw-sample>\images\*.tif
        - <path-to-raw-samples>\images\micron_to_mosaic_pixel_transform.csv
    - output
        - <path-to-output-folder>\cellpose_micron_space.parquet
        - <path-to-output-folder>\cellpose_mosaic_space.parquet
        - <path-to-output-folder>\segmentation_specification.json
        - <path-to-output-folder>\results_tiles\0.parquet
        - <path-to-output-folder>\results_tiles\1.parquet
        - <path-to-output-folder>\results_tiles\2.parquet

[X] rule partition_transcripts_cells:
    - input:
        - <path-to-raw-samples>\detected_transcripts.csv
        - <path-to-output-folder>\cellpose_micron_space.parquet
    - output:
        - <path-to-output-folder>\cell_by_gene.csv
        - <path-to-output-folder>\detected_transcripts.csv

[X] rule calc_cell_metadata:
    - input:
        - <path-to-output-folder>\cellpose_micron_space.parquet
        - <path-to-output-folder>\cell_by_gene.csv
    - output:
        - <path-to-output-folder>\cell_metadata.csv

[X] rule calc_cell_sum_signal:
    - input:
        - <path-to-raw-sample>\images\*.tif
        - <path-to-raw-samples>\images\micron_to_mosaic_pixel_transform.csv
        - <path-to-output-folder>\cellpose_micron_space.parquet
    - output:
        - <path-to-output-folder>\sum_signal.csv

[X] rule update_vizgen:
    - input:
        - <path-to-output-folder>\cellpose_micron_space.parquet
        - <path-to-output-folder>\cell_by_gene.csv
        - <path-to-output-folder>\cell_metadata.csv
        - <path-to-raw-sample>\<project_name>-vizgen-file.vgz
    - output:
        - <path-to-output-folder>\yy-mm-dd_<project_name>updated.vgz

### Structure of output
    <path-to-output>\
    |   <sample-name>\
    |       results_tiles\
    |           0.parquet
    |           1.parquet
    |           2.parquet
    |       cellpose_micron_space.parquet
    |       cellpose_mosaic_space.parquet
    |       segmentaion_segmentation.json
    |       cell_by_gene.csv
    |       detected_transcripts.csv
    |       cell_metadata.csv
    |       sum_signals.csv
    |       <yy_mm_dd_hh_mm_ss_<project_name>_updated.vgz>
