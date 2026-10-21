variable "libvirt_pool_name" {
  default = "default"
}

variable "base_image_debian" {
  description = "Imagen base de la máquina web"
  default     = "debian13-base.qcow2"
}

variable "base_image_ubuntu" {
  description = "Imagen base de la máquina bd"
  default     = "ubuntu2604-base.qcow2"
}

variable "memoria" {
  description = "Memoria de cada máquina en MB"
  default     = 1024
}

variable "ssh_key_file" {
  description = "Tu clave pública SSH"
  default     = "~/.ssh/id_ed25519.pub"
}
