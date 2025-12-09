## Características principales del script generate_md_report.sh

1. **Configuración flexible**: Puedes modificar fácilmente qué extensiones incluir, qué archivos/directorios excluir.

2. **Uso avanzado**:

   ```bash
   # Ejemplos de uso:
   ./generate_md_report.sh
   ./generate_md_report.sh -o "mi_reporte.md"
   ./generate_md_report.sh -i "md,ps1,sh,txt" -e "README,LICENSE"
   ./generate_md_report.sh -d "temp,backup,test" -v
   ```

3. **Características incluidas**:
   - Exclusión inteligente de directorios (`.git`, `zz-drafts`)
   - Inclusión/exclusión por extensión
   - Exclusión por nombre de archivo
   - Modo verbose para depuración
   - Alternativa si `tree` no está instalado
   - Manejo de errores
   - Output colorido (opcional)

4. **Formato de salida**: Genera un archivo Markdown bien formateado que puede visualizarse directamente en GitHub o cualquier visor Markdown.

El script es modular y fácil de extender para incluir más funcionalidades según sea necesario.
