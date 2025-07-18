# BUILD stage
FROM python:3.12-slim AS build
ARG CACTUS_RUNNER_VERSION

RUN apt-get update; apt-get install -y git openssh-client

# Setup the git config to use https
RUN git config --global url."https://git@github.com/".insteadOf "ssh://git@github.com/"

# Install app / dependencies
RUN pip install --no-cache-dir "git+ssh://git@github.com/synergy-au/cactus-runner.git@${CACTUS_RUNNER_VERSION}" gunicorn

# RUN stage
FROM  python:3.12-slim

# This postgresql-client version must align with the postgres version in the k8s pod
RUN apt update && apt install --no-install-recommends -y postgresql-client-15 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN mkdir -p config/logging
RUN mkdir /shared
COPY ./logconf.json /app/config/logging/config.json

# Copy env
COPY --from=build --chown=appuser:appuser /usr/local/lib/  /usr/local/lib/
COPY --from=build --chown=appuser:appuser /usr/local/bin/  /usr/local/bin/

# conf
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV APP_HOST='0.0.0.0'
ENV APP_PORT='8080'

# run app
CMD ["sh", "-c", "exec gunicorn cactus_runner.app.main:app --bind ${APP_HOST}:${APP_PORT} --worker-class aiohttp.GunicornWebWorker"]

