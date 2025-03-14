FROM tiangolo/uvicorn-gunicorn-fastapi:python3.11-slim

# Install envoy
RUN pip install --no-cache-dir git+ssh://git@github.com/bsgip/envoy.git@v0.12.1#egg=envoy

# Setup execution environment
ENV DATABASE_URL="postgresql+asyncpg://envoyuser:envoyuser@localhost:5432/envoy"
ENV CERT_PEM_HEADER="x-forwarded-client-cert"
ENV DEFAULT_TIMEZONE="Australia/Brisbane"
ENV APP_MODULE="envoy.server.main:app"
