# Stage 1: Builder image with all optimization flags
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04 AS builder

# Build-time optimization environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    CMAKE_BUILD_PARALLEL_LEVEL=8 \
    TORCH_CUDA_ARCH_LIST="8.6;8.9;9.0" \
    CUDA_HOME=/usr/local/cuda \
    FORCE_CUDA=1 \
    PIP_PREFER_BINARY=0 \
    TORCH_NVCC_FLAGS="-Xfatbin -compress-all" \
    NVCC_FLAGS="-O3 --use_fast_math" \
    CFLAGS="-O3 -march=native -mtune=native" \
    CXXFLAGS="-O3 -march=native -mtune=native"

# Install Python, build tools and development dependencies
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3-pip \
    git \
    wget \
    libgl1 \
    build-essential \
    ninja-build \
    && ln -sf /usr/bin/python3.11 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install comfy-cli with optimized build flags
RUN pip install --no-cache-dir comfy-cli

# Install ComfyUI with optimized build
RUN /usr/bin/yes | comfy --workspace /comfyui install --cuda-version 12.4 --nvidia --version 0.3.27

# Install optimized PyTorch with CUDA 12.4 support
RUN pip install --no-cache-dir --force-reinstall torch torchvision torchaudio xformers inference --extra-index-url https://download.pytorch.org/whl/cu124

# Change working directory to ComfyUI
WORKDIR /comfyui

# Install all dependencies with optimized builds
RUN pip install --no-cache-dir runpod requests azure-storage-blob azure-identity huggingface_hub \
    numpy pillow scipy transformers safetensors aiohttp accelerate pyyaml dill

# Support for the network volume
ADD src/extra_model_paths.yaml ./

# Go back to the root
WORKDIR /

# Add scripts
ADD src/start.sh src/restore_snapshot.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh /restore_snapshot.sh

# Optionally copy the snapshot file
ADD *snapshot*.json /

# Restore the snapshot to install custom nodes
RUN /restore_snapshot.sh

# Download models (if needed)
ARG HUGGINGFACE_ACCESS_TOKEN
ARG MODEL_TYPE

# Create model directories and download checkpoints
WORKDIR /comfyui
RUN mkdir -p models/checkpoints models/vae && \
    if [ "$MODEL_TYPE" = "sdxl" ]; then \
      wget -O models/checkpoints/sd_xl_base_1.0.safetensors https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors && \
      wget -O models/vae/sdxl_vae.safetensors https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors && \
      wget -O models/vae/sdxl-vae-fp16-fix.safetensors https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae.safetensors; \
    fi

# Pre-compile Python modules to bytecode for faster imports
RUN find /comfyui -name "*.py" -type f -exec python -m py_compile {} \;

# Stage 2: Final runtime image
FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04 AS final

# Runtime optimization environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512 \
    CUDA_DEVICE_MAX_CONNECTIONS=1 \
    CUDA_MODULE_LOADING=LAZY \
    PYTORCH_JIT=1 \
    TORCH_CUDNN_V8_API_ENABLED=1 \
    OMP_NUM_THREADS=4 \
    MKL_NUM_THREADS=4 \
    PATH="/opt/venv/bin:$PATH" \
    PYTHONPATH="/comfyui:$PYTHONPATH"

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-venv \
    git \
    wget \
    libgl1 \
    google-perftools \
    && ln -sf /usr/bin/python3.11 /usr/bin/python \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Copy virtual environment with all optimized packages
COPY --from=builder /opt/venv /opt/venv

# Copy ComfyUI and all its compiled code
COPY --from=builder /comfyui /comfyui

# Copy scripts and snapshot
COPY --from=builder /start.sh /restore_snapshot.sh /rp_handler.py /test_input.json /

# Add configuration files
ADD comfyui-config/ /

# Make scripts executable
RUN chmod +x /start.sh /restore_snapshot.sh

# Set initial working directory to root
WORKDIR /

# Start container
CMD ["/start.sh"]