# --- CONFIGURACIÓN DE VARIABLES ---
# Ajustar estos nombres según el resultado de 'Get-NetAdapter'
$PublicAdapterName = "Wi-Fi"       # La interfaz que TIENE internet
$PrivateAdapterName = "Ethernet"   # La interfaz que COMPARTE internet (hacia Victus)

# Configuración de Red Deseada para la LAN interna
$TargetIPAddress = "10.255.255.1"
$TargetSubnetMask = "255.255.255.0"

Write-Host "--- Iniciando Configuración de ICS ---" -ForegroundColor Cyan

# 1. Modificar el Registro para forzar el rango IP deseado
# Windows usa por defecto 192.168.137.1. Cambiamos esto en SharedAccess.
$RegPath = "HKLM:\System\CurrentControlSet\Services\SharedAccess\Parameters"

try {
    Write-Host "Configurando rango IP en el Registro..."
    # ScopeAddress: La IP del Gateway (este equipo)
    New-ItemProperty -Path $RegPath -Name "ScopeAddress" -Value $TargetIPAddress -PropertyType String -Force | Out-Null
    # StandaloneDhcpAddress: La IP base para el servidor DHCP
    New-ItemProperty -Path $RegPath -Name "StandaloneDhcpAddress" -Value $TargetIPAddress -PropertyType String -Force | Out-Null
    
    Write-Host "Registro actualizado correctamente ($TargetIPAddress)." -ForegroundColor Green
}
catch {
    Write-Error "Error modificando el registro. Asegúrese de correr como Administrador."
    Break
}

# 2. Instanciar el Gestor de ICS (HNetCfg)
try {
    $m = New-Object -ComObject HNetCfg.HNetShare
}
catch {
    Write-Error "No se pudo crear el objeto COM HNetCfg.HNetShare."
    Break
}

# 3. Identificar conexiones
$c = $m.EnumEveryConnection | ? { $m.NetConnectionProps($_).Status -eq '2' } # Status 2 = Conectado

$publicConfig = $null
$privateConfig = $null

foreach ($conn in $c) {
    $props = $m.NetConnectionProps($conn)
    if ($props.Name -eq $PublicAdapterName) {
        $publicConfig = $m.INetSharingConfigurationForINetConnection($conn)
    }
    if ($props.Name -eq $PrivateAdapterName) {
        $privateConfig = $m.INetSharingConfigurationForINetConnection($conn)
    }
}

if (-not $publicConfig -or -not $privateConfig) {
    Write-Error "No se encontraron los adaptadores especificados: $PublicAdapterName o $PrivateAdapterName."
    Break
}

# 4. Deshabilitar ICS si ya estaba activo (para aplicar cambios de IP limpiamente)
Write-Host "Reiniciando configuraciones previas..."
$publicConfig.DisableSharing()
$privateConfig.DisableSharing()

# 5. Habilitar ICS
# 0 = Public, 1 = Private
Write-Host "Habilitando ICS en $PublicAdapterName (Público)..."
$publicConfig.EnableSharing(0)

Write-Host "Habilitando ICS en $PrivateAdapterName (Privado)..."
$privateConfig.EnableSharing(1)

Write-Host "--- Configuración Completada ---" -ForegroundColor Cyan
Write-Host "Por favor, reinicie el equipo o el servicio SharedAccess si la IP no cambia inmediatamente."
