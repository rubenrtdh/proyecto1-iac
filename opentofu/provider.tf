terraform {
  required_providers {
    # Para crear máquinas, discos y redes en KVM
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
    # Para escribir el fichero de inventario de Ansible en tu equipo
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}
