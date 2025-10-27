# Use official lightweight Python base
FROM python:3.11-slim

# Install curl for ECS healthcheck
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install deps first (faster rebuilds)
COPY requirements.txt .
RUN pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt \
 && opentelemetry-bootstrap -a install

# Copy app source
COPY app.py .

# Set environment defaults
ENV PORT=8080
EXPOSE 8080

# Run via the OTel launcher
CMD ["opentelemetry-instrument", \
     "--traces_exporter", "otlp", \
     "--metrics_exporter", "none", \
     "--service_name", "app-demo", \
     "python", "app.py"]
