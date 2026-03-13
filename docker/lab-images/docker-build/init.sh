#!/bin/bash
until docker info &>/dev/null; do sleep 1; done
echo "Your task: write a Dockerfile for the sample Python app in ~/sample-app/"
echo "Then build it with: docker build -t my-app ."
