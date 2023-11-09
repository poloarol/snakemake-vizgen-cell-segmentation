# snakemake-vizgen-cell-segmentation
A snakemake pipeline to perform cell segmentation on MERFISH spatial transcriptomics data.

## Fetaures
This snakemake pipeline is a wrapper around the [VizGen Post-processing Tool](https://vizgen.github.io/vizgen-postprocessing/index.html),
to perfrom cell segmentation on MERFISH spatial transcriptomics data.

### Build Docker image
- Create image: `docker built -t vizgen-segmentation .`
- Test image: `docker run --rm -it --entrypoint /bin/bash vizgen-segmentation`
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

## ToDO
- Describe output structure
