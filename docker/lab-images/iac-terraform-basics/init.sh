#!/bin/bash
echo "Terraform $(terraform version -json | python3 -c 'import sys,json; print(json.load(sys.stdin)[\"terraform_version\"])')"
echo "Exercises are in ~/exercises/"
echo "Tasks:"
echo "1. Complete main.tf"
echo "2. terraform init"
echo "3. terraform plan"
echo "4. terraform apply"
