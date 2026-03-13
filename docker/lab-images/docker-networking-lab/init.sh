#!/bin/bash
until docker info &>/dev/null; do sleep 1; done
echo "Tasks:"
echo "1. Create a custom bridge network called 'lab-net'"
echo "2. Run two alpine containers attached to lab-net"
echo "3. Ping between them by container name"
echo "4. Inspect network with: docker network inspect lab-net"
