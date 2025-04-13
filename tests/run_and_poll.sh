#!/bin/bash

# Script to submit a job and poll its status
# Usage: ./run_and_poll.sh [API_BASE_URL]
# Default API_BASE_URL is http://localhost:8000

API_BASE_URL=${1:-http://localhost:8000}
RUN_URL="$API_BASE_URL/run"

echo "Submitting job to: $RUN_URL"

# Submit the job and capture the response
RESPONSE=$(curl -s -X POST \
  "$RUN_URL" \
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

echo "Submit response: $RESPONSE"

# Extract job ID
JOB_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$JOB_ID" ]; then
  echo "Error: Could not extract job ID from response"
  exit 1
fi

echo "Job ID: $JOB_ID"
echo ""
echo "Starting to poll job status..."
echo "Press Ctrl+C to stop polling"

# Poll status
STATUS_URL="$API_BASE_URL/status"

while true; do
  # Use POST request for status endpoint
  STATUS_RESPONSE=$(curl -s -X POST \
    "$STATUS_URL" \
    -H "Content-Type: application/json" \
    -d "{\"id\":\"$JOB_ID\"}")
  
  echo "$(date +"%H:%M:%S") - Raw response: '$STATUS_RESPONSE'"
  
  # Check if response is empty
  if [ -z "$STATUS_RESPONSE" ]; then
    echo "Warning: Empty response from server, retrying..."
    sleep 2
    continue
  fi
  
  # Extract status
  STATUS=$(echo "$STATUS_RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
  
  echo "$(date +"%H:%M:%S") - Status: $STATUS"
  
  # Check if job completed or failed
  if [[ "$STATUS" == "COMPLETED" ]]; then
    echo "Job completed!"
    echo "Full response:"
    echo "$STATUS_RESPONSE" | jq . 2>/dev/null || echo "$STATUS_RESPONSE"
    break
  elif [[ "$STATUS" == "FAILED" ]]; then
    echo "Job failed!"
    echo "Full response:"
    echo "$STATUS_RESPONSE" | jq . 2>/dev/null || echo "$STATUS_RESPONSE"
    break
  fi
  
  # Try checking the ComfyUI history directly if status is empty
  if [ -z "$STATUS" ]; then
    echo "Checking ComfyUI history directly..."
    COMFY_RESPONSE=$(curl -s "http://localhost:8188/history")
    
    # Extract image filename if available
    IMAGE_PATH=$(echo "$COMFY_RESPONSE" | grep -o '"filename":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ ! -z "$IMAGE_PATH" ]; then
      echo "Image generated: $IMAGE_PATH"
      echo "Check ComfyUI interface at http://localhost:8188 to view the image"
    fi
  fi
  
  # Wait before polling again
  sleep 2
done