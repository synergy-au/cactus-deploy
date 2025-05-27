FROM alpine:latest

RUN apk add --no-cache inotify-tools bash postgresql-client

# Envoy migrations sql, tail it for current alembic revision
COPY ./envoy-db-migrate.sql /migrate.sql

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
