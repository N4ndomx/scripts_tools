#!/bin/bash

# Función para imprimir mensaje en verde
print_success() {
    echo -e "\e[32m$1\e[0m"  # 32m representa verde, 0m resetea a color por defecto
}

# Función para imprimir mensaje en rojo
print_error() {
    echo -e "\e[31m$1\e[0m"  # 31m representa rojo, 0m resetea a color por defecto
}

# Función para imprimir mensaje y leer entrada del usuario
input() {
    echo -n "$1: "
    read $2
}

# Solicitar entrada para las variables
input "Nombre/ID del contenedor Docker" CONTAINER_NAME
input "Nombre de la base de datos PostgreSQL" DB_NAME
input "Usuario de PostgreSQL" DB_USER
input "Ruta de destino para el backup (opcional, por defecto '.') " BACKUP_PATH
input "Nombre del archivo de backup (opcional, por defecto 'database_${DB_NAME}_backup_$(date +%Y%m%d%H%M%S).sql')" BACKUP_FILE

# Verificar si se desea hacer backup solo de los datos
input "¿Desea hacer backup solo de los datos? (s/n)" DATA_ONLY
if [ "$DATA_ONLY" = "s" ]; then
    PG_DUMP_OPTIONS="-a"  # Opción para solo datos
else
    PG_DUMP_OPTIONS=""    # Vacío para backup completo
fi

# Si no se proporcionó un nombre de archivo de backup, asignar uno por defecto
if [ -z "$BACKUP_FILE" ]; then
    BACKUP_FILE="database_${DB_NAME}_backup_$(date +%Y%m%d%H%M%S).sql"
fi

# Si no se proporcionó una ruta de destino, usar el directorio actual
if [ -z "$BACKUP_PATH" ]; then
    BACKUP_PATH="."
fi

# Crear el backup
docker exec -t $CONTAINER_NAME pg_dump -U $DB_USER $PG_DUMP_OPTIONS $DB_NAME > "$BACKUP_PATH/$BACKUP_FILE"

# Verificar si el backup se creó correctamente
if [ $? -eq 0 ]; then
  print_success "Backup de la base de datos $DB_NAME creado exitosamente en $BACKUP_PATH/$BACKUP_FILE"
else
  print_error "Error al crear el backup de la base de datos $DB_NAME"
fi