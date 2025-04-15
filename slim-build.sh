#!/bin/bash
set -e

# Default to base type if no parameter provided
BUILD_TYPE=${1:-base}

# Determine the image name
VERSION=${RELEASE_VERSION:-latest}
IMAGE_REPO=${DOCKERHUB_REPO:-kimaraai}
IMAGE_NAME=${DOCKERHUB_IMG:-runpod-worker-comfy}

# Configure build based on type
case $BUILD_TYPE in
  "sdxl")
    BASE_IMAGE="${IMAGE_REPO}/${IMAGE_NAME}:${VERSION}-sdxl"
    SLIM_IMAGE="${IMAGE_REPO}/${IMAGE_NAME}:${VERSION}-sdxl-slim"
    TARGET="sdxl"
    MODEL_ARG="--set *.args.MODEL_TYPE=sdxl"
    ;;
  "base" | *)
    BASE_IMAGE="${IMAGE_REPO}/${IMAGE_NAME}:${VERSION}-base"
    SLIM_IMAGE="${IMAGE_REPO}/${IMAGE_NAME}:${VERSION}-slim"
    TARGET="base"
    MODEL_ARG=""
    ;;
esac

# Print current disk space
df -h

echo "Building ${BUILD_TYPE} image first..."
docker buildx bake ${TARGET} ${MODEL_ARG}

echo "Running slim build to create optimized ${BUILD_TYPE} image..."
slim --report=off build --target ${BASE_IMAGE} \
  --tag ${SLIM_IMAGE} \
  --http-probe=false \
  --continue-after=10 \
  --expose=8188 \
  --cmd="/start.sh" \
  --include-path=/comfyui \
  --include-path=/opt/venv \
  --include-path=/usr/lib/python3.11 \
  --include-path=/usr/lib/python3 \
  --include-path=/usr/local/lib/python3.11 \
  --include-path=/start.sh \
  --include-path=/restore_snapshot.sh \
  --include-path=/rp_handler.py \
  --include-path=/test_input.json \
  --include-path=/extra_model_paths.yaml \
  --include-path=/models \
  --include-shell \
  --include-zoneinfo \
  --remove-file-artifacts \
  --show-blogs \
  --show-clogs

echo "Slim build complete! Optimized ${BUILD_TYPE} image created: ${SLIM_IMAGE}"
df -h

# Usage instructions printed if no args
if [ $# -eq 0 ]; then
  echo -e "\nUsage:"
  echo "  $0 [base|sdxl]"
  echo "  - base: Build the base slim image (default)"
  echo "  - sdxl: Build the SDXL slim image"
fi