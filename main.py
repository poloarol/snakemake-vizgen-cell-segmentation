
from platform import python_version

import snakemake

print("A Snakemake workflow for cell segmentation of Vizgen spatial transcriptomics data.\n")

print(f"- Python: {python_version()}")
print(f"- Snakemake: {snakemake.__version__}")
print("- VPT: 1.3.3 (installed in the workflow's isolated environment)")