#!/bin/bash

# Wait for DB and run migrations
echo "(1) cactus-envoy-db Setup"
if [ -z "$ENVOY_DATABASE_URL" ]; then
  echo "Error: ENVOY_DATABASE_URL environment variable not set."
  exit 1
fi

echo "Waiting for db to be ready..."
until psql ${ENVOY_DATABASE_URL} -c "SELECT 1;" >/dev/null 2>&1; do
  sleep 1
done

echo "Running migrations..."
psql ${ENVOY_DATABASE_URL} -f /migrate.sql

echo "End of teststack-init"