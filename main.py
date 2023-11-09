
from platform import python_version

import snakemake

print('A VPT/cellpose snakemake wrapper to assist in cell segmentation from Vizgen Spatial transcriptomics')

print(f'python: {python_version()}')
print(f'snakemake: {snakemake.__version__}')