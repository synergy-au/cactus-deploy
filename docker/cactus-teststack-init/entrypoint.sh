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

# Watchdog - blocks until file is created
echo "(2) cactus-envoy Setup"

if [ -z "$KICKOFF_FILE" ]; then
  echo "Error: KICKOFF_FILE environment variable not set."
  exit 1
fi

WATCHED_DIR=$(dirname "$KICKOFF_FILE")

# Ensure the directory exists
if [ ! -d "$WATCHED_DIR" ]; then
  echo "Error: Directory $WATCHED_DIR does not exist."
  exit 1
fi

echo "Blocking until $KICKOFF_FILE is found..."

while true; do
  inotifywait -e create --include $(basename $KICKOFF_FILE) "$WATCHED_DIR"

  echo "Detected $KICKOFF_FILE at $(date)"
  break

done
