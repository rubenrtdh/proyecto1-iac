# Proyecto 1: Infraestructura como código — Hosting Rubén

Escenario creado con **OpenTofu** (libvirt/KVM) y configurado con **Ansible** que
funciona como un pequeño **proveedor de hosting**: cada cliente tiene su web, su base
de datos y su usuario, y se dan de alta y de baja editando una lista.

Aplicaciones que ofrece el hosting:

- [guestbook_php](https://github.com/josedom24/guestbook_php): libro de visitas en PHP con MariaDB.
- [WordPress](https://es.wordpress.org/).

## Escenario

```
                         Equipo anfitrión
                                │
         ┌──── red p1-nat (NAT + DHCP) 192.168.120.0/24 ────┐
         │                      │                           │
  web (Debian 13)        bd (Ubuntu 26.04)            nas (Debian 13)
  Apache + PHP           MariaDB                      Servidor NFS
  un vhost por cliente   una BD y un usuario          un espacio por cliente
  monta por NFS el       por cliente                  (con un usuario del
  espacio de cada                                     sistema por cliente)
  cliente
  ens4: 10.0.0.10        ens4: 10.0.0.20              ens4: 10.0.0.30
         │                      │                           │
         └──── red p1-datos (muy aislada) 10.0.0.0/24 ──────┘
```

- **p1-nat**: acceso desde el anfitrión y salida a internet.
- **p1-datos**: red muy aislada con IP estáticas por la que se comunican las máquinas.
  MariaDB solo escucha en esta red, y el usuario de cada cliente solo tiene permisos
  sobre su base de datos y solo acepta conexiones desde web.
- **nas**: guarda los ficheros de los clientes. Cada cliente tiene su directorio,
  exportado por NFS solo a web, y web lo monta en el DocumentRoot de su vhost.

## Requisitos

- KVM/libvirt y OpenTofu instalados.
- Imágenes base en el pool `default`: `debian13-base.qcow2` (web y nas) y `ubuntu2604-base.qcow2` (bd).
- Una clave SSH en `~/.ssh/id_ed25519.pub` (se cambia en `opentofu/variables.tf`).
- Ansible con las colecciones `community.mysql` y `ansible.posix`:

  ```bash
  ansible-galaxy collection install -r ansible/requirements.yml
  ```

- La contraseña de Ansible Vault en el fichero `ansible/.vault_pass` (no se sube al
  repositorio):

  ```bash
  echo 'contraseña-del-vault' > ansible/.vault_pass
  chmod 600 ansible/.vault_pass
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
con sus IP. `ansible-playbook site.yaml` comprueba la lista de clientes y configura
las máquinas con estos roles:

| Rol                 | Máquinas | Qué hace |
|---------------------|----------|----------|
| `commons`           | todas    | Actualiza el sistema e instala paquetes comunes |
| `bd`                | bd       | MariaDB en la red de datos; base de datos y usuario de cada cliente; tablas del guestbook; baja de clientes |
| `usuarios_clientes` | nas, web | Un usuario y un grupo del sistema por cliente, con el mismo UID en todas las máquinas |
| `nas`               | nas      | Servidor NFS; un espacio por cliente (dueño el cliente, grupo `www-data`, `2750`) exportado solo a web; baja de clientes |
| `guestbook`         | nas      | Despliega el guestbook en el espacio del cliente (con su usuario) y genera su `config.php` |
| `wordpress`         | nas      | Despliega WordPress en el espacio del cliente y genera su `wp-config.php` |
| `nfs_cliente`       | web      | Monta por NFS el espacio de cada cliente en su DocumentRoot; desmonta los de baja |
| `web`               | web      | Apache + PHP; virtual host de cada cliente; página por defecto del hosting; baja de clientes |

Al dar de baja a un cliente, primero web desmonta su espacio y después el NAS lo borra
(por eso `site.yaml` tiene una jugada para desmontar antes de la del NAS).

## Clientes del hosting

Los clientes están en `ansible/group_vars/all/clientes.yaml`:

```yaml
clientes:
  - nombre: blog              # base de datos, usuario y directorio
    uid: 2002                 # usuario del sistema (2000-2999), no se reutiliza
    dominio: blog.ruben.org
    aplicacion: wordpress     # guestbook | wordpress
    plan: premium             # basico | premium
    estado: alta              # alta | baja
```

- **Dar de alta un cliente**: añadir su contraseña en el vault y un elemento a la
  lista, y ejecutar `ansible-playbook site.yaml`.

  ```bash
  ansible-vault edit group_vars/all/vault.yaml
  ```

- **Dar de baja un cliente**: cambiar su `estado` a `baja` y ejecutar el playbook. Se
  borran su virtual host, su espacio en el NAS, su base de datos y sus usuarios.

Al empezar, el playbook comprueba la lista (nombres, UID y dominios sin repetir,
aplicación y plan válidos, contraseña en el vault) y se para si hay algún error.

Las contraseñas de los clientes y la semilla de las claves de WordPress están
cifradas en `ansible/group_vars/all/vault.yaml` con **Ansible Vault**.

## Acceso a las webs

Ver la IP de web con `tofu output` y añadir al `/etc/hosts` del equipo:

```
<IP de web>   www.ruben.org blog.ruben.org hosting.ruben.org
```

- http://www.ruben.org: guestbook del cliente `libro`.
- http://blog.ruben.org: WordPress del cliente `blog` (la primera vez se completa su
  instalación desde el navegador).
- http://hosting.ruben.org: página del hosting con los clientes activos. Cualquier
  dominio que no sea de un cliente dado de alta muestra esta página.

## Destruir el escenario

```bash
cd opentofu
tofu destroy
```
