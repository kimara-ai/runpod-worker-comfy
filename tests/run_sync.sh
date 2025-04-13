#!/bin/bash

# Script to run a ComfyUI workflow synchronously
# Usage: ./run_sync.sh [API_BASE_URL]
# Default API_BASE_URL is http://localhost:8000

API_BASE_URL=${1:-http://localhost:8000}
RUNSYNC_URL="$API_BASE_URL/runsync"

echo "Submitting synchronous job to: $RUNSYNC_URL"

# Submit the job and capture the response
RESPONSE=$(curl -s -X POST \
  "$RUNSYNC_URL" \
  -H "Content-Type: application/json" \
  -d '{
  "input": {
    "workflow": {
      "3": {
        "inputs": {
          "seed": 322395417973386,
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
        "class_type": "KSampler",
        "_meta": {
          "title": "KSampler"
        }
      },
      "4": {
        "inputs": {
          "ckpt_name": "sd_xl_base_1.0.safetensors"
        },
        "class_type": "CheckpointLoaderSimple",
        "_meta": {
          "title": "Load Checkpoint"
        }
      },
      "5": {
        "inputs": {
          "width": 512,
          "height": 512,
          "batch_size": 1
        },
        "class_type": "EmptyLatentImage",
        "_meta": {
          "title": "Empty Latent Image"
        }
      },
      "6": {
        "inputs": {
          "text": "beautiful scenery nature glass bottle landscape, , purple galaxy bottle,",
          "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode",
        "_meta": {
          "title": "CLIP Text Encode (Prompt)"
        }
      },
      "7": {
        "inputs": {
          "text": "text, watermark",
          "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode",
        "_meta": {
          "title": "CLIP Text Encode (Prompt)"
        }
      },
      "8": {
        "inputs": {
          "samples": ["3", 0],
          "vae": ["4", 2]
        },
        "class_type": "VAEDecode",
        "_meta": {
          "title": "VAE Decode"
        }
      },
      "9": {
        "inputs": {
          "filename_prefix": "ComfyUI",
          "images": ["8", 0]
        },
        "class_type": "SaveImage",
        "_meta": {
          "title": "Save Image"
        }
      }
    }
  }
}')

echo "Response:"
echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"

# Extract image URL if available
IMAGE_URL=$(echo "$RESPONSE" | grep -o '"image":"[^"]*"' | cut -d'"' -f4)
if [ ! -z "$IMAGE_URL" ]; then
  echo -e "\nGenerated image URL: $IMAGE_URL"
fi