# Proyecto 1: Infraestructura como código

Escenario creado con **OpenTofu** (libvirt/KVM) y configurado con **Ansible** para
poner en producción la aplicación [guestbook_php](https://github.com/josedom24/guestbook_php),
un libro de visitas en PHP con MariaDB.

## Escenario

```
                    Equipo anfitrión
                           │
      ┌──── red p1-nat (NAT + DHCP) 192.168.120.0/24 ────┐
      │                                                  │
 web (Debian 13)                                  bd (Ubuntu 26.04)
 Apache + PHP                                     MariaDB
 ens3: DHCP · ens4: 10.0.0.10                     ens3: DHCP · ens4: 10.0.0.20
      │                                                  │
      └──── red p1-datos (muy aislada) 10.0.0.0/24 ──────┘
```

- **p1-nat**: acceso desde el anfitrión y salida a internet.
- **p1-datos**: red muy aislada con IP estáticas por la que se comunican web y bd.
  MariaDB solo escucha en esta red y su usuario solo acepta conexiones desde web.

## Requisitos

- KVM/libvirt y OpenTofu instalados.
- Imágenes base en el pool `default`: `debian13-base.qcow2` y `ubuntu2604-base.qcow2`.
- Una clave SSH en `~/.ssh/id_ed25519.pub` (se cambia en `opentofu/variables.tf`).
- Ansible con la colección `community.mysql`:

  ```bash
  ansible-galaxy collection install -r ansible/requirements.yml
  ```

## Despliegue

```bash
git clone https://github.com/rubenrtdh/proyecto1-iac.git
cd proyecto1-iac/opentofu
tofu init
tofu apply
cd ../ansible
ansible-playbook site.yaml
```

`tofu apply` crea las redes y las máquinas y genera el inventario `ansible/hosts`
con sus IP. `ansible-playbook site.yaml` configura las máquinas con tres roles:

| Rol       | Máquinas | Qué hace |
|-----------|----------|----------|
| `commons` | todas    | Actualiza el sistema e instala paquetes comunes |
| `bd`      | bd       | MariaDB escuchando en la red de datos, base de datos, usuario y tablas |
| `web`     | web      | Apache + PHP, virtual host `www.ruben.org` y despliegue de la aplicación |

Las variables están en `ansible/group_vars/`.

## Acceso a la aplicación

Ver la IP de web con `tofu output` y añadir al `/etc/hosts` del equipo:

```
<IP de web>   www.ruben.org
```

Después, abrir http://www.ruben.org en el navegador.

## Destruir el escenario

```bash
cd opentofu
tofu destroy
```
