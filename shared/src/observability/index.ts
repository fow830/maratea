import { JaegerExporter } from '@opentelemetry/exporter-jaeger';
import { FastifyInstrumentation } from '@opentelemetry/instrumentation-fastify';
import { HttpInstrumentation } from '@opentelemetry/instrumentation-http';
import { Resource } from '@opentelemetry/resources';
import { NodeSDK } from '@opentelemetry/sdk-node';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

let sdk: NodeSDK | null = null;

export function initializeOpenTelemetry(serviceName: string): void {
  if (sdk) {
    return; // Already initialized
  }

  const jaegerExporter = new JaegerExporter({
    endpoint: process.env.JAEGER_ENDPOINT || 'http://localhost:14268/api/traces',
  });

  sdk = new NodeSDK({
    resource: new Resource({
      [SemanticResourceAttributes.SERVICE_NAME]: serviceName,
      [SemanticResourceAttributes.SERVICE_VERSION]: process.env.SERVICE_VERSION || '1.0.0',
    }),
    traceExporter: jaegerExporter,
    instrumentations: [new HttpInstrumentation(), new FastifyInstrumentation()],
  });

  sdk.start();
  console.log(`OpenTelemetry initialized for service: ${serviceName}`);
}

export function shutdownOpenTelemetry(): Promise<void> {
  if (sdk) {
    return sdk.shutdown();
  }
  return Promise.resolve();
}
