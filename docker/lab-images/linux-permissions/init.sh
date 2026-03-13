#!/bin/bash
mkdir -p ~/permissions-lab
echo "public content" > ~/permissions-lab/public.txt
echo "private content" > ~/permissions-lab/private.txt
chmod 644 ~/permissions-lab/public.txt
chmod 600 ~/permissions-lab/private.txt
mkdir -p ~/permissions-lab/shared
chmod 777 ~/permissions-lab/shared
echo "done"
