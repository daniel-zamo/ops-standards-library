# GUÍA DE CONTRIBUCIÓN Y GESTIÓN DE ARTEFACTOS DE CÓDIGO

**ESTADO:** Activo / Normativo  
**ÚLTIMA ACTUALIZACIÓN:** 2025-12-09  
**OBJETIVO:** Definir el criterio de separación entre documentación y código automatizado.

---

## 1. PRINCIPIO DE LOCALIDAD DEL CÓDIGO

En el equipo de Operaciones, a menudo surge la duda: *"¿Debo subir este script a este repositorio de SOPs o crear uno nuevo?"*.

Para evitar la proliferación innecesaria de repositorios (*Repo Sprawl*), aplicamos la siguiente **Matriz de Decisión**:

### A. Cuándo incluir el código AQUÍ (In-Repo)

El código debe residir dentro de `ops-standards-library` si cumple las siguientes condiciones:

1. **Es un "Helper" o Utilitario:** Su única función es facilitar la ejecución de un paso descrito en un SOP.
2. **Es Atómico:** Es un único archivo (ej. `.ps1`, `.sh`, `.py`) o un conjunto muy pequeño que no requiere compilación.
3. **Sin Ciclo de Vida Complejo:** No requiere tests unitarios, CI/CD pipelines propios, ni versionado semántico independiente (v1.0, v2.0).
4. **Contexto Específico:** No tiene sentido ejecutarlo fuera del contexto del procedimiento que lo acompaña.

**Ejemplos válidos:**

* Script para configurar IPs estáticas en Windows (`Enable-CustomICS.ps1`).
* Script de limpieza de logs para un servidor Linux.
* Plantilla JSON pequeña de configuración.

### B. Cuándo crear un REPOSITORIO EXTERNO

El código debe tener su propio repositorio (`git init`) si:

1. **Es un "Producto" o "Plataforma":** Es un entorno de trabajo completo (ej. Entorno Ansible, Módulo de Terraform).
2. **Requiere Construcción:** Necesita un `Makefile`, `Dockerfile`, `requirements.txt` o compilación.
3. **Reutilizable:** Está diseñado para ser clonado y usado como base para múltiples proyectos distintos.
4. **Tiene Ciclo de Vida Propio:** Requiere control de versiones estricto, Issues propios y Pull Requests complejos.

**Ejemplos:**

* `ops-ansible-core` (Entorno base de Ansible).
* `ops-terraform-modules` (Librería de módulos).
* Una API REST en Python para monitoreo.

---

## 2. ESTRUCTURA DE ALMACENAMIENTO

Si el código califica para quedarse en este repositorio (Caso A), debe organizarse de la siguiente manera para mantener el orden:

```text
/ (root)
├── [dominio] /           # ej. windows, linux, cloud
│   ├── scripts /         # CARPETA OBLIGATORIA PARA CÓDIGO
│   │   ├── Helper-Script-01.ps1
│   │   └── Utility-Tool.sh
│   └── SOP-DOMINIO-XX.md
```

> **⛔ PROHIBIDO:** Dejar scripts sueltos en la raíz del dominio o mezclados con los archivos `.md` sin una subcarpeta `/scripts`.

---

## 3. ESTÁNDAR DE DOCUMENTACIÓN DE SCRIPTS

Cuando un SOP hace uso de un script alojado en este repositorio, el documento Markdown debe cumplir con el **Patrón de Doble Referencia**:

### 1. Enlace de Descarga (Operatividad)

Debe existir un enlace directo al archivo físico. Esto permite al operador hacer `wget`, `curl` o guardar el archivo sin errores de formato.

> *Ejemplo:*  
> "Descargue el script desde la ruta: [**`./scripts/MiScript.ps1`**](./scripts/MiScript.ps1)"

### 2. Bloque de Auditoría (Seguridad)

Se debe incluir el contenido del script (o su parte crítica) dentro de un bloque desplegable `<details>`. Esto permite validar qué hace el código sin necesidad de abrir el archivo, agilizando la revisión de seguridad.

> *Sintaxis Markdown requerida:*

```markdown
<details>
  <summary><strong>👁️ Ver código fuente (Auditoría)</strong></summary>

\```powershell
# Pegar aquí el contenido del script
Write-Host "Hola Mundo"
\```
</details>
```

---

## 4. SEGURIDAD EN SCRIPTS (HARDCODING)

Cualquier script subido a este repositorio (`ops-standards-library`) tiene clasificación **INTERNA**.

* **⛔ ESTRICTAMENTE PROHIBIDO:** Incluir contraseñas, tokens de API, claves privadas SSH o cadenas de conexión a base de datos dentro de los scripts en `/scripts`.
* **✅ CORRECTO:** Usar parámetros de entrada (`$Password = Read-Host`) o variables de entorno.

Si un script requiere credenciales fijas, **NO** pertenece a este repositorio.
