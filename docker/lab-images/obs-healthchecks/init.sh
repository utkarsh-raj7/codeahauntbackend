#!/bin/bash
python3 ~/app.py &
sleep 1
echo "App running on port 8080"
echo "Tasks:"
echo "1. curl http://localhost:8080/health"
echo "2. curl http://localhost:8080/ready"
echo "3. Write a bash script that polls /health every 5s"
