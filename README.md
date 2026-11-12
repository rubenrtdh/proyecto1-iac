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
      │                                                  │
 web (Debian 13)                                  bd (Ubuntu 26.04)
 Apache + PHP                                     MariaDB
 un virtual host por cliente                      una BD y un usuario por cliente
 ens3: DHCP · ens4: 10.0.0.10                     ens3: DHCP · ens4: 10.0.0.20
      │                                                  │
      └──── red p1-datos (muy aislada) 10.0.0.0/24 ──────┘
```

- **p1-nat**: acceso desde el anfitrión y salida a internet.
- **p1-datos**: red muy aislada con IP estáticas por la que se comunican web y bd.
  MariaDB solo escucha en esta red, y el usuario de cada cliente solo tiene permisos
  sobre su base de datos y solo acepta conexiones desde web.

## Requisitos

- KVM/libvirt y OpenTofu instalados.
- Imágenes base en el pool `default`: `debian13-base.qcow2` y `ubuntu2604-base.qcow2`.
- Una clave SSH en `~/.ssh/id_ed25519.pub` (se cambia en `opentofu/variables.tf`).
- Ansible con la colección `community.mysql`:

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

| Rol         | Máquinas | Qué hace |
|-------------|----------|----------|
| `commons`   | todas    | Actualiza el sistema e instala paquetes comunes |
| `bd`        | bd       | MariaDB en la red de datos; base de datos y usuario de cada cliente; tablas del guestbook; baja de clientes |
| `web`       | web      | Apache + PHP; virtual host y directorio de cada cliente; página por defecto del hosting; baja de clientes |
| `guestbook` | web      | Despliega el guestbook y genera su `config.php` para los clientes con esta aplicación |
| `wordpress` | web      | Despliega WordPress y genera su `wp-config.php` para los clientes con esta aplicación |

## Clientes del hosting

Los clientes están en `ansible/group_vars/all/clientes.yaml`:

```yaml
clientes:
  - nombre: blog              # base de datos, usuario y directorio
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
  borran su virtual host, sus ficheros, su base de datos y su usuario.

Al empezar, el playbook comprueba la lista (nombres y dominios sin repetir,
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
