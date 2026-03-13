terraform {
  required_providers {
    local = { source = "hashicorp/local" }
  }
}

# TODO: Call the file-generator module twice
# to create two different files with different content
# module "file1" {
#   source   = "./modules/file-generator"
#   filename = "..."
#   content  = "..."
# }
