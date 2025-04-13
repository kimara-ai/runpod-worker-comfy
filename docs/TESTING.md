# Running RunPod Worker ComfyUI Locally for Testing

This guide explains how to run and test the RunPod Worker ComfyUI Docker image on your local machine.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your system
- NVIDIA GPU with CUDA support
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) installed (for GPU access from Docker)

## Setup Process

### 1. Clone the Repository

```bash
git clone https://github.com/blib-la/runpod-worker-comfy.git
cd runpod-worker-comfy
```

### 2. Start with Docker Compose

The easiest way to run the worker locally is using Docker Compose:

```bash
docker-compose up
```

This will:
- Pull the SDXL image version (`timpietruskyblibla/runpod-worker-comfy:3.4.0-sdxl`)
- Mount local directories for output files and volume data
- Enable the local API server (`SERVE_API_LOCALLY=true`)
- Configure NVIDIA GPU support
- Expose ports:
  - 8000: Worker API
  - 8188: ComfyUI interface

### 3. Accessing the Services

Once running, you can access:

- **Local Worker API**: http://localhost:8000
- **ComfyUI Interface**: http://localhost:8188

## Testing the Handler

If you want to test the RunPod handler directly without Docker, you can use a virtual environment:

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

**Note**: For this to work, you also need ComfyUI running, otherwise the handler will not function correctly.

## Setting Up SDXL with Azure Blob Storage

Here's a complete step-by-step guide to set up a local SDXL endpoint with Azure Blob Storage:

### 1. Create Azure Storage Account and Container

```bash
# Install Azure CLI if needed
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Create a resource group (skip if you have one already)
az group create --name comfyui-test-group --location eastus

# Create a storage account
az storage account create \
  --name comfyuitest \
  --resource-group comfyui-test-group \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2

# Get the connection string
AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
  --name comfyuitest \
  --resource-group comfyui-test-group \
  --query connectionString \
  --output tsv)

# Create a container
az storage container create \
  --name comfyui-images \
  --connection-string "$AZURE_STORAGE_CONNECTION_STRING"

echo "Azure Storage Connection String: $AZURE_STORAGE_CONNECTION_STRING"
echo "Azure Storage Container Name: comfyui-images"
```

### 2. Create a Custom Docker Compose File

Create a file named `docker-compose-azure.yml` with the following content:

```bash
cat > docker-compose-azure.yml << 'EOF'
services:
  comfyui-worker:
    image: timpietruskyblibla/runpod-worker-comfy:3.6.0-sdxl
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
      - AZURE_STORAGE_CONTAINER_NAME=comfyui-images
      - COMFY_POLLING_INTERVAL_MS=250
      - COMFY_POLLING_MAX_RETRIES=500
    ports:
      - "8000:8000"
      - "8188:8188"
    volumes:
      - ./data/comfyui/output:/comfyui/output
      - ./data/runpod-volume:/runpod-volume
EOF
```

### 3. Create Required Directories

```bash
mkdir -p data/comfyui/output
mkdir -p data/runpod-volume
```

### 4. Start the Container with Azure Configuration

```bash
# Start with Azure environment variables
export AZURE_STORAGE_CONNECTION_STRING="$AZURE_STORAGE_CONNECTION_STRING"
docker-compose -f docker-compose-azure.yml up
```

### 5. Verify the Setup

In a new terminal window:

```bash
# Check if container is running
docker ps

# Test the API health endpoint
curl http://localhost:8000/health

# Run a test with SDXL workflow
curl -X POST -H "Content-Type: application/json" -d @test_input.json http://localhost:8000/run
```

### 6. Testing with a Custom SDXL Workflow

Create a test workflow using the SDXL model:

```bash
cat > sdxl_test_workflow.json << 'EOF'
{
  "input": {
    "workflow": {
      "3": {
        "inputs": {
          "seed": 1337,
          "steps": 20,
          "cfg": 8,
          "sampler_name": "euler",
          "scheduler": "normal",
          "denoise": 1,
          "model": ["4", 0],
          "positive": ["6", 0],
          "negative": ["7", 0],
          "latent_image": ["5", 0]
        },
        "class_type": "KSampler"
      },
      "4": {
        "inputs": {
          "ckpt_name": "sd_xl_base_1.0.safetensors"
        },
        "class_type": "CheckpointLoaderSimple"
      },
      "5": {
        "inputs": {
          "width": 1024,
          "height": 1024,
          "batch_size": 1
        },
        "class_type": "EmptyLatentImage"
      },
      "6": {
        "inputs": {
          "text": "beautiful mountain landscape with a lake, photorealistic, 8k, detailed",
          "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode"
      },
      "7": {
        "inputs": {
          "text": "text, watermark, blurry, low quality",
          "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode"
      },
      "8": {
        "inputs": {
          "samples": ["3", 0],
          "vae": ["4", 2]
        },
        "class_type": "VAEDecode"
      },
      "9": {
        "inputs": {
          "filename_prefix": "ComfyUI",
          "images": ["8", 0]
        },
        "class_type": "SaveImage"
      }
    }
  }
}
EOF

# Test with the SDXL workflow
curl -X POST -H "Content-Type: application/json" -d @sdxl_test_workflow.json http://localhost:8000/run
```

### 7. Check the Generated Image in Azure Blob Storage

```bash
# List the blobs in the container
az storage blob list \
  --container-name comfyui-images \
  --connection-string "$AZURE_STORAGE_CONNECTION_STRING" \
  --output table

# Generate a URL to access the latest image
LATEST_BLOB=$(az storage blob list \
  --container-name comfyui-images \
  --connection-string "$AZURE_STORAGE_CONNECTION_STRING" \
  --query "[0].name" \
  --output tsv)

az storage blob url \
  --container-name comfyui-images \
  --name "$LATEST_BLOB" \
  --connection-string "$AZURE_STORAGE_CONNECTION_STRING" \
  --output tsv
```

### 8. Shut Down the Container

When you're done testing:

```bash
# Stop the Docker Compose services
docker-compose -f docker-compose-azure.yml down

# Clean up images if needed
docker system prune -f
```

### 9. Optional: Clean Up Azure Resources

```bash
# Delete the Azure storage account when you're done with testing
az storage account delete \
  --name comfyuitest \
  --resource-group comfyui-test-group \
  --yes

# Delete the resource group if you created one just for this test
az group delete \
  --name comfyui-test-group \
  --yes
```

## Testing with Sample Workflows

The repository includes sample workflows in the `test_resources/workflows/` directory that you can use for testing.

You can make API requests to your local worker using the sample `test_input.json` file:

```bash
curl -X POST -H "Content-Type: application/json" -d @test_input.json http://localhost:8000/run
```

## Windows-Specific Setup

For Windows users, WSL2 with Ubuntu is recommended. Follow the detailed setup instructions in the [README.md](../README.md#setup-for-windows) document.

## Troubleshooting

- **GPU Not Detected**: Ensure the NVIDIA Container Toolkit is properly installed and configured
- **Container Exits Immediately**: Check Docker logs for error messages
- **API Not Reachable**: Verify that ports 8000 and 8188 are not in use by other applications
- **Azure Blob Storage Issues**: Check the connection string and container existence

## Environment Variables

You can customize the worker behavior using environment variables in `docker-compose.yml`:

| Environment Variable              | Description                                        | Example Value                                                                                     |
| --------------------------------- | -------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `COMFY_POLLING_INTERVAL_MS`       | Time between poll attempts in milliseconds         | `250`                                                                                             |
| `COMFY_POLLING_MAX_RETRIES`       | Maximum number of poll attempts                    | `500`                                                                                             |
| `SERVE_API_LOCALLY`               | Enable local API server for development and testing| `true`                                                                                            |
| `IMAGE_RETURN_METHOD`             | How to return generated images (azure, s3, base64) | `azure`                                                                                           |
| `AZURE_STORAGE_CONNECTION_STRING` | Azure Storage Account connection string            | `DefaultEndpointsProtocol=https;AccountName=...;AccountKey=...;EndpointSuffix=core.windows.net`   |
| `AZURE_STORAGE_CONTAINER_NAME`    | Azure Storage container name                       | `comfyui-images`                                                                                  |