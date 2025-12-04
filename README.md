# Ops Standards Library

![Status](https://img.shields.io/badge/status-active-success.svg)
![Classification](https://img.shields.io/badge/classification-Internal%20%2F%20Technical-blue)
![License](https://img.shields.io/badge/license-MIT-green)

Repositorio centralizado de **Procedimientos Operativos Estándar (SOPs)**, referencias técnicas y guías de arquitectura para el equipo de Operaciones e Infraestructura.

Este repositorio tiene como objetivo estandarizar los flujos de trabajo, garantizar la consistencia en los despliegues de *Infrastructure as Code (IaC)* y servir como fuente única de verdad para la configuración de entornos.

---

## 📂 Estructura del Repositorio

La documentación está organizada por dominios tecnológicos para facilitar la navegación y el mantenimiento.

| Directorio | Descripción | Tecnologías Principales |
| :--- | :--- | :--- |
| **`/linux`** | Procedimientos y estándares para sistemas basados en Unix/Linux. | Ubuntu, Debian, RHEL, Bash |
| **`/windows`** | Guías de administración y automatización para ecosistemas Microsoft. | Windows Server, PowerShell, WSL |
| **`/cloud`** | Arquitectura y gestión de proveedores de nube pública. | Azure, AWS, Google Cloud |

---

## 📚 Documentación Destacada

### Linux & Automation

* [**SOP-LINUX-ANS-01**](./linux/SOP-LINUX-ANS-01_setup-ansible-core.md) - Estandarización de Entorno de Desarrollo IaC (Ansible Core + Venv).

---

## 🚀 Uso y Contribución

Este repositorio sigue una política estricta de **"Docs as Code"**.
Todos los procedimientos aquí documentados han sido validados en entornos controlados.

1. **Consulta:** Navegue por las carpetas de dominio para encontrar el SOP requerido.
2. **Validación:** Verifique siempre la "Fecha de Revisión" dentro del documento antes de ejecutar comandos en producción.
3. **Issues:** Si encuentra un error en un procedimiento, por favor abra un *Issue* en este repositorio describiendo la discrepancia.

---

## ⚖️ Licencia

Este proyecto está licenciado bajo la Licencia MIT - vea el archivo [LICENSE](LICENSE) para más detalles.
