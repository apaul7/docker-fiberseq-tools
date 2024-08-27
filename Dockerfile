FROM continuumio/miniconda3:23.10.0-1

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y \
        build-essential \
        cmake \
        curl \
        gcc \
        git \
        less \
        rsync \
        tcsh \
        unzip \
        vim \
        wget \
        && rm -rf /var/lib/apt/lists/*

# install kent libs
# https://github.com/ucscGenomeBrowser/kent/
WORKDIR /lib/kent/
RUN rsync -azvP rsync://hgdownload.soe.ucsc.edu/genome/admin/exe/linux.x86_64/ .

ENV CARGO_HOME=/lib/cargo
WORKDIR /tmp
RUN wget https://static.rust-lang.org/dist/rust-1.75.0-x86_64-unknown-linux-gnu.tar.gz \
  && tar -zxvf rust-1.75.0-x86_64-unknown-linux-gnu.tar.gz \
  && cd rust-1.75.0-x86_64-unknown-linux-gnu \
  && ./install.sh \
  && cd / \
  && rm -rf /tmp/rust-1.75.0-x86_64-unknown-linux-gnu /tmp/rust-1.75.0-x86_64-unknown-linux-gnu.tar.gz

WORKDIR /lib/
ENV PYTORCH_VERSION="2.2.0"
RUN wget  https://download.pytorch.org/libtorch/cu118/libtorch-shared-with-deps-${PYTORCH_VERSION}%2Bcu118.zip \
  && unzip libtorch-shared-with-deps-${PYTORCH_VERSION}+cu118.zip \
  && rm libtorch-shared-with-deps-${PYTORCH_VERSION}+cu118.zip

ENV LIBTORCH_CXX11_ABI=0
ENV LIBTORCH=/lib/libtorch
ENV LD_LIBRARY_PATH=${LIBTORCH}/lib:$LD_LIBRARY_PATH
ENV DYLD_LIBRARY_PATH=${LIBTORCH}/lib:$LD_LIBRARY_PATH

ENV FIBERTOOLS_VERSION="0.5.3"
RUN cargo install --all-features fibertools-rs@${FIBERTOOLS_VERSION}

RUN pip install --upgrade pip
RUN conda install -n base -c conda-forge mamba
RUN mamba create -c conda-forge -c bioconda -n snakemake 'snakemake>=8.4'
RUN /opt/conda/envs/snakemake/bin/pip install snakemake-executor-plugin-cluster-generic snakemake-executor-plugin-lsf

#fiberseq qc
WORKDIR /git
RUN git clone https://github.com/fiberseq/fiberseq-qc.git \
  && cd fiberseq-qc \
  && conda create -n fiberseq-qc \
  && mamba env update -n fiberseq-qc --file env/qc.yaml

# entrypoint is the wrapper script to add conda env to path
WORKDIR /usr/local/bin/
COPY entrypoint .
RUN chmod 777 entrypoint
WORKDIR /
ENTRYPOINT ["/usr/local/bin/entrypoint"]
