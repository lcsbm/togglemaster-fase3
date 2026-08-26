FROM python:3.11-slim AS builder
# trigger ci
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app.py .
RUN adduser --disabled-password --no-create-home --gecos "" appuser
USER appuser
EXPOSE 8002
CMD ["gunicorn", "--bind", "0.0.0.0:8002", "--workers", "2", "app:app"]
