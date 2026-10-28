locals {
  maquinas = {
    web = {
      imagen   = var.base_image_debian
      usuario  = "debian"
      ip_datos = "10.0.0.10"
    }
    bd = {
      imagen   = var.base_image_ubuntu   # para Debian: var.base_image_debian
      usuario  = "ubuntu"                # para Debian: "debian"
      ip_datos = "10.0.0.20"
    }
  }
}

# Disco: clon ligero (solo guarda los cambios respecto a la imagen base)
resource "libvirt_volume" "disco" {
  for_each         = local.maquinas
  name             = "${each.key}.qcow2"
  pool             = var.libvirt_pool_name
  base_volume_name = each.value.imagen
  base_volume_pool = var.libvirt_pool_name
  format           = "qcow2"
}

# cloud-init: nombre, usuario, clave SSH y configuración de red
resource "libvirt_cloudinit_disk" "cloudinit" {
  for_each = local.maquinas
  name     = "${each.key}-cloudinit.iso"
  pool     = var.libvirt_pool_name
  user_data = templatefile("${path.module}/cloud-init/user-data.tftpl", {
    hostname = each.key
    usuario  = each.value.usuario
    ssh_key  = trimspace(file(pathexpand(var.ssh_key_file)))
  })
  network_config = templatefile("${path.module}/cloud-init/network-config.tftpl", {
    ip_datos = each.value.ip_datos
  })
}

# Las máquinas virtuales
resource "libvirt_domain" "maquina" {
  for_each = local.maquinas
  name     = each.key
  memory   = var.memoria
  vcpu     = 1

  # Primera interfaz (ens3): red NAT con DHCP
  network_interface {
    network_id     = libvirt_network.p1-nat.id
    wait_for_lease = true   # espera a que el DHCP le dé IP
  }

  # Segunda interfaz (ens4): red de datos, IP fija (sin wait_for_lease)
  network_interface {
    network_id = libvirt_network.p1-datos.id
  }

  disk {
    volume_id = libvirt_volume.disco[each.key].id
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit[each.key].id

  # Consola serie: la necesitan las imágenes cloud
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}
