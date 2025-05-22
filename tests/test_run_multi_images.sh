#!/bin/bash

# Script to test the RunPod ComfyUI API with multiple image outputs
# Usage: ./test_run_multi_images.sh [JSON_FILE] [API_BASE_URL]
# Default API_BASE_URL is http://localhost:8000

JSON_FILE="$1"
API_BASE_URL=${2:-http://localhost:8000}
RUNSYNC_URL="$API_BASE_URL/runsync"

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Testing endpoint: $RUNSYNC_URL${NC}"

# Use JSON file if provided, otherwise fail
if [ -n "$JSON_FILE" ] && [ -f "$JSON_FILE" ]; then
  echo -e "${GREEN}Using JSON file: $JSON_FILE${NC}"
  
  # Send the JSON file directly to the API with proper wrapping
  FILE_CONTENT=$(cat "$JSON_FILE")
  
  # Basic validation
  echo "$FILE_CONTENT" | jq empty > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Invalid JSON file${NC}"
    exit 1
  fi
  
  echo -e "${BLUE}Sending JSON to API...${NC}"
  RESPONSE=$(curl -s -X POST "$RUNSYNC_URL" \
    -H "Content-Type: application/json" \
    -d "{\"input\":{\"workflow\":$FILE_CONTENT}}")
else
  echo -e "${RED}Error: No JSON file provided or file not found${NC}"
  echo -e "${YELLOW}Usage: $0 <json_file> [api_base_url]${NC}"
  exit 1
fi

echo -e "\nResponse:"
echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"

# Parse image outputs
IMAGES_OUTPUT=$(echo "$RESPONSE" | jq -r '.output.message' 2>/dev/null)
if [ ! -z "$IMAGES_OUTPUT" ]; then
  echo -e "\n${GREEN}======= IMAGE OUTPUT DETAILS =======${NC}"
  
  # Count images
  IMAGE_COUNT=$(echo "$RESPONSE" | grep -o '"node_id"' | wc -l)
  echo -e "${BLUE}Number of images: $IMAGE_COUNT${NC}"
  
  # Image info
  echo -e "\n${BLUE}Image Information:${NC}"
  IMAGE_INFO=$(echo "$RESPONSE" | jq -r '.output.message[] | "Node: \(.node_id), Type: \(.imageType)"' 2>/dev/null)
  echo "$IMAGE_INFO"
  
  # Azure or base64
  AZURE_URLS=$(echo "$RESPONSE" | jq -r '.output.message[] | select(.imageType=="url") | .image' 2>/dev/null)
  if [ ! -z "$AZURE_URLS" ]; then
    echo -e "\n${BLUE}Azure Blob Storage URLs:${NC}"
    echo "$AZURE_URLS"
    
    DOWNLOAD_DIR="./downloaded_images_sync"
    mkdir -p "$DOWNLOAD_DIR"
  else
    BASE64_IMAGES=$(echo "$RESPONSE" | jq -r '.output.message[] | select(.imageType=="base64") | .image' 2>/dev/null)
    if [ ! -z "$BASE64_IMAGES" ]; then
      echo -e "\n${BLUE}Base64 images found. Saving to files...${NC}"
      
      DOWNLOAD_DIR="./downloaded_images_sync"
      mkdir -p "$DOWNLOAD_DIR"
      
      NODE_IDS=$(echo "$RESPONSE" | jq -r '.output.message[] | select(.imageType=="base64") | .node_id' 2>/dev/null)
      
      IMAGE_INDEX=0
      for node_id in $NODE_IDS; do
        IMAGE_INDEX=$((IMAGE_INDEX + 1))
        OUTPUT_FILE="$DOWNLOAD_DIR/image_${node_id}_${IMAGE_INDEX}.png"
        echo "Saving image from node $node_id to $OUTPUT_FILE"
        
        BASE64_DATA=$(echo "$RESPONSE" | jq -r ".output.message[] | select(.node_id==\"$node_id\" and .imageType==\"base64\") | .image" 2>/dev/null | head -1)
        echo "$BASE64_DATA" | base64 -d > "$OUTPUT_FILE"
      done
    else
      echo -e "\n${RED}No image data found in response${NC}"
    fi
  fi
else
  echo -e "\n${RED}No image data found in response${NC}"
fi

echo -e "\n${BLUE}Testing complete.${NC}"