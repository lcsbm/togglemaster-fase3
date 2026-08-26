FROM python:3.11-alpine AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.11-alpine
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app.py .
RUN adduser -D -H -g "" appuser
USER appuser
EXPOSE 8002
CMD ["gunicorn", "--bind", "0.0.0.0:8002", "--workers", "2", "app:app"]
