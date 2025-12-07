# SOP-CLOUD-AZ-00: Aprovisionamiento de Estación de Gestión Windows

| Datos de Control | Valor |
| :--- | :--- |
| **ID** | SOP-CLOUD-AZ-00 |
| **Dominio** | Cloud Engineering / Workstation |
| **Clasificación** | Uso Interno |
| **Propietario** | SysAdmin & DevOps OpsTeam |
| **Estado** | 🟢 Activo |
| **Última Rev.** | 2025-12-07 |

## 1. Objetivo y Alcance

Este procedimiento define el estándar técnico para la configuración de estaciones de trabajo basadas en Windows dedicadas a la gestión de infraestructura Microsoft Azure.

Establece la obligatoriedad de instalar herramientas CLI específicas y módulos de PowerShell necesarios para interactuar con la API de Azure Resource Manager (ARM), garantizando la consistencia en los entornos locales del equipo de ingeniería.

## 2. Prerrequisitos

* **Sistema Operativo:** Windows 10 (22H2) o Windows 11.
* **Privilegios:** Permisos de Administrador Local requeridos **únicamente** para el aprovisionamiento inicial del software.
* **Red:** Acceso saliente HTTPS (443) hacia `*.microsoft.com`, `*.azure.com`, y `psgallery.com`.

## 3. Procedimiento de Aprovisionamiento

### 3.1. Entorno de Shell (PowerShell 7)

La versión legacy de Windows PowerShell (v5.1) está obsoleta para operaciones en la nube multiplataforma. Se debe instalar PowerShell 7 (Core) como el shell de ejecución predeterminado.

**Ejecución:**

```powershell
winget install --id Microsoft.PowerShell --source winget --accept-package-agreements
```

### 3.2. Interfaz de Línea de Comandos de Azure (CLI)

Aprovisionamiento del binario `az` para la gestión imperativa de recursos e integración con scripts de shell.

**Ejecución:**

```powershell
winget install -e --id Microsoft.AzureCLI --accept-package-agreements
```

### 3.3. Módulo Azure PowerShell (Az)

Instalación de la colección de módulos `Az` desde la Galería de PowerShell (PSGallery). Este paso requiere una Sesión Elevada (Ejecutar como Administrador).

**Ejecución:**

```powershell
# Configurar política de ejecución para permitir scripts firmados remotamente
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Instalar framework del módulo (Incluir flag -AllowClobber para evitar conflictos)
Install-Module -Name Az -Repository PSGallery -Force -AllowClobber -Scope AllUsers
```

---

## 4. Política de Uso Operativo

Para mantener el Principio de Mínimo Privilegio (PoLP) en la estación de trabajo local:

1. **Operaciones Estándar:** Todas las interacciones con Azure (Inicio de sesión, Creación de recursos, Monitorización) DEBEN realizarse utilizando una sesión de terminal de **Usuario Estándar**.
2. **Operaciones Administrativas:** Los privilegios de Admin Local SOLO son requeridos para la actualización de herramientas (`winget upgrade` o `Update-Module`).

---

## 5. Gestión de Identidad y Acceso (IAM)

La autenticación se basa en tokens OAuth2 generados mediante interacción basada en navegador.

### 5.1. Inicialización de Sesión CLI

Inicializa la configuración JSON en `%USERPROFILE%\.azure`.

```powershell
az login
# Validación: Verificar contexto de suscripción activa
az account show --output table
```

### 5.2. Inicialización de Sesión PowerShell

Inicializa el contexto para cmdlets basados en `.NET`.

```powershell
Connect-AzAccount
# Validación: Verificar contexto
Get-AzContext
```

---

## 6. Control de Calidad (Validación)

Verificación post-instalación para asegurar el cumplimiento con los estándares mínimos de versión.

```powershell
# 1. Verificar Versión Core (Debe ser 7.x+)
$PSVersionTable.PSVersion

# 2. Verificar Versión CLI (Debe mostrar salida JSON)
az version

# 3. Verificar Disponibilidad del Módulo Az
Get-Module -Name Az -ListAvailable
```

## 7. Diagnóstico y Resolución

| Código de Error | Causa Raíz | Resolución |
| :--- | :--- | :--- |
| `az is not recognized` | Variable de entorno PATH no actualizada. | Cerrar y volver a abrir la sesión de terminal completamente. |
| `Connect-AzAccount is not recognized` | Módulo instalado en un alcance (scope) diferente o instalación incompleta. | Verificar instalación con `Get-Module -ListAvailable Az`. Re-ejecutar instalación si está vacío. |
| `Nuget provider is required` | Falta el proveedor de paquetes. | Aceptar el mensaje para instalar NuGet durante la ejecución de `Install-Module`. |
