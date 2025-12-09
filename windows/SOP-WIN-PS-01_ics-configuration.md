# SOP-WIN-PS-01: Configuración de Internet Connection Sharing (ICS)

| Metadato | Valor |
| :--- | :--- |
| **ID** | SOP-WIN-PS-01 |
| **Dominio** | Windows Infrastructure / Networking |
| **Autor** | SysAdmin & DevOps OpsTeam |
| **Estado** | 🟢 Activo |
| **Última Rev.** | 2025-12-09 |

## 1. Objetivo y Alcance

Este procedimiento define el estándar para configurar una estación de trabajo Windows 10/11 como puerta de enlace (Gateway) para una red secundaria conectada vía Ethernet.

El proceso habilita **NAT (Network Address Translation)** y el servicio DHCP nativo de Windows. A diferencia de la configuración gráfica tradicional, este procedimiento fuerza, mediante manipulación del Registro, un rango de red específico (`10.255.255.0/24`) para evitar conflictos con el rango por defecto (`192.168.137.0/24`).

**Alcance de la Topología:**
El procedimiento aplica al host local (Gateway), gestionando el tráfico entre:

* **WAN/Internet:** Adaptador Wireless (Salida).
* **LAN/Privada:** Adaptador Ethernet (Entrada desde dispositivos o clusters locales).

### Diagrama de Topología Lógica

```mermaid
graph TD
    subgraph WAN_Zone [Zona Externa / ISP]
        ISP[Router ISP]
    end

    subgraph Host_Acer [Local Host - Windows Gateway]
        direction TB
        WIFI[Interfaz: Wi-Fi]
        REG[Registro de Windows<br/>ScopeAddress Override]
        ICS[Servicio: SharedAccess / ICS]
        ETH_ACER[Interfaz: Ethernet]
        
        WIFI --"Recibe Internet (DHCP)"--> ISP
        ICS --"NAT & Routing"--> WIFI
        REG -.-> ICS
        ICS --"Gateway: 10.255.255.1"--> ETH_ACER
    end

    subgraph Host_Client [Host Cliente / K8s Node]
        ETH_CLIENT[Interfaz: Ethernet]
        K8S[Workloads]
        
        ETH_CLIENT --"IP Asignada: 10.255.255.x"--> ETH_ACER
        K8S -.-> ETH_CLIENT
    end

    linkStyle 0 stroke:#2ecd71,stroke-width:2px;
    linkStyle 3 stroke:#3498db,stroke-width:2px;
```

## 2. Prerrequisitos

* **Sistema Operativo:** Windows 10 (22H2) o Windows 11 Pro/Enterprise.
* **Privilegios:** PowerShell 7 (Core) ejecutado con permisos de **Administrador Local**.
* **Identificación de Hardware:** Se deben conocer los nombres exactos de los adaptadores de red (ej. "Wi-Fi" y "Ethernet").
* **Estado del Servicio:** El servicio `SharedAccess` (ICS) no debe estar activo previamente o debe reiniciarse durante el proceso.

## 3. Procedimiento Técnico

La configuración de ICS mediante CLI en Windows requiere el uso de objetos COM (`HNetCfg.HNetShare`) para la gestión de redes y la manipulación del Registro de Windows para definir segmentos IP personalizados.

### 3.1. Ejecución del Script de Automatización

Este procedimiento se apoya en un script utilitario ("Helper") alojado en este repositorio para abstraer la complejidad de los objetos COM.

1. **Ubicación del Script:**
   El archivo fuente se encuentra en la ruta relativa de este directorio:
   👉 [**`./scripts/Enable-CustomICS.ps1`**](./scripts/Enable-CustomICS.ps1)

2. **Ejecución:**
   Abra una terminal de PowerShell como Administrador, navegue a la raíz del directorio Windows y ejecute:

```powershell
# Permitir ejecución de scripts para el proceso actual
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# Ejecutar el script helper
.\scripts\Enable-CustomICS.ps1
```

### 3.2. Auditoría del Código (Referencia)

A continuación se despliega el contenido del script para revisión de seguridad y lógica antes de su ejecución.

<details>
  <summary><strong>👁️ Ver código fuente de Enable-CustomICS.ps1</strong></summary>

<br>

```powershell
# ==========================================
# SOP-WIN-PS-01: Script de Configuración ICS
# Autor: OpsTeam
# Versión: 1.2
# ==========================================

# --- 1. BLOQUE INTERACTIVO Y VALIDACIÓN ---
Clear-Host
Write-Host "--- CONFIGURACIÓN DE INTERNET CONNECTION SHARING (ICS) ---" -ForegroundColor Cyan

Write-Host "`nAdaptadores disponibles en el sistema:" -ForegroundColor Yellow
Get-NetAdapter | Select-Object Name, Status, InterfaceDescription | Format-Table -AutoSize

$InputPublic = Read-Host "Nombre de la interfaz con INTERNET (WAN) [Default: Wi-Fi]"
if ([string]::IsNullOrWhiteSpace($InputPublic)) { $PublicAdapterName = "Wi-Fi" } else { $PublicAdapterName = $InputPublic }

$InputPrivate = Read-Host "Nombre de la interfaz para la LAN [Default: Ethernet]"
if ([string]::IsNullOrWhiteSpace($InputPrivate)) { $PrivateAdapterName = "Ethernet" } else { $PrivateAdapterName = $InputPrivate }

# --- 2. CONFIGURACIÓN DEL REGISTRO (IP FIJA) ---
$TargetIPAddress = "10.255.255.1"
$RegPath = "HKLM:\System\CurrentControlSet\Services\SharedAccess\Parameters"

try {
    Write-Host "`n[1/4] Configurando IP $TargetIPAddress en el Registro..."
    New-ItemProperty -Path $RegPath -Name "ScopeAddress" -Value $TargetIPAddress -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name "StandaloneDhcpAddress" -Value $TargetIPAddress -PropertyType String -Force | Out-Null
}
catch {
    Write-Error "Error modificando el registro. ¿Está ejecutando como Administrador?"
    Exit
}

# --- 3. CONFIGURACIÓN ICS (COM OBJECTS) ---
try {
    Write-Host "[2/4] Instanciando gestor de red (HNetCfg)..."
    $m = New-Object -ComObject HNetCfg.HNetShare
}
catch {
    Write-Error "No se pudo crear el objeto COM HNetCfg.HNetShare."
    Exit
}

# Obtener todas las conexiones (incluso desconectadas)
$connections = $m.EnumEveryConnection
$publicConfig = $null
$privateConfig = $null

foreach ($conn in $connections) {
    $props = $m.NetConnectionProps($conn)
    # Case insensitive check
    if ($props.Name -eq $PublicAdapterName) {
        $publicConfig = $m.INetSharingConfigurationForINetConnection($conn)
    }
    if ($props.Name -eq $PrivateAdapterName) {
        $privateConfig = $m.INetSharingConfigurationForINetConnection($conn)
    }
}

if (-not $publicConfig -or -not $privateConfig) {
    Write-Error "ERROR FATAL: No se encontraron los adaptadores '$PublicAdapterName' o '$PrivateAdapterName'."
    Write-Host "Verifique los nombres listados arriba." -ForegroundColor Red
    Exit
}

# --- 4. APLICAR CAMBIOS ---
Write-Host "[3/4] Reiniciando estado de compartición..."
try { $publicConfig.DisableSharing() } catch {}
try { $privateConfig.DisableSharing() } catch {}

Write-Host "[4/4] Habilitando ICS..."
# 0 = Public (WAN), 1 = Private (LAN)
try {
    $publicConfig.EnableSharing(0)
    $privateConfig.EnableSharing(1)
    Write-Host "      -> Gateway habilitado exitosamente en $PrivateAdapterName" -ForegroundColor Green
    Write-Host "      -> NAT habilitado a través de $PublicAdapterName" -ForegroundColor Green
}
catch {
    Write-Error "Hubo un error al activar ICS. Verifique el servicio SharedAccess."
    Write-Error $_.Exception.Message
}

Write-Host "`n--- CONFIGURACIÓN COMPLETADA ---" -ForegroundColor Cyan
```

</details>

---

## 4. Control de Calidad (Validación)

Una vez ejecutado el procedimiento, realizar las siguientes verificaciones en PowerShell para asegurar que el Gateway está operativo.

**A. Verificar IP en interfaz LAN**
La interfaz Ethernet debe haber tomado la IP del registro forzado.

```powershell
Get-NetIPAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4 | Select-Object IPAddress
# Resultado esperado: 10.255.255.1
```

**B. Verificar Estado del Servicio**
El servicio debe estar en ejecución para mantener el NAT.

```powershell
Get-Service SharedAccess
# Resultado esperado: Status: Running
```

---

## 5. Diagnóstico y Resolución

| Síntoma | Causa Probable | Resolución |
| :--- | :--- | :--- |
| **La IP LAN es `192.168.137.1`** | El registro de Windows se restableció o no se aplicó antes de iniciar ICS. | Detener ICS manualmente desde el panel de control o script, re-ejecutar las claves de registro (`ScopeAddress`) y volver a habilitar ICS. |
| **Error en script: `Access Denied`** | Falta de elevación de privilegios. | Cerrar la terminal y volver a abrir PowerShell haciendo clic derecho -> "Ejecutar como Administrador". |
| **Cliente sin internet** | El servicio DNS de Windows (ICS) falló o el cable está desconectado. | 1. Reiniciar el servicio `SharedAccess`.<br>2. Configurar DNS estático (8.8.8.8) en el cliente conectado.<br>3. Verificar link físico. |
| **Error COM Object Null** | Adaptador de red no encontrado. | Asegúrese de escribir el nombre del adaptador (ej. "Wi-Fi") exactamente como aparece en `Get-NetAdapter`. |
