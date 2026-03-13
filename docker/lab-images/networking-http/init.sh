#!/bin/bash
python3 -m http.server 8080 --directory /home/labuser &>/dev/null &
echo "Local HTTP server running on port 8080"
echo "Try: curl http://localhost:8080"
