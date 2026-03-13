"""
Tasks:
1. Load config.yaml and print the app version
2. List all server names and their IPs
3. Convert the entire config to JSON and save to config.json
4. Add a new server to the YAML and save it back
"""
import yaml, json

with open('exercises/config.yaml') as f:
    config = yaml.safe_load(f)

# TODO: complete the tasks above
