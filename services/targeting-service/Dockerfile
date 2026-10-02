FROM python:3.11-alpine AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.11-alpine
WORKDIR /app
RUN rm -rf /usr/local/lib/python3.11/site-packages/setuptools* \
           /usr/local/lib/python3.11/site-packages/pkg_resources
COPY --from=builder /install /usr/local
COPY app.py .
RUN adduser -D -H -g "" appuser
USER appuser
EXPOSE 8003
CMD ["gunicorn", "--bind", "0.0.0.0:8003", "--workers", "2", "app:app"]


