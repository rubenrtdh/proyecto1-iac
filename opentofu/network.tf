# Red NAT con DHCP: acceso desde tu equipo y salida a internet
resource "libvirt_network" "p1-nat" {
  name      = "p1-nat"
  mode      = "nat"
  addresses = ["192.168.120.0/24"]
  dhcp {
    enabled = true
  }
  autostart = true
}

# Red de datos muy aislada: sin addresses = el anfitrión no tiene IP aquí
resource "libvirt_network" "p1-datos" {
  name      = "p1-datos"
  mode      = "none"
  autostart = true
}
