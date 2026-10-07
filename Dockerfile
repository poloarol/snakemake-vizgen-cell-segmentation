FROM condaforge/miniforge3:latest

WORKDIR /app

COPY environment.yml /tmp/environment.yml
RUN mamba env create --file /tmp/environment.yml \
    && mamba clean --all --yes

COPY config ./config
COPY workflow ./workflow
COPY utils ./utils

ENTRYPOINT ["/opt/conda/envs/vizgen-snakemake/bin/snakemake", "--snakefile", "workflow/Snakefile", "--configfile", "config/config.yml", "--software-deployment-method", "conda"]
CMD ["--cores", "32"]
