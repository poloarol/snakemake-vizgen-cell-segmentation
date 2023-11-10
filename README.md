# snakemake-vizgen-cell-segmentation
A snakemake pipeline to perform cell segmentation on MERFISH spatial transcriptomics data.

## Fetaures
This snakemake pipeline is a wrapper around the [VizGen Post-processing Tool](https://vizgen.github.io/vizgen-postprocessing/index.html),
to perfrom cell segmentation on MERFISH spatial transcriptomics data.

### Build Docker image
- Create image: `docker build vizgen-segmentation .`
- Test image: `docker run vizgen-segmentation`
- Mount disk: `docker run --rm -it --entrypoint /bin/bash -v <path-to-folder>:<docker-folder-name> vizgen-segmentation`

### Run test on pipeline

- Using watershed segmentation algorithm: `bash run_test.sh watershed zero`
- Using cellpose model for segmentation:
    - experimental model nuclei-only: `bash run_test.sh cellpose three`


### Run the pipeline with desired VPT model

- Using watershed segmentation algorithm: `bash run.sh watershed zero`
- Using cellpose model for segmentation:
    - experimental model nuclei-only: `bash run.sh cellpose three`
    - experimental model cytoplasm with nuclei Z3: `bash run.sh cellpose two`
    - experimental model cytoplasm with nuclei Z3: `bash run.sh cellpose one`

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
