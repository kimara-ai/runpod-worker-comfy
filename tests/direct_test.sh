#!/bin/bash

# Script to directly call the API endpoints to see what's available
# Usage: ./direct_test.sh [API_BASE_URL]
# Default API_BASE_URL is http://localhost:8000

API_BASE_URL=${1:-http://localhost:8000}

echo "Testing RunPod Serverless API at $API_BASE_URL"
echo "--------------------------------------------"

echo "1. Testing base endpoint with GET"
curl -v "$API_BASE_URL/"

echo -e "\n\n2. Testing healthcheck endpoint with GET"
curl -v "$API_BASE_URL/health"

echo -e "\n\n3. Testing runsync endpoint with POST"
curl -v -X POST \
  "$API_BASE_URL/runsync" \
  -H "Content-Type: application/json" \
  -d '{
  "input": {
    "workflow": {
      "3": {
        "inputs": {
          "seed": 42,
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
          "width": 512,
          "height": 512,
          "batch_size": 4
        },
        "class_type": "EmptyLatentImage"
      },
      "6": {
        "inputs": {
          "text": "beautiful scenery nature",
          "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode"
      },
      "7": {
        "inputs": {
          "text": "text, watermark",
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
}'

echo -e "\n\nNow checking ComfyUI API directly"
echo "--------------------------------------------"

echo -e "\n1. Checking ComfyUI history API"
curl -s "http://localhost:8188/history" | head -20

echo -e "\n\n2. Checking ComfyUI system stats"
curl -s "http://localhost:8188/system_stats" | head -20

echo -e "\n\nTesting complete."