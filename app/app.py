from flask import Flask
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
import os

app = Flask(__name__)

# OTel setup
service_name = "app-demo"
environment = os.getenv("ENVIRONMENT", "dev")
resource = Resource.create({
    "service.name": service_name,
    "deployment.environment": environment,
})
provider = TracerProvider(resource=resource)
exporter = OTLPSpanExporter(endpoint="http://localhost:4317", insecure=True)
provider.add_span_processor(BatchSpanProcessor(exporter))
trace.set_tracer_provider(provider)

FlaskInstrumentor().instrument_app(app)

@app.get("/health")
def health():
    return "ok", 200

# existing routes...

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
