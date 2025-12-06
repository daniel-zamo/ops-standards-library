# SOP-LINUX-ANS-01 - REFERENCIA TÉCNICA

**PROYECTO:** Estandarización de Entorno de Desarrollo IaC  
**CÓDIGO:** SOP-LINUX-ANS-01  
**FECHA:** 2024-12-06  
**REVISIÓN:** 2.0 (Refactorización Makefile/Secrets)  
**AUTOR:** dzamo/Grp Ops  
**CLASIFICACIÓN:** Interno / Técnico  

## 1. OBJETO

Establecer el procedimiento estándar para la creación, estructura y operación de proyectos de automatización con **Ansible Core**. Este estándar prioriza la automatización del entorno de desarrollo (vía `Makefile`) y la gestión segura de secretos.

## 2. ALCANCE

Aplica a cualquier nuevo repositorio de infraestructura creado por el equipo de Operaciones bajo sistemas **Ubuntu 22.04+** o **WSL2**.

## 3. REQUISITOS DEL SISTEMA

El host de control debe contar con las siguientes herramientas base:

* **OS:** Ubuntu 24.04 LTS o WSL2 equivalente.
* **Paquetes:** `python3`, `python3-venv`, `make`, `git`.
* **Acceso:** Claves SSH configuradas hacia los hosts destino.

## 4. GESTIÓN DE DEPENDENCIAS (SISTEMA)

Para permitir la compilación de librerías Python y la ejecución de tareas automatizadas, se requiere:

```bash
sudo apt update
sudo apt install -y curl git make python3-venv build-essential
```

## 5. ARQUITECTURA DEL PROYECTO

Se define la siguiente estructura de directorios como estándar obligatorio. Esta estructura separa la configuración pública de los secretos locales.

**Ruta base:** `$HOME/projects/<nombre-descriptivo>` (Ej: `ansible-intranet-core`)

```text
<proyecto>/
├── Makefile                # ⚙️ Orquestador (Wrapper)
├── ansible.cfg             # Configuración del motor
├── requirements.yml        # Colecciones (Galaxy)
├── inventory/
│   ├── dev                 # Inventario Desarrollo (IPs Privadas)
│   └── prod                # Inventario Producción (Placeholders)
├── group_vars/
│   ├── all.yml             # Variables Públicas (Sanitizadas)
│   └── secrets.yml         # 🔒 Secretos Reales (GitIgnored)
├── playbook/               # Lógica de ejecución
│   └── deploy.yml          # Playbook principal
└── .gitignore              # Exclusiones de Git
```

## 6. CONFIGURACIÓN DEL MOTOR

### 6.1. Archivo `ansible.cfg`

Se debe utilizar una configuración minimalista y robusta, evitando callbacks que generen conflictos de versión.

```ini
[defaults]
inventory = ./inventory/dev
roles_path = ./roles
collections_path = ./collections
host_key_checking = False
pipelining = True

# Usar formato estándar para evitar errores de plugins externos
stdout_callback = default

# Reducción de ruido visual
deprecation_warnings = False
interpreter_python = auto_silent

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
```

### 6.2. Archivo `.gitignore`

Es crítico bloquear la subida de secretos y entornos virtuales.

```text
.venv/
__pycache__/
*.retry
*.log
.env
# Bloqueo de secretos locales
group_vars/secrets.yml
```

## 7. AUTOMATIZACIÓN DEL ENTORNO (MAKEFILE)

Se prohíbe la gestión manual de entornos virtuales (`source activate`). Todo proyecto debe incluir un `Makefile` en la raíz con las siguientes directivas estándar:

```makefile
.PHONY: setup deploy clean check

VENV := .venv
PIP := $(VENV)/bin/pip
ANSIBLE := $(VENV)/bin/ansible-playbook
GALAXY := $(VENV)/bin/ansible-galaxy

# Inicialización (Setup)
setup:
 python3 -m venv $(VENV)
 $(PIP) install --upgrade pip
 $(PIP) install ansible-core ansible-lint docker
 $(GALAXY) install -r requirements.yml --force

# Despliegue (Deploy)
deploy:
 $(ANSIBLE) playbook/deploy.yml

# Verificación (Lint)
check:
 $(VENV)/bin/ansible-lint playbook/deploy.yml

# Limpieza
clean:
 rm -rf $(VENV) collections/ansible_collections
```

## 8. GESTIÓN DE SECRETOS (PATRÓN DE SOBREESCRITURA)

Para permitir repositorios públicos sin comprometer la seguridad, se utiliza el patrón de doble archivo de variables.

**1. Archivo Público (`group_vars/all.yml`):**
Contiene la estructura y valores por defecto o sanitizados. Se sube a Git.

```yaml
db_pass: "CHANGE_ME"
```

**2. Archivo Privado (`group_vars/secrets.yml`):**
Contiene las contraseñas reales. **NO** se sube a Git (bloqueado por `.gitignore`).

```yaml
db_pass: "SuperSecret123!"
```

**3. Carga en Playbook:**
El playbook debe cargar ambos archivos explícitamente.

```yaml
- hosts: all
  vars_files:
    - "../group_vars/all.yml"
    - "../group_vars/secrets.yml" # Sobreescribe si existe
```

## 9. CICLO DE OPERACIÓN

El operador interactúa con el proyecto exclusivamente a través de `make`:

1. **Clonar repositorio.**
2. **Inicializar:** `make setup`
3. **Configurar Secretos:** Crear `group_vars/secrets.yml` localmente.
4. **Desplegar:** `make deploy`

---
