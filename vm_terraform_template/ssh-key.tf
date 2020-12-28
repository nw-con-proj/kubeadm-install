#Variable
variable "sshkey_name" {}
variable "sshkey_privatekey_filename" {}
variable "sshkey_publickey_filename" {}

#resource
provider "tls" {
}

resource "tls_private_key" "keygen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  filename = var.sshkey_privatekey_filename
  content  = "${tls_private_key.keygen.private_key_pem}"
}

resource "local_file" "public_key_openssh" {
  filename = var.sshkey_publickey_filename
  content  = "${tls_private_key.keygen.public_key_openssh}"
}

output "keygen_privatekey" {
  description = "keygen privatekey"
  value       = tls_private_key.keygen.private_key_pem
}

output "keygen_pubkey" {
  description = "keygen pubkey"
  value       = tls_private_key.keygen.public_key_openssh
}

