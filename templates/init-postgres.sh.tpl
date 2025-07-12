#!/bin/bash

# Script de inicialización de PostgreSQL
# Se ejecuta automáticamente al crear el contenedor

set -e

# Variables de entorno disponibles:
# POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD

echo "=== Inicializando PostgreSQL con configuración personalizada ==="

# Crear usuario de aplicación
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Crear usuario de aplicación
    CREATE USER ${app_user} WITH PASSWORD '${app_password}';
    
    -- Otorgar permisos
    GRANT ALL PRIVILEGES ON DATABASE ${database_name} TO ${app_user};
    ALTER USER ${app_user} CREATEDB;
    
    -- Crear esquema para la aplicación
    CREATE SCHEMA IF NOT EXISTS app AUTHORIZATION ${app_user};
    
    -- Configurar search_path para el usuario
    ALTER USER ${app_user} SET search_path = app, public;
    
    -- Crear extensiones útiles
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    
    -- Información de la instalación
    SELECT 'PostgreSQL inicializado correctamente' as status;
    SELECT version() as postgres_version;
EOSQL

echo "=== Configuración de PostgreSQL completada ==="
echo "Base de datos: ${database_name}"
echo "Usuario administrador: postgres"
echo "Usuario de aplicación: ${app_user}"
