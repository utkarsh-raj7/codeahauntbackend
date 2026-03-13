#!/bin/bash
echo "Security hardening tasks:"
echo "1. Find world-writable files: find / -perm -o+w -type f 2>/dev/null | grep -v proc"
echo "2. Check for SUID binaries: find / -perm -4000 2>/dev/null"
echo "3. Review /etc/passwd for unexpected users: cat /etc/passwd"
echo "4. Check listening ports: ss -tlnp"
