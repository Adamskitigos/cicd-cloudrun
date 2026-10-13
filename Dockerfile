# ---- Étape 1 : installation des dépendances ----
FROM python:3.12-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---- Étape 2 : image finale légère ----
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080
WORKDIR /srv
COPY --from=builder /install /usr/local
COPY app/ ./app/

# Utilisateur non-root
RUN useradd --create-home appuser
USER appuser

EXPOSE 8080
CMD exec gunicorn --bind :$PORT --workers 2 --threads 4 --timeout 0 app.main:app
