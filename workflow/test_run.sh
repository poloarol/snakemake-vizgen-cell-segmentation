#!/bin/bash snakemake

algorithm=$1
model=$2

snakemake -n --config algorithm=${algorithm} model=${model} --cores 1