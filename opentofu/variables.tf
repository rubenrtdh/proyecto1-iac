variable "libvirt_pool_name" {
  default = "default"
}

variable "base_image" {
  description = "Imagen base de las máquinas"
  default     = "debian13-base.qcow2"
}

variable "memoria" {
  description = "Memoria de cada máquina en MB"
  default     = 1024
}

variable "ssh_key_file" {
  description = "Tu clave pública SSH"
  default     = "~/.ssh/id_ed25519.pub"
}
