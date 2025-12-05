# SOP-LINUX-ANS-01 - DOCUMENTO DE REFERENCIA TÉCNICA

**PROYECTO:** Estandarización de Entorno de Desarrollo IaC  
**CÓDIGO:** SOP-LINUX-ANS-01  
**FECHA:** 2024-11-03  
**REVISIÓN:** 1.0
**AUTOR:** dzamo/Grp Ops  
**CLASIFICACIÓN:** Interno / Técnico  

## 1. OBJETO

Establecer el procedimiento estándar para el despliegue y configuración de estaciones de trabajo destinadas al desarrollo de *Infrastructure as Code* (IaC) mediante **Ansible Core** sobre sistemas **Ubuntu 24.04 LTS**.

## 2. ALCANCE

Este documento aplica a cualquier entorno de desarrollo local (estaciones de trabajo físicas, máquinas virtuales o subsistemas WSL2) utilizado por el equipo de Operaciones/DevOps.

## 3. REQUISITOS DEL SISTEMA

El entorno base debe cumplir las siguientes especificaciones antes de iniciar el procedimiento:

* **Sistema Operativo:** Ubuntu 24.04 LTS (Noble Numbat) o WSL2 equivalente.
* **Acceso:** Privilegios de `sudo` para la instalación de dependencias del sistema.
* **Conectividad:** Acceso a repositorios oficiales de Ubuntu y PyPI (Python Package Index).

## 4. GESTIÓN DE DEPENDENCIAS DE SISTEMA (S.O.)

Debido a las restricciones de PEP 668 en Ubuntu 24.04, se prohíbe la instalación global de paquetes Python vía `pip`. Se requiere la instalación de las siguientes librerías de sistema para permitir la compilación de módulos en entornos virtuales.

Ejecutar en terminal:

```bash
sudo apt update
sudo apt install -y curl git python3 python3-pip python3-venv build-essential libssl-dev libffi-dev python3-dev
```

## 5. ARQUITECTURA DEL ENTORNO DE TRABAJO

Se define la siguiente estructura de directorios como el estándar para repositorios de Ansible. Esta estructura garantiza la compatibilidad con sistemas de CI/CD y la segregación de entornos.

**Ruta base sugerida:** `$HOME/ansible-projects/<nombre-proyecto>`

```text
<proyecto>/
├── .venv/                  # Entorno virtual (Excluido de Git)
├── ansible.cfg             # Configuración local del proyecto
├── requirements.yml        # Dependencias de Galaxy (Collections/Roles)
├── inventory/
│   ├── dev                 # Inventario entorno Desarrollo
│   └── prod                # Inventario entorno Producción
├── group_vars/             # Variables de grupo
├── host_vars/              # Variables de host
├── playbooks/              # Lógica de ejecución (.yml)
├── roles/                  # Roles locales
└── collections/            # Colecciones instaladas localmente
```

## 6. PROCEDIMIENTO DE DESPLIEGUE (SETUP)

### 6.1. Inicialización del Entorno Virtual (Venv)

Para garantizar el aislamiento de versiones entre proyectos, se debe instanciar un entorno virtual de Python.

```bash
# Creación del entorno
python3 -m venv .venv

# Activación del entorno
source .venv/bin/activate
```

### 6.2. Instalación del Motor Ansible

Una vez activado el entorno (indicador `.venv` en prompt), proceder con la instalación de los paquetes core.

```bash
pip install --upgrade pip
pip install ansible-core ansible-lint
```

### 6.3. Configuración del Motor (ansible.cfg)

Se debe generar el archivo `ansible.cfg` en la raíz del proyecto para sobrescribir la configuración global `/etc/ansible/ansible.cfg`.

**Contenido requerido para `ansible.cfg`:**

```ini
[defaults]
inventory = ./inventory/dev
roles_path = ./roles
collections_path = ./collections
host_key_checking = False
pipelining = True
stdout_callback = yaml
bin_ansible_callbacks = True

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
```

## 7. CONTROL DE VERSIONES (GIT)

Para mantener la higiene del repositorio, se establece la siguiente configuración de exclusión (`.gitignore`). Es imperativo no versionar binarios, entornos virtuales ni secretos.

**Contenido para `.gitignore`:**

```text
# Python & Venv
.venv/
__pycache__/
*.pyc

# Ansible Artifacts
*.retry
collections/ansible_collections/

# Secrets & Keys
*.pem
*.key
.env
```

## 8. GESTIÓN DE COLECCIONES (GALAXY)

Las dependencias externas deben declararse explícitamente en el archivo `requirements.yml` para facilitar la replicación del entorno.

**Ejemplo de `requirements.yml`:**

```yaml
---
collections:
  - name: community.general
    version: 8.x
  - name: ansible.posix
    version: 1.5.x
```

**Comando de instalación:**

```bash
ansible-galaxy install -r requirements.yml
```

## 9. CICLO DE OPERACIÓN ESTÁNDAR

Para sesiones de trabajo diarias, el operador debe seguir el siguiente flujo:

1. **Activación:** `source .venv/bin/activate`
2. **Validación:** `ansible-lint playbooks/<playbook>.yml`
3. **Ejecución:** `ansible-playbook playbooks/<playbook>.yml`
4. **Desactivación:** `deactivate`

---
