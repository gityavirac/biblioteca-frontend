#!/bin/bash

# Script para exportar base de datos desde Supabase
# Reemplaza TU_CONNECTION_STRING con la URL de tu Supabase

echo "🔄 Exportando base de datos desde Supabase..."

# PASO 1: Reemplaza esta línea con tu connection string de Supabase
SUPABASE_URL="postgresql://postgres:[TU_PASSWORD]@db.[TU_PROJECT_REF].supabase.co:5432/postgres"

# PASO 2: Exportar solo las tablas públicas (sin auth ni storage de Supabase)
pg_dump "$SUPABASE_URL" \
  --schema=public \
  --no-owner \
  --no-privileges \
  --clean \
  --if-exists \
  --exclude-table=public.schema_migrations \
  --exclude-table=public.supabase_functions_migrations \
  -f biblioteca_export.sql

echo "✅ Exportación completada: biblioteca_export.sql"
echo ""
echo "📋 Próximos pasos:"
echo "1. Revisa el archivo biblioteca_export.sql"
echo "2. Ejecuta: psql -h TU_NUEVO_SERVIDOR -U TU_USUARIO -d TU_BASE -f biblioteca_export.sql"