FROM timescale/timescaledb:latest-pg10

# Envoy migrations sql, tail it for current alembic revision
COPY ./migrate.sql /migrate.sql
COPY --chmod=+x entrypoint.sh /custom-entrypoint.sh

# Custom entrypoint to run migrations
ENTRYPOINT ["/custom-entrypoint.sh"]
