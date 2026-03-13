#!/bin/bash
mkdir -p ~/workspace/project/{src,docs,tests}
echo "Hello from Code-A-Haunt!" > ~/workspace/project/src/main.txt
echo "# Project Docs" > ~/workspace/project/docs/readme.md
echo "test1\ntest2\ntest3" > ~/workspace/project/tests/results.txt
for i in {1..5}; do echo "log line $i: INFO app started" >> ~/workspace/app.log; done
echo "done"
