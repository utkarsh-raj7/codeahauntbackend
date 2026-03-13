#!/bin/bash
echo "Waiting for Docker daemon..."
until docker info &>/dev/null; do sleep 1; done
echo "Docker is ready!"
echo "Try: docker run hello-world"
docker pull alpine:latest &>/dev/null &
