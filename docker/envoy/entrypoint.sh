#!/bin/sh

if [ -n "${RABBIT_MQ_BROKER_URL}" ]; then
    echo "Notifications are enabled. RABBIT_MQ_BROKER_URL has been set."

    # Extract hostname/port from rabbit mq connection string
    REMOVED_CREDS="${RABBIT_MQ_BROKER_URL#*@}"
    HOST_WITH_PORT="${REMOVED_CREDS%%/*}"
    HOST_WITH_PORT="${HOST_WITH_PORT:=localhost}"

    if [[ "$HOST_WITH_PORT" == *:* ]]; then
      RABBIT_MQ_HOST="${HOST_WITH_PORT%%:*}"
      RABBIT_MQ_PORT="${HOST_WITH_PORT#*:}"
      RABBIT_MQ_PORT="${RABBIT_MQ_PORT:=5672}"
    else
      RABBIT_MQ_HOST="$HOST_WITH_PORT"
      RABBIT_MQ_PORT=5672
    fi

    # Wait for RabbitMQ to be ready
    until nc -z $RABBIT_MQ_HOST $RABBIT_MQ_PORT; do
      echo "Waiting for RabbitMQ @ '${RABBIT_MQ_HOST}:${RABBIT_MQ_PORT}' to become available..."
      sleep 2
    done
    echo "RabbitMQ @ '${RABBIT_MQ_HOST}:${RABBIT_MQ_PORT}' is available, starting envoy..."
else
    echo "RABBIT_MQ_BROKER_URL has not been specified. Skipping wait."
fi

exec uvicorn $APP_MODULE --workers $WORKERS --log-config $LOG_CONFIG --host $HOST --port $PORT
