#!/bin/bash snakemake

algorithm=$1
model=$2
vgz_file=$3

snakemake -n --config algorithm=${algorithm} model=${model} file=${vgz_file} --cores 1