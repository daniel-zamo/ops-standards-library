# SOP-CLOUD-AZ-01: Azure Ansible Containerized Environment

| Metadato | Valor |
| :--- | :--- |
| **ID** | SOP-CLOUD-AZ-01 |
| **Dominio** | Cloud Engineering / IaC |
| **Autor** | SysAdmin & DevOps OpsTeam |
| **Estado** | 🟢 Approved |
| **Última Rev.** | 2025-12-06 |

## 1. Objetivo y Alcance

Este procedimiento define el estándar para aprovisionar un **Entorno de Ejecución Aislado** para la gestión de recursos en Microsoft Azure mediante Ansible.

### Problema que resuelve

La instalación nativa de `azure-cli` y las librerías de Python (`azure-sdk`) en el host local suele generar conflictos de dependencias (Dependency Hell) y problemas de compatibilidad entre versiones de Python (ej. 3.12 vs 3.10).

### Solución Arquitectónica

Implementación del patrón **Execution Environment**:

1. **Docker:** Encapsula el motor Ansible, Python 3.10 y la colección `azure.azcollection`.
2. **Credential Passthrough:** El contenedor no almacena credenciales persistentes; monta el token de sesión (`~/.azure`) generado en el host anfitrión.
3. **Ephemeral Runtime:** El contenedor se destruye tras cada ejecución, garantizando un entorno limpio.

---

## 2. Prerrequisitos del Host (Control Node)

El equipo desde donde se ejecutarán las operaciones debe cumplir:

* **Docker Engine:** Runtime de contenedores activo.
* **Azure CLI (`az`):** Instalado en el host para gestión de autenticación.
* **Conectividad:** Acceso a `management.azure.com` (HTTPS/443).

---

## 3. Procedimiento de Construcción (Build)

### 3.1. Definición de Artefactos

Crear un directorio de contexto (ej. `~/builds/ansible-azure`) y generar los siguientes manifiestos.

**Archivo: `requirements.yml`**
Define la colección oficial mantenida por Microsoft/Ansible.

```yaml
---
collections:
  - name: azure.azcollection
    version: 1.19.0
```

**Archivo: `Dockerfile`**
Especificación de la imagen base. Utilizamos Python 3.10-slim por su estabilidad probada con los SDKs de Azure actuales.

```dockerfile
FROM python:3.10-slim

# Supresión de alertas pip root
ENV PIP_ROOT_USER_ACTION=ignore

# 1. Instalación de dependencias de sistema (Compiladores necesarios para SDKs)
RUN apt-get update && apt-get install -y \
    gcc \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --upgrade pip \
    && pip install ansible-core==2.16.0

# 2. Inyección de definición de colecciones
WORKDIR /ansible
COPY requirements.yml .

# 3. Instalación de Colección Azure y Dependencias Python (Paso Crítico)
# Se extrae el requirements.txt interno de la colección para asegurar compatibilidad exacta.
RUN ansible-galaxy install -r requirements.yml \
    && pip install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt

# 4. Entrypoint por defecto
CMD ["/bin/bash"]
```

### 3.2. Compilación de la Imagen

Ejecutar el build etiquetando la imagen con versionado semántico.

```bash
docker build -t ansible-azure:v1.0 .
```

---

## 4. Configuración del Runtime (Alias)

Para simplificar la invocación y asegurar el montaje correcto de volúmenes, se debe configurar un alias en el shell del usuario (`~/.bashrc` o `~/.zshrc`).

### Definición del Alias

```bash
alias az-ansible='docker run --rm -it \
  -v $(pwd):/ansible \
  -v $HOME/.azure:/root/.azure \
  ansible-azure:v1.0 ansible-playbook'
```

### Explicación de Montajes

* `-v $(pwd):/ansible`: Monta el directorio de trabajo actual dentro del contenedor. Permite acceder a los playbooks locales.
* `-v $HOME/.azure:/root/.azure`: **Identity Mapping**. Permite al contenedor reutilizar el token de autenticación generado por `az login` en el host.

---

## 5. Flujo de Trabajo Operativo

### 5.1. Autenticación (Paso Previo)

Antes de ejecutar cualquier playbook, renueve el token en el host.

```bash
az login
# Verificar suscripción activa
az account show
```

### 5.2. Ejecución de Playbooks

Navegue al directorio de su proyecto IaC y utilice el alias definido.

```bash
cd ~/my-workspace/projects/azure-migration
az-ansible playbook.yml
```

### 5.3. Validación de Conectividad (Smoke Test)

Crear un playbook de prueba `check_azure.yml`:

```yaml
- name: Azure Connectivity Check
  hosts: localhost
  connection: local
  tasks:
    - name: Get Resource Groups
      azure.azcollection.azure_rm_resourcegroup_info:
      register: rgs
    - debug:
        msg: "Auth OK. Found {{ rgs.resourcegroups | length }} Resource Groups."
```

Ejecutar: `az-ansible check_azure.yml`

---

## 6. Resolución de Problemas (Troubleshooting)

| Síntoma | Causa Probable | Solución |
| :--- | :--- | :--- |
| `Please run 'az login'` dentro del contenedor | El volumen `.azure` no está montado o el token expiró. | Ejecutar `az login` en el host y verificar el mapeo `-v` en el alias. |
| `ModuleNotFoundError` | La imagen Docker no compiló las librerías de Python. | Reconstruir la imagen verificando el paso `pip install -r ...requirements-azure.txt`. |
| Error de Permisos en Docker | El usuario no pertenece al grupo `docker`. | `sudo usermod -aG docker $USER` o usar `sudo` (no recomendado). |
