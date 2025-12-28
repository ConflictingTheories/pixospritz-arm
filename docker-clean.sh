#!/bin/bash
# Clean build artifacts
echo "Cleaning build artifacts..."
docker-compose run --rm buildroot /home/builder/work/docker-build.sh clean
echo "Clean complete!"
