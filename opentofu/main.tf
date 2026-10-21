locals {
  maquinas = {
    web = { ip_datos = "10.0.0.10" }
    bd  = { ip_datos = "10.0.0.20" }
  }
}

# Disco: clon ligero de la imagen base
resource "libvirt_volume" "disco" {
  for_each         = local.maquinas
  name             = "${each.key}.qcow2"
  pool             = var.libvirt_pool_name
  base_volume_name = var.base_image
  base_volume_pool = var.libvirt_pool_name
  format           = "qcow2"
}

# cloud-init: usuario, clave SSH y red
resource "libvirt_cloudinit_disk" "cloudinit" {
  for_each = local.maquinas
  name     = "${each.key}-cloudinit.iso"
  pool     = var.libvirt_pool_name
  user_data = templatefile("${path.module}/cloud-init/user-data.tftpl", {
    hostname = each.key
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

  # ens3: red NAT (DHCP)
  network_interface {
    network_id     = libvirt_network.p1-nat.id
    wait_for_lease = true
  }

  # ens4: red de datos (IP estática, sin wait_for_lease)
  network_interface {
    network_id = libvirt_network.p1-datos.id
  }

  disk {
    volume_id = libvirt_volume.disco[each.key].id
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit[each.key].id

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}
