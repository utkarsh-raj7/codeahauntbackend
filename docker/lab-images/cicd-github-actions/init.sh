#!/bin/bash
git config --global user.email "lab@lab.local" && git config --global user.name "Lab User"
cd ~/my-project && git init && git add . && git commit -m "Initial project"
echo "Task: complete .github/workflows/ci.yml"
echo "Reference: https://docs.github.com/en/actions"
