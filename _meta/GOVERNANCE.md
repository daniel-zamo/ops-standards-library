# ESTÁNDAR DE GOBERNANZA DOCUMENTAL Y NOMENCLATURA

- **ESTADO:** Borrador / Uso Interno
- **ÚLTIMA ACTUALIZACIÓN:** 2024-11-03
- **ALCANCE:** Editores y contribuidores del repositorio `ops-standards-library`.

---

## 1. PRINCIPIOS DE DISEÑO

Este repositorio sigue una filosofía de **"Docs as Code"** y estructura jerárquica agnóstica. El objetivo es mantener una base de conocimiento escalable que cumpla con principios básicos de organización alineados a normas de calidad y seguridad (como ISO 27001 para la clasificación de activos).

## 2. TAXONOMÍA JERÁRQUICA (NOMENCLATURA)

Todo archivo dentro de este repositorio debe seguir estrictamente la siguiente convención de nombres para garantizar su rápida identificación y ordenamiento automático.

**Sintaxis:**
`[TIPO]-[DOMINIO]-[HERRAMIENTA]-[ID]_[descripción-breve].md`

### A. [TIPO] - Categoría del Documento
Define el propósito y estructura de la información.

| Código | Significado | Definición |
| :--- | :--- | :--- |
| **SOP** | *Standard Operating Procedure* | Guía "paso a paso" imperativa para lograr un resultado específico. No admite ambigüedad. |
| **POL** | *Policy* | Normas, reglas o restricciones de cumplimiento obligatorio (ej. Política de contraseñas). |
| **REF** | *Reference* | Tablas, listas de puertos, direccionamiento IP, glosarios. Información estática de consulta. |
| **TSHOOT** | *Troubleshooting* | Guías de diagnóstico y solución de problemas (Causa -> Solución). |
| **ARCH** | *Architecture* | Diagramas de alto nivel, decisiones de diseño y topologías. |

### B. [DOMINIO] - Ámbito Tecnológico
Define el área macro de infraestructura. Permite el filtrado rápido por especialidad.

| Código | Ámbito | Ejemplos |
| :--- | :--- | :--- |
| **LINUX** | Sistemas Unix/Linux | Ubuntu, RHEL, Alpine, Bash scripting. |
| **WIN** | Ecosistema Microsoft | Windows Server, Active Directory, WSL. |
| **CLOUD** | Nube Pública | Azure, AWS, GCP (Infraestructura general). |
| **NET** | Networking | Switches, Firewalls, VPNs, DNS. |
| **SEC** | Seguridad | Certificados, Hacking Ético, Hardening. |
| **DEV** | Desarrollo | Git, CI/CD Pipelines, IDEs. |

### C. [HERRAMIENTA] - Tecnología Específica
Sub-clasificación para la herramienta concreta sobre la que trata el documento.

*   **ANS** (Ansible)
*   **DKR** (Docker / Containerd)
*   **K8S** (Kubernetes)
*   **PS** (PowerShell)
*   **AZ** (Azure CLI / Portal)
*   **AWS** (AWS CLI / Console)
*   **TF** (Terraform)
*   **GIT** (Git / GitHub / GitLab)

### D. [ID] - Serialización
Contador incremental de dos dígitos (`01`, `02`, `10`) para mantener el orden cronológico o lógico de creación dentro de una misma serie.

---

## 3. EJEMPLOS DE APLICACIÓN

**Caso 1: Guía para instalar Ansible en Linux (El documento actual)**
*   **Nombre:** `SOP-LINUX-ANS-01_setup-ansible-core.md`
*   *Desglose:* Es un procedimiento (SOP), sobre Linux (LINUX), usando Ansible (ANS), primer documento (01).

**Caso 2: Guía futura para configurar Azure CLI en Windows**
*   **Nombre:** `SOP-WIN-AZ-01_azure-cli-setup.md`

**Caso 3: Lista de puertos de Firewall requeridos**
*   **Nombre:** `REF-NET-FW-01_puertos-permitidos.md`

---

## 4. CLASIFICACIÓN DE LA INFORMACIÓN

Para alinearnos con buenas prácticas de Seguridad de la Información, cada documento debe incluir en su encabezado (Frontmatter) el nivel de clasificación:

*   **Público:** Información segura para divulgar fuera de la organización (Blogs, GitHub público).
*   **Interno / Técnico:** (Por defecto en este repo). Solo para el equipo de Operaciones. Puede contener IPs internas o nombres de host, pero **NUNCA** contraseñas ni claves privadas.
*   **Confidencial:** Contiene datos sensibles de clientes o negocio. **PROHIBIDO** subir a este repositorio público. Debe residir en bóvedas seguras (Bitwarden, Vault).

## 5. ESTRUCTURA DE DIRECTORIOS

El repositorio no se organiza por "Proyectos" (que son temporales), sino por **Tecnologías** (que son permanentes).

```text
/ (root)
├── _meta/          # Gobernanza, guías de estilo, plantillas.
├── linux/          # Todo lo relacionado con SO Linux.
├── windows/        # Todo lo relacionado con SO Windows.
├── cloud/          # Proveedores Cloud (Azure, AWS).
└── zz-drafts/      # Zona de trabajo sucio (no indexada en README).
