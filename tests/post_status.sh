#!/bin/bash

# Script to send a POST request to the status endpoint
# Usage: ./post_status.sh JOB_ID [API_BASE_URL]
# Default API_BASE_URL is http://localhost:8000

if [ -z "$1" ]; then
  echo "Error: Job ID is required"
  echo "Usage: $0 JOB_ID [API_BASE_URL]"
  exit 1
fi

JOB_ID=$1
API_BASE_URL=${2:-http://localhost:8000}
STATUS_URL="$API_BASE_URL/status"

echo "Sending POST request to: $STATUS_URL"

# Send a POST request with the job ID
curl -X POST \
  "$STATUS_URL" \
  -H "Content-Type: application/json" \
  -d "{\"id\":\"$JOB_ID\"}"