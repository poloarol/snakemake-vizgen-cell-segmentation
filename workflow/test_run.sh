#!/bin/bash snakemake

algorithm=$1
model=$2

snakemake -n \
    --config algorithm=${algorithm} \
    --use-conda --conda-frontend conda \