#!/bin/bash

# Aquí-doc para el banner
cat << 'BANNER'
      ____           _   ____ __            __                    
     / __ )__  __   / | / / // / ____  ____/ /___  ____ ___  _  __
    / __  / / / /  /  |/ / // /_/ __ \/ __  / __ \/ __ `__ \| |/_/
   / /_/ / /_/ /  / /|  /__  __/ / / / /_/ / /_/ / / / / / />  <  
  /_____/\__, /  /_/ |_/  /_/ /_/ /_/\__,_/\____/_/ /_/ /_/_/|_|  
        /____/                                                    
BANNER

# Función para imprimir mensaje en verde
print_success() {
    echo -e "\e[32m$1\e[0m"  # 32m representa verde, 0m resetea a color por defecto
}

# Función para imprimir mensaje en rojo
print_error() {
    echo -e "\e[31m$1\e[0m"  # 31m representa rojo, 0m resetea a color por defecto
}

# Función para imprimir mensaje en azul
print_info() {
    echo -e "\e[34m$1\e[0m"  # 34m representa azul, 0m resetea a color por defecto
}

# Función para imprimir mensaje y leer entrada del usuario
input() {
    echo -n "$1: "
    read $2
}

# Función para realizar backup de la base de datos
perform_backup() {
    echo
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    print_info "                 BACKUP DE BASE DE DATOS           "
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo

    input "Nombre/ID del contenedor Docker " CONTAINER_BACKUP_NAME
    input "Nombre de la base de datos PostgreSQL " DB_BACKUP_NAME
    input "Usuario de PostgreSQL " DB_BACKUP_USER
    input "Ruta de destino para el backup (opcional, por defecto '.') " BACKUP_PATH
    input "Nombre del archivo de backup (opcional, por defecto 'database_${DB_BACKUP_NAME}_backup_$(date +%Y%m%d%H%M%S).sql')" BACKUP_FILE
    input "¿Desea hacer backup solo de los datos? (s/n)" DATA_ONLY

    # Realizar el backup
    perform_backup_logic "$CONTAINER_BACKUP_NAME" "$DB_BACKUP_USER" "$DB_BACKUP_NAME" "$BACKUP_PATH" "$BACKUP_FILE" "$DATA_ONLY"
}

# Función para realizar la lógica de backup
perform_backup_logic() {
    local CONTAINER_NAME="$1"
    local DB_USER="$2"
    local DB_NAME="$3"
    local BACKUP_PATH="$4"
    local BACKUP_FILE="$5"
    local DATA_ONLY="$6"

    # Verificar si se desea hacer backup solo de los datos
    if [ "$DATA_ONLY" = "s" ]; then
        PG_DUMP_OPTIONS="-a"  # Opción para solo datos
    else
        PG_DUMP_OPTIONS=""    # Vacío para backup completo
    fi

    # Si no se proporcionó un nombre de archivo de backup, asignar uno por defecto
    if [ -z "$BACKUP_FILE" ]; then
        BACKUP_FILE="database_backup_${DB_BACKUP_NAME}_$(date +%Y%m%d%H%M%S).sql"
    fi

    # Si no se proporcionó una ruta de destino, usar el directorio actual
    if [ -z "$BACKUP_PATH" ]; then
        BACKUP_PATH="."
    fi

    # Crear el backup
    docker exec -t "$CONTAINER_BACKUP_NAME" pg_dump -U "$DB_BACKUP_USER" $PG_DUMP_OPTIONS "$DB_BACKUP_NAME" > "$BACKUP_PATH/$BACKUP_FILE"

    # Verificar si el backup se creó correctamente
    if [ $? -eq 0 ]; then
        print_success "Backup de la base de datos $DB_BACKUP_NAME creado exitosamente en $BACKUP_PATH/$BACKUP_FILE"
    else
        print_error "Error al crear el backup de la base de datos $DB_BACKUP_NAME"
    fi
    read -p "Presione Enter para continuar..."
    echo
}

# Función para restaurar la base de datos desde un archivo SQL
restore_database() {
    echo
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    print_info "            RESTAURAR BASE DE DATOS POSTGRES       "
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo

    input "Nombre/ID del contenedor Docker " CONTAINER_RESTORE_NAME
    input "Nombre de la base de datos PostgreSQL " DB_RESTORE_NAME
    input "Usuario de PostgreSQL " DB_RESTORE_USER
    input "Ruta completa al archivo de backup SQL  " RESTORE_FILE

    # Restaurar la base de datos
    restore_database_logic "$CONTAINER_RESTORE_NAME" "$DB_RESTORE_USER" "$DB_RESTORE_NAME" "$RESTORE_FILE"
}

# Función para realizar la lógica de restauración
restore_database_logic() {
    local CONTAINER_NAME="$1"
    local DB_USER="$2"
    local DB_NAME="$3"
    local RESTORE_FILE="$4"

    # Verificar si el contenedor está corriendo
    local IS_RUNNING=$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)
    if [ "$IS_RUNNING" != "true" ]; then
        print_error "El contenedor $CONTAINER_NAME no está corriendo."
        return 1
    fi

    # Verificar si el archivo de restore existe
    if [ ! -f "$RESTORE_FILE" ]; then
        print_error "El archivo de restore '$RESTORE_FILE' no existe."
        return 1
    fi

    # Restaurar la base de datos
    docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" < "$RESTORE_FILE"

    # Verificar si la restauración fue exitosa
    if [ $? -eq 0 ]; then
        print_success "Ejecucion exitosa de restauracion de Base de datos $DB_NAME desde $RESTORE_FILE en contenedor $CONTAINER_NAME."
        print_info "Revisar consola para ver el estado de la restauracion..."

    else
        print_error "Error al restaurar la base de datos $DB_NAME desde $RESTORE_FILE en contenedor $CONTAINER_NAME."
    fi
    read -p "Presione Enter para continuar..."
    echo
}

# Función para mostrar el menú principal
main_menu() {
    print_info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    echo ">> Herramienta PostgreSQL"
    echo "1. Realizar Backup"
    echo "2. Restaurar desde Archivo SQL "
    echo "3. Salir"
    echo
}

# Loop principal del programa
while true; do
    main_menu

    read -p "Ingrese el número de la opción deseada : " OPTION

    case $OPTION in
        1)
            perform_backup
            ;;
        2)
            restore_database
            ;;
        3)
            print_info "Saliendo ..."
            exit 0
            ;;
        *)
            print_error "Opción no válida..."
            ;;
    esac
done
