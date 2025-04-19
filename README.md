# runpod-worker-comfy

> [ComfyUI](https://github.com/comfyanonymous/ComfyUI) as a serverless API on [RunPod](https://www.runpod.io/)

<p align="center">
  <img src="assets/worker_sitting_in_comfy_chair.png" title="Worker sitting in comfy chair" />
</p>

[![Discord](https://img.shields.io/discord/1275179185790386331?color=7289da&label=Discord&logo=discord&logoColor=fff&style=for-the-badge)](https://discord.com/invite/BBDPRQzGSM)

[Support the maintenance of this image by registering to RunPod with this referral link](https://runpod.io?ref=hoognf1a)

---

<!-- toc -->

- [Quickstart](#quickstart)
- [Features](#features)
- [Configuration](#configuration)
  * [AWS S3 Storage](#aws-s3-storage)
  * [Azure Blob Storage](#azure-blob-storage)
- [RunPod Setup](#runpod-setup)
  * [Create a template (optional)](#create-a-template-optional)
  * [Create your endpoint](#create-your-endpoint)
- [API Reference](#api-reference)
- [Using the API](#using-the-api)
  * [Setup](#setup)
  * [Basic Commands](#basic-commands)
  * [Example Responses](#example-responses)
- [Exporting ComfyUI Workflows](#exporting-comfyui-workflows)
- [Custom Models and Nodes](#custom-models-and-nodes)
  * [Using Network Volumes](#using-network-volumes)
  * [Custom Docker Images](#custom-docker-images)
    + [Adding Models](#adding-models)
    + [Adding Custom Nodes](#adding-custom-nodes)
- [Local Testing](#local-testing)
  * [Python Testing Setup](#python-testing-setup)
  * [Docker Testing](#docker-testing)
  * [Windows-specific Setup](#windows-specific-setup)
- [Automatic Docker Hub Deployment](#automatic-docker-hub-deployment)
  * [Required GitHub Repository Configuration](#required-github-repository-configuration)
- [Acknowledgments](#acknowledgments)

<!-- tocstop -->

---

## Quickstart

- 🐳 Deploy with this image: `kimaraai/runpod-worker-comfy:1.2.1-base`
- 🔧 [Set up your RunPod endpoint](#use-the-docker-image-on-runpod)
- 🧪 Run an [example workflow](./test_resources/workflows/)

## Features

- Run [ComfyUI](https://github.com/comfyanonymous/ComfyUI) workflows as an API
- Process input images via base64-encoding
- Get results as:
  - Base64-encoded string (default)
  - AWS S3 upload ([with configuration](#upload-image-to-aws-s3))
  - Azure Blob Storage ([with configuration](#upload-image-to-azure-blob-storage))
- Available images:
  - `kimaraai/runpod-worker-comfy:1.2.1-base`: Clean ComfyUI without models
- Build custom images with models:
  - SDXL: Use `--build-arg MODEL_TYPE=sdxl` 
    - Includes: [sd_xl_base_1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0), [sdxl_vae](https://huggingface.co/stabilityai/sdxl-vae/) and [sdxl-vae-fp16-fix](https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/)
- [Add your own models](#bring-your-own-models)
- Based on [Ubuntu + NVIDIA CUDA](https://hub.docker.com/r/nvidia/cuda)

## Configuration

| Environment Variable        | Description                                                                                    | Default  |
| --------------------------- | ---------------------------------------------------------------------------------------------- | -------- |
| `REFRESH_WORKER`            | Stop worker after each job for clean state ([docs](https://docs.runpod.io/docs/handler-additional-controls#refresh-worker)) | `false`  |
| `COMFY_POLLING_INTERVAL_MS` | Time (ms) between poll attempts                                                                | `250`    |
| `COMFY_POLLING_MAX_RETRIES` | Maximum poll attempts (increase for longer workflows)                                          | `500`    |
| `SERVE_API_LOCALLY`         | Enable local API server for development ([details](#local-testing))                            | disabled |
| `IMAGE_RETURN_METHOD`       | Return method: `azure`, `s3`, or `base64` (falls back if method unavailable)                   | `base64` |

### AWS S3 Storage

To store generated images in S3:

1. Create an S3 bucket
2. Set up IAM user with S3 access
3. Configure environment variables:

| Environment Variable       | Description                     | Example                                      |
| -------------------------- | ------------------------------- | -------------------------------------------- |
| `BUCKET_ENDPOINT_URL`      | S3 bucket endpoint URL          | `https://<bucket>.s3.<region>.amazonaws.com` |
| `BUCKET_ACCESS_KEY_ID`     | AWS access key ID               | `AKIAIOSFODNN7EXAMPLE`                       |
| `BUCKET_SECRET_ACCESS_KEY` | AWS secret access key           | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`   |

### Azure Blob Storage

To store generated images in Azure:

1. Create an Azure Storage Account
2. Configure environment variables:

| Environment Variable               | Description                          | Example                                                  |
| ---------------------------------- | ------------------------------------ | -------------------------------------------------------- |
| `AZURE_STORAGE_CONNECTION_STRING`  | Azure Storage connection string      | `DefaultEndpointsProtocol=https;AccountName=myaccount;...` |
| `AZURE_STORAGE_CONTAINER_NAME`     | Container name (default: `comfyui-images`) | `comfyui-images`                              |
| `IMAGE_RETURN_METHOD`              | Set to `azure` for Azure priority    | `azure`                                                  |

Example response:
```json
{
  "output": {
    "message": "https://mystorageaccount.blob.core.windows.net/comfyui-images/job-id/ComfyUI_00001_.png",
    "status": "success"
  },
  "status": "COMPLETED"
}
```

## RunPod Setup

### Create a template (optional)

- Go to [RunPod Templates](https://runpod.io/console/serverless/user/templates) and click `New Template`
- Configure:
  - Name: `runpod-worker-comfy` (or any name)
  - Type: serverless
  - Image: `kimaraai/runpod-worker-comfy:1.2.1-base`
  - Disk: `20 GB`
  - Optional: Set [S3](#aws-s3-storage) or [Azure](#azure-blob-storage) environment variables
- Click `Save Template`

### Create your endpoint

- Navigate to [`Serverless > Endpoints`](https://www.runpod.io/console/serverless/user/endpoints) and click on `New Endpoint`
- Configure:
  - Endpoint Name: `comfy` (or any name)
  - Select appropriate GPU for your models
  - Set worker count based on your needs
  - Enable Flash Boot for faster startup
  - Select your template
  - Optional: Attach Network Volume for custom models
- Click `deploy`

## API Reference

API request structure ([full documentation](https://docs.runpod.io/docs/serverless-usage)):

```json
{
  "input": {
    "workflow": {},     // Required: ComfyUI workflow configuration
    "images": [         // Optional: Input images for the workflow
      {
        "name": "example.png",  // Name used to reference in workflow
        "image": "base64_string"  // Base64-encoded image
      }
    ]
  }
}
```

**Important Notes:**
- Request size limits: 10 MB for `/run`, 20 MB for `/runsync` ([details](https://docs.runpod.io/docs/serverless-endpoint-urls))
- Each input image must have a unique name
- Use the same image name in your workflow to reference it

## Using the API

### Setup

1. Generate an API key in [RunPod User Settings](https://www.runpod.io/console/serverless/user/settings)
2. Find your endpoint ID in the [Endpoints dashboard](https://www.runpod.io/console/serverless)

![EndpointID location](./assets/my-endpoint-with-endpointID.png)

### Basic Commands

Check endpoint status:
```bash
curl -H "Authorization: Bearer <api_key>" https://api.runpod.ai/v2/<endpoint_id>/health
```

Generate an image (synchronous):
```bash
curl -X POST \
  -H "Authorization: Bearer <api_key>" \
  -H "Content-Type: application/json" \
  -d @test_input.json \
  https://api.runpod.ai/v2/<endpoint_id>/runsync
```

For asynchronous requests, use `/run` instead of `/runsync`.

### Example Responses

Base64 response:
```json
{
  "id": "sync-c0cd1eb2-068f-4ecf-a99a-55770fc77391-e1",
  "output": { "message": "base64encodedimage", "status": "success" },
  "status": "COMPLETED"
}
```

S3 response:
```json
{
  "id": "sync-c0cd1eb2-068f-4ecf-a99a-55770fc77391-e1",
  "output": {
    "message": "https://bucket.s3.region.amazonaws.com/10-23/sync-c0cd1eb2-068f-4ecf-a99a-55770fc77391-e1/image.png",
    "status": "success"
  },
  "status": "COMPLETED"
}
```

## Exporting ComfyUI Workflows

1. Open ComfyUI in browser
2. Click `Settings` (gear icon)
3. Enable `Dev mode Options`
4. Close Settings
5. Click `Save (API Format)` in the menu
6. Use the downloaded `workflow_api.json` content in your API requests

## Custom Models and Nodes

### Using Network Volumes

1. **Create a Network Volume**
   - Follow the [RunPod guide](https://docs.runpod.io/pods/storage/create-network-volumes)

2. **Add your models**
   - Deploy a temporary pod with the volume
   - Create model directories and download models:
     ```bash
     cd /workspace
     mkdir -p models/{checkpoints,clip,vae,loras}
     wget -O models/checkpoints/sdxl_model.safetensors <model_url>
     ```
   - Terminate the temporary pod

3. **Attach to your endpoint**
   - In endpoint settings, select your volume under Advanced options

### Custom Docker Images

#### Adding Models

Edit the Dockerfile to add model downloads:

```Dockerfile
RUN wget -O models/checkpoints/sd_xl_base_1.0.safetensors \
  https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
```

#### Adding Custom Nodes

1. Export a [ComfyUI Manager snapshot](https://github.com/ltdrdata/ComfyUI-Manager#snapshot-manager):
   - Open "Manager > Snapshot Manager"
   - Save a snapshot 
   - Get the snapshot file from `ComfyUI/custom_nodes/ComfyUI-Manager/snapshots`
   - Place in project root directory

2. Build your image:
   ```bash
   # Base image
   docker build -t your-username/runpod-worker-comfy:dev-base \
     --target base --platform linux/amd64 .

   # SDXL image (for local testing)
   docker build --build-arg MODEL_TYPE=sdxl \
     -t your-username/runpod-worker-comfy:dev-sdxl \
     --platform linux/amd64 .
   ```

   > **Note**: Always use `--platform linux/amd64` for RunPod compatibility

## Local Testing

### Python Testing Setup

```bash
# Python 3.10+ required
python -m venv venv
source ./venv/bin/activate  # On Windows: .\venv\Scripts\activate
pip install -r requirements.txt

# Run tests
python -m unittest discover
```

### Docker Testing

The easiest way to test locally:

```bash
# Start local server with Docker
docker-compose up
```

This will:
- Start an API server at http://localhost:8000
- Start ComfyUI at http://localhost:8188
- Use test_input.json for sample data

> **Requirements:** NVIDIA GPU with CUDA support

### Windows-specific Setup

For Windows users:
1. Install [WSL2 with Ubuntu](https://ubuntu.com/tutorials/install-ubuntu-on-wsl2-on-windows-11-with-gui-support#1-overview)
2. Install [Docker and NVIDIA container toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
3. Enable [GPU acceleration in WSL2](https://canonical-ubuntu-wsl.readthedocs-hosted.com/en/latest/tutorials/gpu-cuda/)

For better compatibility, use Docker Desktop on Windows instead of Docker in WSL2.

## Automatic Docker Hub Deployment

This repo includes GitHub Actions workflows for Docker Hub publishing:

- **Development builds:** [dev.yml](.github/workflows/dev.yml) - Creates `dev` tagged images on pushes to non-main branches
- **Release builds:** [release.yml](.github/workflows/release.yml) - Creates versioned images when a GitHub release is published

> **Note:** Only the base image is published due to GitHub Actions disk space limits.

### Required GitHub Repository Configuration

**Secrets:**
- `DOCKERHUB_USERNAME` - Your Docker Hub username
- `DOCKERHUB_TOKEN` - Your Docker Hub access token
- `HUGGINGFACE_ACCESS_TOKEN` - Hugging Face READ token

**Variables:**
- `DOCKERHUB_REPO` - Docker Hub repository (e.g., `kimaraai`)
- `DOCKERHUB_IMG` - Image name (e.g., `runpod-worker-comfy`)

## Acknowledgments

- Original fork from [blib-la/runpod-worker-comfy](https://github.com/blib-la/runpod-worker-comfy)
- [Justin Merrell](https://github.com/justinmerrell) - [worker-1111](https://github.com/runpod-workers/worker-a1111)
- [Ashley Kleynhans](https://github.com/ashleykleynhans) - [runpod-worker-a1111](https://github.com/ashleykleynhans/runpod-worker-a1111)
- [comfyanonymous](https://github.com/comfyanonymous) - [ComfyUI](https://github.com/comfyanonymous/ComfyUI)