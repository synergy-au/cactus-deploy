#!/bin/sh

# Wait for RabbitMQ to be ready
until nc -z localhost 5672; do
  echo "Waiting for RabbitMQ to become available..."
  sleep 2
done
echo "RabbitMQ is available, starting envoy..."

uvicorn $APP_MODULE --workers $WORKERS --log-config $LOG_CONFIG --host $HOST --port $PORT
