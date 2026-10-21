terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
    local = {
      source = "hashicorp/local"   # para escribir el inventario de Ansible
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}
