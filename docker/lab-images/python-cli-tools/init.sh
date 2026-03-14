#!/bin/bash
# ═══════════════════════════════════════════════
# Python CLI Tools — Lab Init
# ═══════════════════════════════════════════════

# Create GUIDE.md
cat > ~/GUIDE.md << 'GUIDE'
# 🐍 Python CLI Tools — Exercise Guide

## Objective
Build command-line tools using Click and Rich. Complete the TODO exercises.

## Setup
Your exercise files are in `~/exercises/`:
```bash
ls ~/exercises/
```

## Exercises

### 1. Explore the starter code
```bash
cat ~/exercises/cli_tool.py        # Read the TODO template
python3 ~/exercises/cli_tool.py --help   # See Click help
```

### 2. Complete the CLI tool
Edit `~/exercises/cli_tool.py` with `nano`:
```bash
nano ~/exercises/cli_tool.py
```

**Task A**: Implement `greet` command:
```python
@cli.command()
@click.option('--name', default='World', help='Name to greet')
def greet(name):
    click.echo(f"Hello, {name}! 👋")
```

**Task B**: Implement `count` command:
```python
@cli.command()
@click.argument('filename')
@click.option('--verbose', is_flag=True)
def count(filename, verbose):
    with open(filename) as f:
        lines = f.readlines()
    click.echo(f"Lines: {len(lines)}")
    if verbose:
        for i, line in enumerate(lines, 1):
            click.echo(f"  {i}: {line.rstrip()}")
```

### 3. Test your tool
```bash
python3 ~/exercises/cli_tool.py greet --name "CloudLab"
echo -e "one\ntwo\nthree" > /tmp/test.txt
python3 ~/exercises/cli_tool.py count /tmp/test.txt --verbose
```

### 4. Build a Rich output script
```bash
python3 ~/exercises/rich_demo.py     # See Rich in action
cat ~/exercises/rich_demo.py         # Study the code
```

### 5. Create your own CLI tool
```bash
nano ~/exercises/my_tool.py          # Create from scratch
```
Try building a tool that:
- Takes a directory path as argument
- Lists all files with their sizes
- Uses Rich tables for pretty output

## Useful Python Packages (pre-installed)
- `click` — CLI framework
- `rich` — Beautiful terminal output
- `argparse` — Standard library CLI parsing
GUIDE

# Create the Rich demo file
cat > ~/exercises/rich_demo.py << 'PY'
#!/usr/bin/env python3
"""Demo of Rich library for beautiful terminal output"""
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich import print as rprint

console = Console()

# Rich panel
console.print(Panel.fit(
    "[bold green]Welcome to Rich![/bold green]\n"
    "Beautiful terminal output in Python",
    title="🐍 Rich Demo",
    border_style="blue"
))

# Rich table
table = Table(title="Example Data")
table.add_column("Name", style="cyan")
table.add_column("Role", style="green")
table.add_column("Score", justify="right", style="yellow")

table.add_row("Alice", "Engineer", "95")
table.add_row("Bob", "Designer", "87")
table.add_row("Carol", "Manager", "92")

console.print(table)

# Rich colors
rprint("[bold red]Error:[/bold red] Something went wrong!")
rprint("[bold green]Success:[/bold green] All tests passed!")
rprint("[italic]This is italic text[/italic]")
PY

# Create a sample data file for the count exercise
cat > ~/exercises/sample_data.txt << 'DATA'
Server started on port 8080
Connected to database
Processing request from 192.168.1.1
Cache hit ratio: 0.87
Response sent in 23ms
Processing request from 10.0.0.1
Cache miss - fetching from database
Response sent in 145ms
Server health check: OK
DATA

# Welcome banner
echo ""
echo -e "\033[1;32m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[1;32m║    🐍 Python CLI Tools                   ║\033[0m"
echo -e "\033[1;32m╚══════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[33m📂 Exercises:\033[0m ~/exercises/"
echo -e "\033[33m📖 Guide:\033[0m     cat ~/GUIDE.md"
echo ""
echo -e "\033[90mStart with: cat ~/exercises/cli_tool.py\033[0m"
echo -e "\033[90mTry also:   python3 ~/exercises/rich_demo.py\033[0m"
echo ""
