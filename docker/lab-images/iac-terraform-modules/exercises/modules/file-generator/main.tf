variable "filename" { type = string }
variable "content"  { type = string }

resource "local_file" "generated" {
  filename = var.filename
  content  = var.content
}

output "created_file" { value = local_file.generated.filename }
