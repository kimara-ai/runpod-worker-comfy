# Running and Testing RunPod Worker ComfyUI Locally

This guide explains how to build, run, and test the locally developed version of RunPod Worker ComfyUI on your local machine.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your system
- [Docker Compose](https://docs.docker.com/compose/install/) installed
- NVIDIA GPU with CUDA support
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) installed (for GPU access from Docker)
- Git (to clone the repository)

## Building and Testing Local Changes

### 1. Clone the Repository

```bash
git clone https://github.com/kimara-ai/runpod-worker-comfy.git
cd runpod-worker-comfy
```

### 2. Build the Docker Image Locally

You can build different versions of the image depending on your needs:

```bash
# Build the base image (no models)
docker build -t local/runpod-worker-comfy:dev-base --target base --platform linux/amd64 .

# Build the SDXL image
docker build --build-arg MODEL_TYPE=sdxl -t local/runpod-worker-comfy:dev-sdxl --platform linux/amd64 .

```

> **Note**: Always specify `--platform linux/amd64` to ensure compatibility with RunPod.

### 3. Create a Local Docker Compose File

Create a file named `docker-compose-local.yml` with your locally built image:

```yaml
services:
  comfyui-worker:
    image: local/runpod-worker-comfy:dev-sdxl  # Use your locally built image
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    environment:
      - SERVE_API_LOCALLY=true
      - COMFY_POLLING_INTERVAL_MS=250
      - COMFY_POLLING_MAX_RETRIES=500
    ports:
      - "8000:8000"
      - "8188:8188"
    volumes:
      - ./test_data/output:/comfyui/output       # Test-specific output path
      - ./test_data/volume:/runpod-volume        # Test-specific volume path
      - ./src:/src_local                         # Mount source code for easier development
```

### 4. Create Required Directories

```bash
mkdir -p test_data/output
mkdir -p test_data/volume
```

### 5. Run the Local Docker Image

```bash
docker-compose -f docker-compose-local.yml up
```

This will:
- Start your locally built image
- Enable the local API server (`SERVE_API_LOCALLY=true`)
- Configure NVIDIA GPU support
- Mount local directories for output files and volume data
- Expose ports:
  - 8000: Worker API
  - 8188: ComfyUI interface

### 6. Accessing the Services

Once running, you can access:

- **Local Worker API**: http://localhost:8000
- **ComfyUI Interface**: http://localhost:8188

### 7. Testing the API

Test your local API with the included test workflow:

```bash
# Check the API health endpoint
curl http://localhost:8000/health

# Run a test with the included workflow
curl -X POST -H "Content-Type: application/json" -d @test_input.json http://localhost:8000/run
```

## Alternative: Using Docker Buildx

For more advanced multi-platform builds, you can use Docker Buildx:

```bash
# Build all targets
docker buildx bake --set *.platform=linux/amd64 --set *.output=type=docker

# Build specific targets
docker buildx bake --set *.platform=linux/amd64 --set *.output=type=docker sdxl

# Tag with custom repository
DOCKERHUB_REPO=local RELEASE_VERSION=dev docker buildx bake --set *.platform=linux/amd64 --set *.output=type=docker sdxl
```

### Preventing Docker.io Prefixing

If you want to prevent Docker from adding the `docker.io/` prefix to your image name, you can use:

```bash
# Disable BuildKit
DOCKER_BUILDKIT=0 docker build -t local/runpod-worker-comfy:dev-sdxl --build-arg MODEL_TYPE=sdxl --platform linux/amd64 .

# Or use --no-resolve flag
docker build --no-resolve -t local/runpod-worker-comfy:dev-sdxl --build-arg MODEL_TYPE=sdxl --platform linux/amd64 .
```

This is purely cosmetic - the images will work the same regardless of the prefix.

## Python Testing Without Docker

If you want to test the Python code directly without Docker:

### 1. Create and Activate Virtual Environment

```bash
python -m venv venv
source ./venv/bin/activate  # Linux/Mac
# Or on Windows:
# .\venv\Scripts\activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Run Tests

Run all tests:
```bash
python -m unittest discover
```

Run a specific test:
```bash
python -m unittest tests.test_rp_handler.TestRunpodWorkerComfy.test_bucket_endpoint_not_configured
```

### 4. Start the Handler Server

To start the handler server directly:
```bash
python src/rp_handler.py
```

**Note**: For this to work without Docker, you need ComfyUI running separately, otherwise the handler will not function correctly.

## Testing with Azure Blob Storage

To test with Azure Blob Storage, follow the steps in the [Setting Up SDXL with Azure Blob Storage](#setting-up-sdxl-with-azure-blob-storage) section of this document.

## Setting Up SDXL with Azure Blob Storage

To test with Azure Blob Storage configuration, create a `docker-compose-azure-local.yml` file:

```yaml
services:
  comfyui-worker:
    image: local/runpod-worker-comfy:dev-sdxl  # Your locally built image
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
      - COMFY_POLLING_INTERVAL_MS=250
      - COMFY_POLLING_MAX_RETRIES=500
    ports:
      - "8000:8000"
      - "8188:8188"
    volumes:
      - ./test_data/output:/comfyui/output
      - ./test_data/volume:/runpod-volume
      - ./src:/src_local
```

To run the container with Azure Blob Storage configuration:

1. Generate an Azure Storage connection string from the Azure Portal:
   - Go to your Storage Account
   - Navigate to "Security + networking" → "Access keys" 
   - Copy one of the connection strings

2. Export the connection string as an environment variable:
   ```bash
   export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=yourstorageaccount;AccountKey=yourkey;EndpointSuffix=core.windows.net"
   ```

3. Start the container with the Azure-specific compose file:
   ```bash
   docker compose -f docker-compose-azure-local.yml up
   ```

4. Test with the sample workflow:
   ```bash
   curl -X POST -H "Content-Type: application/json" -d @test_input.json http://localhost:8000/run
   ```

The response should include an Azure Blob Storage URL for the generated image.

For step-by-step Azure setup instructions, see the [Azure Blob Storage Setup](#setting-up-sdxl-with-azure-blob-storage) section in this document.

## Development Workflow Tips

1. **Making Changes**:
   - Edit source files in the `src/` directory
   - Rebuild the Docker image with your changes
   - Test using the methods above

2. **Adding Custom Models**:
   - Add download commands in the Dockerfile
   - Rebuild the image with the appropriate model type

3. **Adding Custom Nodes**:
   - Export a snapshot from ComfyUI Manager
   - Save the `*_snapshot.json` file in the project root directory
   - Rebuild the image - the snapshot will be automatically restored

4. **Platform Considerations**:
   - Always use `--platform linux/amd64` for Docker builds
   - For Windows, follow the [Setup for Windows](#setup-for-windows) instructions in the main README

## Troubleshooting

- **GPU Not Detected**: Ensure the NVIDIA Container Toolkit is properly installed and configured
- **Container Exits Immediately**: Check Docker logs for error messages
- **API Not Reachable**: Verify that ports 8000 and 8188 are not in use by other applications
- **Azure Blob Storage Issues**: Check the connection string and container existence
- **Build Errors**: Ensure Docker has enough resources (CPU, memory) allocated

## Windows-Specific Setup

For Windows users, WSL2 with Ubuntu is recommended. Follow the detailed setup instructions in the [README.md](../README.md#setup-for-windows) document.