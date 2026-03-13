#!/bin/bash
git config --global user.email "labuser@lab.local"
git config --global user.name "Lab User"
git config --global init.defaultBranch main
mkdir -p ~/git-lab && cd ~/git-lab
git init && git commit --allow-empty -m "Initial commit"
git checkout -b feature/add-login
echo "function login() { return true; }" > auth.js
git add . && git commit -m "Add login function"
git checkout main
echo "Tasks: merge feature branch, resolve conflict, tag a release"
