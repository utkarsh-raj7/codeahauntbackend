#!/bin/bash
until docker info &>/dev/null; do sleep 1; done
echo "Task: Write a Dockerfile for ~/app/app.py"
echo "Then: docker build -t my-pipeline-app . && docker run my-pipeline-app"
