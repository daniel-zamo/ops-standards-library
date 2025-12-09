# ==========================================
# Script de Restauración (Rollback)
# Objetivo: Desactivar ICS y limpiar Registro
# ==========================================

Write-Host "--- INICIANDO RESTAURACIÓN DE RED ---" -ForegroundColor Yellow

# 1. Desactivar ICS (Internet Connection Sharing)
try {
    $m = New-Object -ComObject HNetCfg.HNetShare
    $connections = $m.EnumEveryConnection
    
    foreach ($conn in $connections) {
        $config = $m.INetSharingConfigurationForINetConnection($conn)
        $props = $m.NetConnectionProps($conn)
        
        # Intentar desactivar en todas las interfaces por seguridad
        try {
            $config.DisableSharing()
            Write-Host "ICS desactivado en: $($props.Name)" -ForegroundColor Green
        } catch {
            # Si no estaba compartido, dará error, lo ignoramos
        }
    }
} catch {
    Write-Error "Error accediendo al objeto HNetCfg. Asegúrese de ser Admin."
}

# 2. Limpiar el Registro (Borrar ScopeAddress y StandaloneDhcpAddress)
$RegPath = "HKLM:\System\CurrentControlSet\Services\SharedAccess\Parameters"

try {
    Write-Host "Limpiando claves del Registro..."
    Remove-ItemProperty -Path $RegPath -Name "ScopeAddress" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $RegPath -Name "StandaloneDhcpAddress" -ErrorAction SilentlyContinue
    Write-Host "Claves de registro eliminadas (Rango 10.255.x eliminado)." -ForegroundColor Green
} catch {
    Write-Host "No se pudieron borrar las claves o ya no existían." -ForegroundColor Gray
}

# 3. Reiniciar el servicio para aplicar limpieza
Write-Host "Reiniciando servicio SharedAccess..."
Restart-Service SharedAccess -Force

Write-Host "--- LISTO ---" -ForegroundColor Cyan
