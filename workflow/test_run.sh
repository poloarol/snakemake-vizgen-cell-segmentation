#!/bin/bash snakemake

algorithm=$1
model=$2

snakemake -n --config algorithm=${algorithm} model=${model} \
    --allowed-rules identify_cell_boundaries partition_transcripts_cells calc_cell_metadata calc_cell_sum_signal \
    --cores 1