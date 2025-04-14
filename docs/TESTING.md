# Local Testing Guide for RunPod Worker ComfyUI

This guide walks you through building, running, and testing the RunPod Worker ComfyUI on your local development machine.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)
- NVIDIA GPU with CUDA support (min. 4GB VRAM recommended)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- Git

## Quick Start

```bash
# Clone repository
git clone https://github.com/kimara-ai/runpod-worker-comfy.git
cd runpod-worker-comfy

# Build base image
docker build -t local/runpod-worker-comfy:dev-base --target base --platform linux/amd64 .

# Create test directories
mkdir -p test_data/{output,volume}

# Run with Docker Compose
docker compose -f docker-compose.yml up
```

## Building Images

Build options for different use cases:

```bash
# Base image (minimal, no models)
docker build -t local/runpod-worker-comfy:dev-base --target base --platform linux/amd64 .

# SDXL image (includes SDXL models, ~15GB)
docker build --build-arg MODEL_TYPE=sdxl -t local/runpod-worker-comfy:dev-sdxl --platform linux/amd64 .
```

> **Important**:
> - Use `--platform linux/amd64` for RunPod compatibility
> - SDXL builds require ~15GB disk space

## Testing with Docker Compose

### Basic Setup

Create `docker-compose-local.yml`:

```yaml
services:
  comfyui-worker:
    image: local/runpod-worker-comfy:dev-sdxl
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    environment:
      - SERVE_API_LOCALLY=true
    ports:
      - "8000:8000"  # API
      - "8188:8188"  # UI
    volumes:
      - ./test_data/output:/comfyui/output
      - ./test_data/volume:/runpod-volume
      - ./src:/src_local
```

Run:

```bash
docker compose -f docker-compose-local.yml up
```

### Testing the API

Once the container is running:

```bash
# Health check
curl http://localhost:8000/health

# Run a test workflow
curl -X POST -H "Content-Type: application/json" -d @test_input.json http://localhost:8000/run
```

Visit http://localhost:8188 to access the ComfyUI interface directly.

## Advanced Build Options

### Using Docker Buildx

For multi-platform or multi-target builds:

```bash
# Build all targets
docker buildx bake --set *.platform=linux/amd64 --set *.output=type=docker

# Build specific target
docker buildx bake --set *.platform=linux/amd64 --set *.output=type=docker sdxl

# Custom repository and version
DOCKERHUB_REPO=local RELEASE_VERSION=dev docker buildx bake \
  --set *.platform=linux/amd64 --set *.output=type=docker sdxl
```

### Image Naming Options

To prevent Docker from adding the `docker.io/` prefix:

```bash
# Option 1: Disable BuildKit
DOCKER_BUILDKIT=0 docker build -t local/runpod-worker-comfy:dev-sdxl \
  --build-arg MODEL_TYPE=sdxl --platform linux/amd64 .

# Option 2: Use --no-resolve flag
docker build --no-resolve -t local/runpod-worker-comfy:dev-sdxl \
  --build-arg MODEL_TYPE=sdxl --platform linux/amd64 .
```

## Python Testing Without Docker

For testing the Python code directly:

```bash
# Setup virtual environment
python -m venv venv
source ./venv/bin/activate  # Linux/Mac
# or .\venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Run all tests
python -m unittest discover

# Run specific test
python -m unittest tests.test_rp_handler.TestRunpodWorkerComfy.test_bucket_endpoint_not_configured

# Run handler service directly
python src/rp_handler.py
```

> **Note**: Without Docker, you'll need ComfyUI running separately for the handler to function.

## Testing with Azure Blob Storage

### Azure Setup

1. Create `docker-compose-azure-local.yml`:

```yaml
services:
  comfyui-worker:
    image: local/runpod-worker-comfy:dev-sdxl
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    environment:
      - SERVE_API_LOCALLY=true
      - IMAGE_RETURN_METHOD=azure
      - AZURE_STORAGE_CONNECTION_STRING=${AZURE_STORAGE_CONNECTION_STRING}
      - AZURE_STORAGE_CONTAINER_NAME=comfyui-test-images
    ports:
      - "8000:8000"
      - "8188:8188"
    volumes:
      - ./test_data/output:/comfyui/output
      - ./test_data/volume:/runpod-volume
      - ./src:/src_local
```

2. Set Azure connection string:
```bash
export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=youraccount;AccountKey=yourkey;EndpointSuffix=core.windows.net"
```

3. Run and test:
```bash
docker compose -f docker-compose-azure-local.yml up

# In another terminal
curl -X POST -H "Content-Type: application/json" -d @test_input.json http://localhost:8000/run
```

Response will include Azure Blob Storage URLs.

## Development Tips

1. **Code Changes**:
   - Edit files in mounted `./src:/src_local` volume
   - For bigger changes, rebuild the image

2. **Custom Models**:
   - Add download commands to Dockerfile
   - Use `MODEL_TYPE` build arg

3. **Custom Nodes**:
   - Export snapshot from ComfyUI Manager
   - Save as `*_snapshot.json` in project root

4. **Cross-Platform**:
   - Build with `--platform linux/amd64`
   - Windows: use WSL2

## Troubleshooting

Common issues and their solutions:

- **GPU not detected**: Check NVIDIA Container Toolkit setup
- **Container exits immediately**: View logs with `docker logs <container_id>`
- **API not responding**: Check if ports 8000/8188 are already in use
- **Azure Blob issues**: Verify connection string and container name

For Windows-specific setup, see [README.md](../README.md#setup-for-windows).