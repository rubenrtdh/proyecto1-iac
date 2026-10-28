output "web" {
  value = {
    sistema  = "Debian 13"
    ip_nat   = try(libvirt_domain.maquina["web"].network_interface[0].addresses[0], "No disponible")
    ip_datos = local.maquinas.web.ip_datos
  }
}

output "bd" {
  value = {
    sistema  = "Ubuntu 26.04"
    ip_nat   = try(libvirt_domain.maquina["bd"].network_interface[0].addresses[0], "No disponible")
    ip_datos = local.maquinas.bd.ip_datos
  }
}
