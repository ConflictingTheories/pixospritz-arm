#!/bin/bash
# Rebuild Docker image (needed after changing Dockerfile)
echo "Rebuilding Docker image with current UID/GID..."
docker-compose build --no-cache
echo "✓ Image rebuilt!"
