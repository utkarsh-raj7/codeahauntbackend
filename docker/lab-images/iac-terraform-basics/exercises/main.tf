# Terraform Basics Exercise
# Using the 'local' provider (no cloud account needed)
terraform {
  required_providers {
    local = { source = "hashicorp/local" }
  }
}

# TODO: Create a local_file resource that writes "Hello Terraform!" to hello.txt
# resource "local_file" "hello" { ... }

# TODO: Add an output that shows the filename
# output "filename" { ... }
