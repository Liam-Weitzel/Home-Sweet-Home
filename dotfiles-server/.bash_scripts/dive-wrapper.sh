#!/usr/bin/env bash
docker images
echo "Enter Docker image name/tag to analyze:"
read -r image
if [ -z "$image" ]; then
    echo "No image specified!"
    read -p "Press Enter to exit..."
    exit 1
fi
echo "Analyzing Docker image: $image"
dive "$image"
