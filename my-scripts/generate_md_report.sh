#!/bin/bash

# Script: generate_md_report.sh
# Descripción: Genera un reporte Markdown con estructura de directorios y contenido de archivos específicos
# Autor: Experto en Bash Scripting
# Fecha: $(date)

# Configuración personalizable
OUTPUT_FILE="filesystem_report.md"
INCLUDE_EXTENSIONS=("md" "ps1")      # Extensiones a incluir en el reporte
EXCLUDE_NAMES=("LICENSE")            # Nombres de archivos a excluir (sin extensión)
EXCLUDE_DIRS=(".git" "zz-drafts" "my-scripts")    # Directorios a excluir completamente
EXCLUDE_EXTENSIONS=()                # Extensiones adicionales a excluir (vacío por defecto)

# Colores para output (opcional)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
show_help() {
    cat << EOF
Uso: $(basename "$0") [OPCIONES]

Genera un reporte Markdown con la estructura del filesystem y contenido de archivos.

Opciones:
  -h, --help              Muestra esta ayuda
  -o, --output FILE       Especifica archivo de salida (por defecto: $OUTPUT_FILE)
  -i, --include EXTS      Extensiones a incluir separadas por comas (ej: md,ps1,txt)
  -e, --exclude NAMES     Nombres de archivos a excluir separados por comas
  -d, --exclude-dirs DIRS Directorios a excluir separados por comas
  -x, --exclude-exts EXTS Extensiones a excluir separadas por comas
  --no-color              Deshabilitar colores en la salida
  -v, --verbose           Modo verbose

Ejemplos:
  $(basename "$0")                      # Usa configuraciones por defecto
  $(basename "$0") -o informe.md        # Especifica archivo de salida
  $(basename "$0") -i "md,ps1,sh"       # Incluye múltiples extensiones
  $(basename "$0") -e "LICENSE,README"  # Excluye archivos específicos
  $(basename "$0") -d "temp,backup"     # Excluye directorios adicionales
  $(basename "$0") -x "log,tmp"         # Excluye extensiones específicas

Configuración actual:
  Salida: $OUTPUT_FILE
  Extensiones incluidas: ${INCLUDE_EXTENSIONS[*]}
  Nombres excluidos: ${EXCLUDE_NAMES[*]}
  Directorios excluidos: ${EXCLUDE_DIRS[*]}
  Extensiones excluidas: ${EXCLUDE_EXTENSIONS[*]}
EOF
}

# Función para mostrar mensajes verbose
verbose_echo() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${YELLOW}[VERBOSE]${NC} $1"
    fi
}

# Función para mostrar errores
error_echo() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Función para mostrar éxito
success_echo() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# Función para verificar si un elemento debe ser excluido
should_exclude() {
    local item="$1"
    local item_type="$2"  # "file" o "dir"
    
    # Verificar si es un directorio excluido
    if [[ "$item_type" == "dir" ]]; then
        for exclude_dir in "${EXCLUDE_DIRS[@]}"; do
            if [[ "$item" == "$exclude_dir" ]] || [[ "$item" == "./$exclude_dir" ]] || [[ "$item" == */$exclude_dir ]] || [[ "$item" == */$exclude_dir/* ]]; then
                verbose_echo "Excluyendo directorio: $item"
                return 0
            fi
        done
        return 1
    fi
    
    # Verificar si es un archivo excluido
    local filename=$(basename "$item")
    local name_without_ext="${filename%.*}"
    local extension="${filename##*.}"
    
    # Excluir por nombre (sin extensión)
    for exclude_name in "${EXCLUDE_NAMES[@]}"; do
        if [[ "$name_without_ext" == "$exclude_name" ]]; then
            verbose_echo "Excluyendo por nombre: $item"
            return 0
        fi
    done
    
    # Excluir por extensión específica
    for exclude_ext in "${EXCLUDE_EXTENSIONS[@]}"; do
        if [[ "$extension" == "$exclude_ext" ]]; then
            verbose_echo "Excluyendo por extensión: $item"
            return 0
        fi
    done
    
    # Incluir solo extensiones específicas
    local include_match=false
    for include_ext in "${INCLUDE_EXTENSIONS[@]}"; do
        if [[ "$extension" == "$include_ext" ]]; then
            include_match=true
            break
        fi
    done
    
    if [[ "$include_match" == "false" ]]; then
        verbose_echo "Excluyendo por extensión no incluida: $item"
        return 0
    fi
    
    return 1
}

# Parsear argumentos de línea de comandos
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -i|--include)
            IFS=',' read -r -a INCLUDE_EXTENSIONS <<< "$2"
            shift 2
            ;;
        -e|--exclude)
            IFS=',' read -r -a EXCLUDE_NAMES <<< "$2"
            shift 2
            ;;
        -d|--exclude-dirs)
            IFS=',' read -r -a EXCLUDE_DIRS <<< "$2"
            shift 2
            ;;
        -x|--exclude-exts)
            IFS=',' read -r -a EXCLUDE_EXTENSIONS <<< "$2"
            shift 2
            ;;
        --no-color)
            RED=''
            GREEN=''
            YELLOW=''
            NC=''
            shift
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        *)
            error_echo "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Verificar si tree está instalado
if ! command -v tree &> /dev/null; then
    echo -e "${YELLOW}[ADVERTENCIA]${NC} El comando 'tree' no está instalado. Intentando usar alternativa..."
    
    # Función alternativa para generar estructura de directorios
    generate_tree_alternative() {
        local indent="$1"
        local dir="$2"
        
        for item in "$dir"/*; do
            # Obtener nombre base
            local base=$(basename "$item")
            
            # Saltar si está vacío
            [[ -e "$item" ]] || continue
            
            # Excluir directorios no deseados
            if [[ -d "$item" ]]; then
                if should_exclude "$item" "dir"; then
                    continue
                fi
                echo "${indent}├── $base/"
                generate_tree_alternative "$indent│   " "$item"
            else
                # Para archivos, verificar si deben ser excluidos
                if should_exclude "$item" "file"; then
                    continue
                fi
                echo "${indent}├── $base"
            fi
        done
    }
    
    TREE_CMD="generate_tree_alternative"
else
    TREE_CMD="tree"
fi

# Crear patrón de exclusión para tree
TREE_EXCLUDE_PATTERN=$(IFS='|'; echo "${EXCLUDE_DIRS[*]}")
if [[ -n "$TREE_EXCLUDE_PATTERN" ]]; then
    TREE_ARGS="-I '$TREE_EXCLUDE_PATTERN|.*'"
else
    TREE_ARGS="-I '.*'"
fi

# Crear el archivo de reporte
echo "Generando reporte en: $OUTPUT_FILE"

# Encabezado del reporte
cat > "$OUTPUT_FILE" << EOF
# Contenido de Archivos del \$PWD = \`$(pwd)\`

Fecha de generación: $(date)

## Estructura del filesystem

\`\`\`bash
$(whoami)@$(hostname):$(pwd)$ $TREE_CMD
EOF

# Añadir estructura de directorios
if [[ "$TREE_CMD" == "tree" ]]; then
    # Usar tree si está disponible
    eval "tree $TREE_ARGS" >> "$OUTPUT_FILE" 2>/dev/null || echo "Error al ejecutar tree. La estructura puede estar incompleta." >> "$OUTPUT_FILE"
else
    # Usar alternativa personalizada
    echo "." >> "$OUTPUT_FILE"
    generate_tree_alternative "" "." >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" << EOF
\`\`\`

## Contenido de archivos

EOF

# Buscar y procesar archivos
verbose_echo "Buscando archivos con extensiones: ${INCLUDE_EXTENSIONS[*]}"
verbose_echo "Excluyendo directorios: ${EXCLUDE_DIRS[*]}"
verbose_echo "Excluyendo nombres: ${EXCLUDE_NAMES[*]}"

# Contador de archivos procesados
file_count=0
skipped_count=0

# Función para buscar archivos recursivamente
find_and_process_files() {
    local dir="$1"
    
    # Leer elementos del directorio
    for item in "$dir"/*; do
        [[ -e "$item" ]] || continue
        
        # Si es directorio, procesar recursivamente
        if [[ -d "$item" ]]; then
            local dirname=$(basename "$item")
            
            # Verificar si el directorio debe ser excluido
            if should_exclude "$item" "dir"; then
                verbose_echo "Saltando directorio excluido: $item"
                ((skipped_count++))
                continue
            fi
            
            # Llamada recursiva
            find_and_process_files "$item"
            
        # Si es archivo, procesarlo
        elif [[ -f "$item" ]]; then
            # Verificar si el archivo debe ser excluido
            if should_exclude "$item" "file"; then
                ((skipped_count++))
                continue
            fi
            
            # Procesar archivo
            process_file "$item"
        fi
    done
}

# Función para procesar un archivo individual
process_file() {
    local file="$1"
    local relative_path="${file#./}"
    
    ((file_count++))
    verbose_echo "Procesando archivo $file_count: $relative_path"
    
    cat >> "$OUTPUT_FILE" << EOF
## Contenido archivo: \`$relative_path\`

\`\`\`bash
\$ cat $relative_path
$(cat "$file" 2>/dev/null || echo "# Error al leer el archivo")
\`\`\`

EOF
}

# Iniciar búsqueda desde el directorio actual
find_and_process_files "."

# Si no se encontraron archivos, añadir mensaje
if [[ $file_count -eq 0 ]]; then
    cat >> "$OUTPUT_FILE" << EOF
No se encontraron archivos con las extensiones especificadas.

Extensiones buscadas: ${INCLUDE_EXTENSIONS[*]}
Directorios excluidos: ${EXCLUDE_DIRS[*]}
Archivos excluidos: ${EXCLUDE_NAMES[*]}
EOF
fi

# Resumen final
cat >> "$OUTPUT_FILE" << EOF

---
*Reporte generado automáticamente por $(basename "$0")*
*Archivos procesados: $file_count*
*Archivos excluidos: $skipped_count*
*Extensiones incluidas: ${INCLUDE_EXTENSIONS[*]}*
EOF

success_echo "Reporte generado exitosamente en: $OUTPUT_FILE"
success_echo "Archivos procesados: $file_count"
success_echo "Archivos excluidos: $skipped_count"

# Mostrar ubicación del archivo
echo "Puedes visualizar el reporte con:"
echo "  cat $OUTPUT_FILE | less"
echo "  o abrirlo con tu editor favorito"
