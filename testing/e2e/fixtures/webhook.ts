import http from 'http';
import { AddressInfo } from 'net';

export type ReceivedRequest = {
  method: string;
  headers: http.IncomingHttpHeaders;
  body: any;
};

export type WebhookReceiver = {
  url: string;
  requests: ReceivedRequest[];
  /** status code answered to the next requests, or a function deciding it per request */
  respond: (status: number | ((req: ReceivedRequest) => number)) => void;
  close: () => Promise<void>;
};

/**
 * A local HTTP server standing in for the CDR webhook. dSIPRouter runs on the same box as the tests,
 * so it reaches the receiver on 127.0.0.1.
 */
export async function startReceiver(): Promise<WebhookReceiver> {
  const requests: ReceivedRequest[] = [];
  let decide: (req: ReceivedRequest) => number = () => 200;

  const server = http.createServer((req, res) => {
    const chunks: Buffer[] = [];
    req.on('data', (chunk) => chunks.push(chunk));
    req.on('end', () => {
      const raw = Buffer.concat(chunks).toString('utf-8');
      let body: any = raw;
      try {
        body = JSON.parse(raw);
      } catch (e) {
        // keep the raw text, the test will fail on it
      }
      const received = { method: req.method || '', headers: req.headers, body };
      requests.push(received);
      res.writeHead(decide(received), { 'Content-Type': 'application/json' });
      res.end('{}');
    });
  });
  await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
  const port = (server.address() as AddressInfo).port;

  return {
    url: `http://127.0.0.1:${port}/cdrs`,
    requests,
    respond: (status) => {
      decide = typeof status === 'function' ? status : () => status;
    },
    close: () => new Promise<void>((resolve) => server.close(() => resolve())),
  };
}

/** every CDR the receiver got, across all requests */
export function receivedCdrs(receiver: WebhookReceiver, tag: string): any[] {
  return receiver.requests
    .filter((r) => r.headers['x-dsip-event'] === 'cdr' && Array.isArray(r.body))
    .flatMap((r) => r.body)
    .filter((cdr: any) => String(cdr.sip_call_id).startsWith(`${tag}-`));
}

export function basicAuth(username: string, password: string): string {
  return 'Basic ' + Buffer.from(`${username}:${password}`).toString('base64');
}
