# SOP-CLOUD-AZ-02: Estación de Ingeniería Azure en WSL (Ubuntu)

| Datos de Control | Valor |
| :--- | :--- |
| **ID** | SOP-CLOUD-AZ-02 |
| **Dominio** | Cloud Engineering / Workstation |
| **Clasificación** | Uso Interno |
| **Propietario** | SysAdmin & DevOps OpsTeam |
| **Estado** | 🟢 Activo |
| **Última Rev.** | 2025-12-09 |

## 1. Objetivo y Alcance

Este procedimiento estandariza la configuración del subsistema Linux (WSL2) dentro de las estaciones de trabajo Windows. Define el método oficial para instalar y configurar **Azure CLI**, asegurando la paridad entre el entorno de desarrollo local y los agentes de CI/CD basados en Linux.

**Alcance:**
Aplica a cualquier ingeniero que requiera interactuar con la API de Azure (`ARM`) mediante scripts Bash o herramientas nativas de Linux desde una estación Windows.

## 2. Prerrequisitos

* **Host:** Windows 10/11 con WSL2 habilitado.
* **Distribución:** Ubuntu 22.04 LTS o superior (Instancia por defecto).
* **Conectividad:** Acceso a internet para repositorios de Microsoft (`packages.microsoft.com`).

## 3. Arquitectura del Entorno

A diferencia de la gestión vía PowerShell (ver *SOP-CLOUD-AZ-00*), este entorno se centra en la interoperabilidad con herramientas Cloud-Native.

* **Capa de Ejecución:** Ubuntu LTS sobre WSL2.
* **Interfaz de Comandos:** Azure CLI (`az`) instalado vía repositorio oficial (no snap/apt default).
* **Editor:** VS Code ejecutándose en Windows pero conectado remotamente al contexto WSL (`code .`).

---

## 4. Procedimiento de Instalación

### 4.1. Preparación del Sistema Base

Antes de instalar herramientas específicas, se debe asegurar la integridad de la distribución base y las herramientas de seguridad.

```bash
# 1. Actualización de listas y binarios
sudo apt update && sudo apt upgrade -y

# 2. Instalación de dependencias de transporte y seguridad
sudo apt install -y curl ca-certificates gnupg lsb-release
```

### 4.2. Instalación de Azure CLI (Método Microsoft)

:::caution[Restricción de Paquetería]
**NO** utilice el comando `apt install azure-cli` directamente de los repositorios de Ubuntu, ya que suelen distribuir versiones obsoletas. Utilice siempre el script de instalación oficial que configura el repositorio firmado de Microsoft.
:::

Ejecute el siguiente comando para importar las claves GPG y configurar el repositorio:

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Validación:**

```bash
az --version
# Output esperado: azure-cli 2.xx.x (core)
```

### 4.3. Configuración de "Calidad de Vida" (Autocompletado)

Dado el volumen de comandos y parámetros en Azure, el autocompletado es mandatorio para la eficiencia operativa.

1. Habilitar el script de compleción en el perfil de Bash:

    ```bash
    echo "source /etc/bash_completion.d/azure-cli" >> ~/.bashrc
    ```

2. Recargar la configuración:

    ```bash
    source ~/.bashrc
    ```

**Prueba:** Escribe `az vm cr` y presiona `TAB`. Debe completarse a `create`.

---

## 5. Integración con VS Code

Para garantizar el flujo de trabajo híbrido, se deben instalar las siguientes extensiones en el contexto **"WSL: Ubuntu"**:

- ~~**Azure Account (ms-vscode.azure-account):** Autenticación centralizada.~~ DEPRECATED - ahora cubierta por **Azure Resources**.
- **Azure Resources (ms-azuretools.vscode-azureresourcegroups):** Navegación visual de recursos.
- **Bicep (ms-azuretools.vscode-bicep):** Soporte para IaC nativo de Azure.

---

## 6. Procedimiento de Autenticación (Handshake)

La autenticación se realiza mediante el flujo de navegador, que conecta el token de WSL con la identidad de Windows.

```bash
# 1. Iniciar flujo OAuth2
az login

# 2. (Opcional) Listar suscripciones disponibles en formato tabla
az account list --output table
```

### Gestión de Suscripciones Múltiples

Si el usuario tiene acceso a múltiples tenants, debe fijar la suscripción de trabajo explícitamente para evitar despliegues en el entorno incorrecto.

```bash
# Establecer contexto activo
az account set --subscription "NOMBRE_O_ID_DE_SUSCRIPCION"
```

---

## 7. Diagnóstico y Resolución

| Código / Error | Causa Raíz | Resolución |
| :--- | :--- | :--- |
| `az: command not found` | El PATH no se ha recargado tras la instalación. | Ejecutar `source ~/.bashrc` o reiniciar la terminal WSL. |
| `Browser not opening` | WSL no puede invocar al navegador de Windows. | Ejecutar `az login --use-device-code` y copiar el código manualmente. |
| `Permission denied` (Config) | Propiedad incorrecta en carpeta `.azure`. | Ejecutar `sudo chown -R $USER:$USER ~/.azure`. |
