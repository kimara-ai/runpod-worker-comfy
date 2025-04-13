#!/bin/bash

# Script to poll a job status
# Usage: ./poll_job.sh JOB_ID [API_BASE_URL]
# Default API_BASE_URL is http://localhost:8000

if [ -z "$1" ]; then
  echo "Error: Job ID is required"
  echo "Usage: $0 JOB_ID [API_BASE_URL]"
  exit 1
fi

JOB_ID=$1
API_BASE_URL=${2:-http://localhost:8000}
STATUS_URL="$API_BASE_URL/status/$JOB_ID"

echo "Polling status from: $STATUS_URL"
echo "Press Ctrl+C to stop polling"

while true; do
  RESPONSE=$(curl -s "$STATUS_URL")
  
  # Extract status
  STATUS=$(echo "$RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
  
  echo "$(date +"%H:%M:%S") - Status: $STATUS"
  
  # Check if job completed or failed
  if [[ "$STATUS" == "COMPLETED" ]]; then
    echo "Job completed!"
    echo "Full response:"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    break
  elif [[ "$STATUS" == "FAILED" ]]; then
    echo "Job failed!"
    echo "Full response:"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    break
  fi
  
  # Wait before polling again
  sleep 2
done