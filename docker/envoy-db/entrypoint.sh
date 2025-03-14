#!/bin/sh
set -e

echo "Starting db..."
docker-entrypoint.sh postgres &  # Start in background
DB_PID=$!  # Capture db's pid

echo "Waiting for db to be ready..."
until PGPASSWORD="$POSTGRES_PASSWORD" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" > /dev/null 2>&1; do
  sleep 1
done

echo "Running migrations..."
PGPASSWORD="$POSTGRES_PASSWORD" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /migrate.sql

echo "Migrations complete."
wait $DB_PID
