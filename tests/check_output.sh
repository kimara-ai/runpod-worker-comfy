#!/bin/bash

# Script to check output directly
# Usage: ./check_output.sh JOB_ID [API_BASE_URL]
# Default API_BASE_URL is http://localhost:8000

if [ -z "$1" ]; then
  echo "Error: Job ID is required"
  echo "Usage: $0 JOB_ID [API_BASE_URL]"
  exit 1
fi

JOB_ID=$1
API_BASE_URL=${2:-http://localhost:8000}
OUTPUT_URL="$API_BASE_URL/output/$JOB_ID"

echo "Checking output from: $OUTPUT_URL"

# Try to get output
OUTPUT_RESPONSE=$(curl -s "$OUTPUT_URL")
echo "Output endpoint response: '$OUTPUT_RESPONSE'"

# Alternate approach: Try the status endpoint but with verbose output
STATUS_URL="$API_BASE_URL/status/$JOB_ID"
echo "Trying status endpoint with verbose output: $STATUS_URL"
curl -v "$STATUS_URL"

# Try hitting the ComfyUI interface directly to see what's available
COMFY_URL="http://localhost:8188/history"
echo -e "\nQuerying ComfyUI history directly: $COMFY_URL"
curl -s "$COMFY_URL" | jq . 2>/dev/null || echo "Raw response: $(curl -s "$COMFY_URL")"