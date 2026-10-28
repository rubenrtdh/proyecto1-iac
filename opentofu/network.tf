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

# Red de datos MUY aislada: modo "none" y SIN addresses.
# Así el anfitrión no tiene IP en ella y no hay DHCP: las IP son fijas.
resource "libvirt_network" "p1-datos" {
  name      = "p1-datos"
  mode      = "none"
  autostart = true
}
