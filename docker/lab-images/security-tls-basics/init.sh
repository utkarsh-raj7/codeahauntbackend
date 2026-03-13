#!/bin/bash
mkdir -p ~/tls-lab
echo "Tasks:"
echo "1. Generate a self-signed cert:"
echo "   openssl req -x509 -newkey rsa:2048 -keyout ~/tls-lab/key.pem -out ~/tls-lab/cert.pem -days 365 -nodes"
echo "2. Inspect it: openssl x509 -in ~/tls-lab/cert.pem -text -noout"
echo "3. Check a real cert: openssl s_client -connect google.com:443 </dev/null"
