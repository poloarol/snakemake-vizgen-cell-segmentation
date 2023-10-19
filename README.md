# snakemake-vizgen-cell-segmentation
A snakemake pipeline to perform cell segmentation on MERFISH spatial transcriptomics data.

## Fetaures
This snakemake pipeline is a wrapper around the [VizGen Post-processing Tool][https://vizgen.github.io/vizgen-postprocessing/index.html],
to perfrom cell segmentation on spatial transcriptomics

### Run test on pipeline

- Using watershed segmentation algorithm: `bash run_test.sh watershed`
- Using cellpose model for segmentation:
    - experimental model nuclei-only: `bash run_test.sh cellpose three`


## ToDO
- Update documentation and how to use tool
