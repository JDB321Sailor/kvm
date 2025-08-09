#!/bin/bash

# Build script for JETKVM UI Docker image

set -e

IMAGE_NAME="jetkvm-ui"
IMAGE_TAG="${1:-latest}"

echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"

# Build the Docker image
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo "Build completed successfully!"
echo ""
echo "To run the container:"
echo "  docker run -d --name jetkvm-ui -p 80:80 ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "To run on a different port (e.g., 8080):"
echo "  docker run -d --name jetkvm-ui -p 8080:80 ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Access the application at: http://localhost (or http://localhost:8080)"
