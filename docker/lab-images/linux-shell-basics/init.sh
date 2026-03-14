#!/bin/bash
# ═══════════════════════════════════════════════
# Linux Shell Basics — Lab Init
# ═══════════════════════════════════════════════

# Create rich workspace
mkdir -p ~/workspace/project/{src,docs,tests,config}
mkdir -p ~/workspace/logs

# Project files
cat > ~/workspace/project/src/main.py << 'PY'
#!/usr/bin/env python3
"""Sample application for shell exploration"""
import os, sys
print(f"Hello from {os.path.basename(__file__)}!")
print(f"Python: {sys.version}")
print(f"User: {os.environ.get('USER', 'unknown')}")
PY

cat > ~/workspace/project/src/utils.sh << 'SH'
#!/bin/bash
greet() { echo "Hello, $1!"; }
count_files() { find "$1" -type f | wc -l; }
SH
chmod +x ~/workspace/project/src/utils.sh ~/workspace/project/src/main.py

echo "# Project Documentation" > ~/workspace/project/docs/readme.md
echo "This is a sample project for practicing shell commands." >> ~/workspace/project/docs/readme.md
echo "version: 1.0" > ~/workspace/project/config/app.yml
echo "debug: true" >> ~/workspace/project/config/app.yml
echo "test_result: PASS" > ~/workspace/project/tests/results.txt
echo "test_count: 42" >> ~/workspace/project/tests/results.txt
echo "coverage: 87%" >> ~/workspace/project/tests/results.txt

# Log files with varied content
for i in {1..20}; do
    level=$([[ $((i % 3)) -eq 0 ]] && echo "ERROR" || ([[ $((i % 2)) -eq 0 ]] && echo "WARN" || echo "INFO"))
    echo "2024-01-$((i % 28 + 1)) 10:$((i % 60)):00 [$level] Service started on port $((3000 + i))" >> ~/workspace/logs/app.log
done

# Hidden config file
echo '{"api_key": "sk-demo-12345", "timeout": 30}' > ~/workspace/.env.json

# Create GUIDE.md
cat > ~/GUIDE.md << 'GUIDE'
# 🐧 Linux Shell Basics — Exercise Guide

## Objective
Master essential shell commands: navigation, file operations, pipes, and redirection.

## Exercises

### 1. Navigate & Explore
```bash
cd ~/workspace
ls -la                    # List all files including hidden
tree .                    # View directory tree
find . -name "*.py"       # Find Python files
```

### 2. File Content
```bash
cat project/src/main.py           # View file contents
head -5 logs/app.log              # First 5 lines
tail -5 logs/app.log              # Last 5 lines
wc -l logs/app.log                # Count lines
```

### 3. Search & Filter (pipes!)
```bash
grep "ERROR" logs/app.log                    # Find errors
grep "ERROR" logs/app.log | wc -l            # Count errors
cat logs/app.log | sort | uniq -c | sort -rn # Frequency analysis
```

### 4. Redirection
```bash
grep "WARN" logs/app.log > ~/warnings.txt    # Save to file
echo "New log entry" >> logs/app.log         # Append to file
cat .env.json | python3 -m json.tool         # Pretty-print JSON
```

### 5. File Operations
```bash
cp project/src/main.py ~/backup.py    # Copy file
mkdir -p ~/output                      # Create directory
mv ~/backup.py ~/output/              # Move file
chmod +x project/src/main.py          # Make executable
./project/src/main.py                 # Run it!
```

## Validation
Run these to check your progress:
- `test -d ~/workspace/project` → workspace exists
- `which tree` → tree command available
- `grep -r "Hello" ~/workspace` → can search files
GUIDE

# Welcome banner
echo ""
echo -e "\033[1;36m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║    🐧 Linux Shell Basics                 ║\033[0m"
echo -e "\033[1;36m╚══════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[33m📁 Workspace:\033[0m ~/workspace"
echo -e "\033[33m📖 Guide:\033[0m     cat ~/GUIDE.md"
echo ""
echo -e "\033[90mStart with: cd ~/workspace && ls -la\033[0m"
echo ""
echo "done"
