variable "libvirt_pool_name" {
  description = "Pool de libvirt donde están las imágenes"
  default     = "default"
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
  description = "Clave pública SSH que se mete en las máquinas"
  default     = "~/.ssh/id_ed25519.pub"
}
