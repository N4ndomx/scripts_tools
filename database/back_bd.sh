#!/bin/bash

# Variables
CONTAINER_NAME="31065a6c386fc675e2629b3f0e8aaad72788afac0468db32514013e23ebf023c"
DB_NAME="devsw"
DB_USER="postgres"
BACKUP_PATH="."
BACKUP_FILE="database_backup_$(date +%Y%m%d%H%M%S).sql"

# Crear el backup
docker exec -t $CONTAINER_NAME pg_dump -U $DB_USER $DB_NAME > $BACKUP_PATH/$BACKUP_FILE

# Verificar si el backup se creó correctamente
if [ $? -eq 0 ]; then
  echo "Backup de la base de datos $DB_NAME creado exitosamente en $BACKUP_PATH/$BACKUP_FILE"
else
  echo "Error al crear el backup de la base de datos $DB_NAME"
  echo "docker exec -i my_postgres_container psql -U postgres_user -d my_database < /path/to/backup/my_database_backup.sql"
fi
