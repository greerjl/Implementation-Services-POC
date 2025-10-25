# Use official lightweight Python base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install deps first (faster rebuilds)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app source
COPY app.py .

# Set environment defaults
ENV PORT=8080
EXPOSE 8080

# Run Flask app
CMD ["python", "app.py"]
