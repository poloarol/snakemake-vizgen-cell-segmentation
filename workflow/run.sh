#!/bin/bash snakemake

algorithm=$1
model=$2
vgz_file=$3

snakemake --config algorithm=${algorithm} model=${model} \
    --cores 32 --latency-wait 600 \
    --allowed-rules identify_cell_boundaries partition_transcripts_cells calc_cell_metadata \
    2> output.vpt.part1.logs


sleep 30


snakemake --config algorithm=${algorithm} model=${model} \
    --cores 32 --latency-wait 600 \
    --allowed-rules calc_cell_sum_signal 2> output.vpt.part2.logs


sleep 30

snakemake -n --config algorithm=${algorithm} model=${model} file=${vgz_file} \
    --allowed-rules update_vizgen \
    --cores 1