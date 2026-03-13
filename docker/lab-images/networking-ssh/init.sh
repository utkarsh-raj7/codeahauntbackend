#!/bin/bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t rsa -b 2048 -f ~/.ssh/lab_key -N "" -q
echo "SSH key generated at ~/.ssh/lab_key"
echo "Practice: ssh-copy-id, authorized_keys, config file"
