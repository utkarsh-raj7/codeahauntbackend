#!/bin/bash
mkdir -p ~/exercises/data
for i in 1 2 3; do
  echo "This is sample file $i with some words in it" > ~/exercises/data/file$i.txt
done
echo "Python exercises ready in ~/exercises/"
echo "Run: python3 exercises/exercise1.py"
