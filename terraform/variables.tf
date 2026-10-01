variable "ami_id" {
  description = "AMI Ubuntu Server 24.04 LTS (ca-central-1)"
  type        = string
}

variable "key_name" {
  description = "Nom de la paire de clés SSH déclarée dans AWS"
  type        = string
}
