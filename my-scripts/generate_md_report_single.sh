#!/bin/bash

# Configuración básica
OUTPUT="report.md"
INCLUDE=("md" "ps1")
EXCLUDE_DIRS=(".git" "zz-drafts")
EXCLUDE_FILES=("LICENSE")

# Generar estructura
echo "# Filesystem Report" > "$OUTPUT"
echo "Fecha: $(date)" >> "$OUTPUT"
echo -e "\n## Estructura\n" >> "$OUTPUT"
echo '```bash' >> "$OUTPUT"
tree -I '.git' 2>/dev/null || find . -type f | sort >> "$OUTPUT"
echo '```' >> "$OUTPUT"

# Buscar y procesar archivos
echo -e "\n## Contenido\n" >> "$OUTPUT"
find . -type f \( -name "*.md" -o -name "*.ps1" \) | while read file; do
    # Excluir directorios no deseados
    for excl_dir in "${EXCLUDE_DIRS[@]}"; do
        if [[ "$file" == *"/$excl_dir/"* ]]; then
            continue 2
        fi
    done
    
    # Excluir archivos no deseados
    filename=$(basename "$file")
    for excl_file in "${EXCLUDE_FILES[@]}"; do
        if [[ "$filename" == "$excl_file"* ]]; then
            continue 2
        fi
    done
    
    # Añadir al reporte
    echo "### $file" >> "$OUTPUT"
    echo '```' >> "$OUTPUT"
    cat "$file" >> "$OUTPUT"
    echo -e '\n```\n' >> "$OUTPUT"
done

echo "Reporte generado: $OUTPUT"
