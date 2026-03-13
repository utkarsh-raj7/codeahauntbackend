#!/bin/bash
sleep 99999 &
echo $! > ~/background.pid
echo "A background process is running. Find it with: ps aux"
