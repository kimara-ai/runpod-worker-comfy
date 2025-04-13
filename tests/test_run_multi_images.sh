#!/bin/bash

# Script to test the RunPod ComfyUI API with multiple image outputs to Azure Blob Storage
# This script uses the /runsync endpoint for immediate results
# Usage: ./test_run_multi_images.sh [API_BASE_URL]
# Default API_BASE_URL is http://localhost:8000

API_BASE_URL=${1:-http://localhost:8000}
RUNSYNC_URL="$API_BASE_URL/runsync"

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Testing endpoint with multiple images (Azure Blob Storage)${NC}"
echo -e "${BLUE}API Base URL: $API_BASE_URL${NC}"
echo -e "${BLUE}Using synchronous endpoint: $RUNSYNC_URL${NC}"

# Submit the workflow that generates multiple images (batch_size: 4)
echo -e "\n${GREEN}Submitting workflow to: $RUNSYNC_URL${NC}"
RESPONSE=$(curl -s -X POST \
  "$RUNSYNC_URL" \
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
          "text": "beautiful scenery nature glass bottle landscape, purple galaxy bottle",
          "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode"
      },
      "7": {
        "inputs": {
          "text": "text, watermark, blurry, distorted",
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
)

echo -e "Response:"
echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"

# Parse and display image URLs, handling multiple images
IMAGES_OUTPUT=$(echo "$RESPONSE" | jq -r '.output.message' 2>/dev/null)

if [ ! -z "$IMAGES_OUTPUT" ]; then
    echo -e "\n${GREEN}======= IMAGE OUTPUT DETAILS =======${NC}"
    
    # Count number of node_id entries to determine image count
    IMAGE_COUNT=$(echo "$RESPONSE" | grep -o '"node_id"' | wc -l)
    echo -e "${BLUE}Number of images: $IMAGE_COUNT${NC}"
    
    # Extract and display each image URL/data
    echo -e "\n${BLUE}Image Information:${NC}"
    IMAGE_INFO=$(echo "$RESPONSE" | jq -r '.output.message[] | "Node: \(.node_id), Type: \(.imageType)"' 2>/dev/null)
    echo "$IMAGE_INFO"
    
    # If using Azure Blob Storage, show URLs
    AZURE_URLS=$(echo "$RESPONSE" | jq -r '.output.message[] | select(.imageType=="url") | .image' 2>/dev/null)
    if [ ! -z "$AZURE_URLS" ]; then
        echo -e "\n${BLUE}Azure Blob Storage URLs:${NC}"
        echo "$AZURE_URLS"
        
        # Create a directory to store downloaded images
        DOWNLOAD_DIR="./downloaded_images_sync"
        echo -e "\n${YELLOW}Creating directory for downloaded images...${NC}"
        mkdir -p "$DOWNLOAD_DIR"
        
        # Download each image URL
        echo -e "\n${YELLOW}Downloading images to $DOWNLOAD_DIR...${NC}"
        URL_COUNT=0
        echo "$AZURE_URLS" | while read -r url; do
            URL_COUNT=$((URL_COUNT + 1))
            OUTPUT_FILE="$DOWNLOAD_DIR/image_${URL_COUNT}.png"
            echo "Downloading: $url"
            curl -s -o "$OUTPUT_FILE" "$url"
            echo "Saved to: $OUTPUT_FILE"
        done
    else
        # For base64 encoded images
        BASE64_IMAGES=$(echo "$RESPONSE" | jq -r '.output.message[] | select(.imageType=="base64") | .image' 2>/dev/null)
        if [ ! -z "$BASE64_IMAGES" ]; then
            echo -e "\n${BLUE}Base64 encoded images found. Saving to files...${NC}"
            
            # Create a directory to store decoded images
            DOWNLOAD_DIR="./downloaded_images_sync"
            mkdir -p "$DOWNLOAD_DIR"
            
            # Counter for saving multiple images
            NODE_IDS=$(echo "$RESPONSE" | jq -r '.output.message[] | select(.imageType=="base64") | .node_id' 2>/dev/null)
            
            # Save each base64 image
            IMAGE_INDEX=0
            for node_id in $NODE_IDS; do
                IMAGE_INDEX=$((IMAGE_INDEX + 1))
                OUTPUT_FILE="$DOWNLOAD_DIR/image_${node_id}_${IMAGE_INDEX}.png"
                echo "Saving image from node $node_id to $OUTPUT_FILE"
                
                # Extract this specific image's base64 data
                BASE64_DATA=$(echo "$RESPONSE" | jq -r ".output.message[] | select(.node_id==\"$node_id\" and .imageType==\"base64\") | .image" 2>/dev/null | head -1)
                
                # Save the base64 data to a file
                echo "$BASE64_DATA" | base64 -d > "$OUTPUT_FILE"
                echo "Saved to: $OUTPUT_FILE"
            done
        else
            echo -e "\n${RED}No image data (URL or base64) found in response${NC}"
        fi
    fi
else
    echo -e "\n${RED}No image data found in response${NC}"
fi

echo -e "\n${BLUE}Testing complete.${NC}"