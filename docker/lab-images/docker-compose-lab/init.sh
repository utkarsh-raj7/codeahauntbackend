#!/bin/bash
until docker info &>/dev/null; do sleep 1; done
echo "Exercise: complete the docker-compose.yml in ~/compose-exercise/"
echo "It should start a web app + redis + postgres"
