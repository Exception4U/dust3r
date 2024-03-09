# Use the official Python image as base
ARG CUDA_VERSION=12.1.0
ARG OS_VERSION=20.04
ARG USER_ID=1000

# Define base image.
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${OS_VERSION}

# Set environment variable to prevent timezone selector prompt
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    wget \
    cmake \
    build-essential \
    ffmpeg \
    libsm6 \
    libxext6 \
    git \
 && rm -rf /var/lib/apt/lists/*

# Create non root user and setup environment.
RUN useradd -m -d /home/user -g root -G sudo -u 1000 user
RUN usermod -aG sudo user
# Set user password
RUN echo "user:user" | chpasswd
# Ensure sudo group users are not asked for a password when using sudo command by ammending sudoers file
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to new user and workdir.
USER ${USER_ID}

WORKDIR /app
COPY . /app
RUN git submodule update --init --recursive

# Add local user binary folder to PATH variable.
ENV PATH="${PATH}:/home/user/.local/bin"
SHELL ["/bin/bash", "-c"]

# Install Miniconda
ENV PATH="/opt/conda/bin:${PATH}"
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh \
    && /bin/bash miniconda.sh -b -p /opt/conda \
    && rm miniconda.sh

# Create a conda environment
RUN conda create -n dust3r python=3.11 cmake=3.14.0 && \
    echo "source activate dust3r" > ~/.bashrc
SHELL ["/bin/bash", "-c", "source activate dust3r"]

# Set the working directory in the container

# Install pytorch and torchvision
#RUN conda install pytorch torchvision pytorch-cuda=12.1 -c pytorch -c nvidia

# Install dependencies from the requirements file
RUN pip install -r requirements.txt

# Build croco models
RUN cd croco/models/curope/ && \
    python setup.py build_ext --inplace && \
    cd ../../../

# Create a directory for checkpoints
RUN mkdir -p checkpoints/

# Download pre-trained weights
RUN wget https://download.europe.naverlabs.com/ComputerVision/DUSt3R/DUSt3R_ViTLarge_BaseDecoder_512_dpt.pth -P checkpoints/

# Set the entrypoint command
# ENTRYPOINT ["python3", "demo.py", "--weights", "checkpoints/DUSt3R_ViTLarge_BaseDecoder_512_dpt.pth"]
