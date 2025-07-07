# variables.tf
variable "aws_region" {
  description = "AWS region for the resources"
  type        = string
  default     = "ap-northeast-2"
}

variable "public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub" # Change this to your public key path
}
