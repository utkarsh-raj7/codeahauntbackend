#!/bin/bash
echo "Ansible $(ansible --version | head -1)"
echo "Playbooks are in ~/playbooks/"
echo "Run with: ansible-playbook playbooks/setup.yml"
