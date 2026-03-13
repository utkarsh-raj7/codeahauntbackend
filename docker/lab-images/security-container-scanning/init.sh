#!/bin/bash
until docker info &>/dev/null; do sleep 1; done
echo "Trivy container scanner ready"
echo "Tasks:"
echo "1. Scan an image: trivy image alpine:latest"
echo "2. Scan for critical only: trivy image --severity CRITICAL nginx:1.20"
echo "3. Scan a Dockerfile: trivy config ."
