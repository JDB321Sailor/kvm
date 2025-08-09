#!/bin/bash

# Build script for JETKVM Cloud API Docker image

set -e

IMAGE_NAME="jetkvm-cloud-api"
IMAGE_TAG="${1:-latest}"

echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"

# Build the Docker image
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo "Build completed successfully!"
echo ""
echo "To run the container:"
echo "  docker run -d --name jetkvm-api -p 3000:3000 --env-file .env ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "To run with docker-compose:"
echo "  docker-compose up -d"
