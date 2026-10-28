resource "local_file" "inventario" {
  filename        = "${path.module}/../ansible/hosts"
  file_permission = "0644"
  content = templatefile("${path.module}/inventario.tftpl", {
    ip_web      = try(libvirt_domain.maquina["web"].network_interface[0].addresses[0], "")
    ip_bd       = try(libvirt_domain.maquina["bd"].network_interface[0].addresses[0], "")
    usuario_web = local.maquinas.web.usuario
    usuario_bd  = local.maquinas.bd.usuario
  })
}
