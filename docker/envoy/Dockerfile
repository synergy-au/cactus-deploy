FROM python:3.11-slim-bookworm

WORKDIR /app

# Deps
RUN apt update && apt install --no-install-recommends -y netcat-traditional git && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir git+https://git@github.com/bsgip/envoy.git@v0.12.1#egg=envoy python-json-logger uvicorn


# logging config
COPY logconf.json ./logconf.json
RUN mkdir logs

# configurables
ENV APP_MODULE="envoy.server.main:app"
ENV WORKERS=1
ENV LOG_CONFIG=logconf.json
ENV HOST=0.0.0.0
ENV PORT=8000

CMD ["sh", "-c", "uvicorn $APP_MODULE --workers $WORKERS --log-config $LOG_CONFIG --host $HOST --port $PORT"]
