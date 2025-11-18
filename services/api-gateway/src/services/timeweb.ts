import { AppError, logger } from '@maratea/shared';

const DEFAULT_TIMEWEB_API_BASE_URL = 'https://api.timeweb.cloud/api/v1';
const DEFAULT_TIMEOUT_MS = 10000;

export interface TimewebClientOptions {
  token?: string;
  baseUrl?: string;
  timeoutMs?: number;
  fetchImpl?: typeof fetch;
}

export interface TimewebDomain {
  id?: number;
  fqdn?: string;
  name?: string;
  status?: string;
  expires_at?: string;
  [key: string]: unknown;
}

interface TimewebDomainsResponse {
  domains?: TimewebDomain[];
  meta?: Record<string, unknown>;
}

interface FetchRequestInit {
  method?: string;
  headers?: Record<string, string>;
  body?: string;
  signal?: AbortSignal;
}

export interface TimewebFinances {
  balance?: number;
  bonus_balance?: number;
  credit?: number;
  [key: string]: unknown;
}

interface TimewebFinancesResponse {
  finances?: TimewebFinances;
}

export class TimewebClient {
  private readonly token: string;
  private readonly baseUrl: string;
  private readonly timeoutMs: number;
  private readonly fetchImpl: typeof fetch;

  constructor({
    token = process.env.TIMEWEB_API_TOKEN,
    baseUrl = process.env.TIMEWEB_API_BASE_URL || DEFAULT_TIMEWEB_API_BASE_URL,
    timeoutMs = DEFAULT_TIMEOUT_MS,
    fetchImpl = globalThis.fetch,
  }: TimewebClientOptions = {}) {
    if (!token) {
      throw new AppError('TIMEWEB_API_TOKEN_MISSING', 'TIMEWEB_API_TOKEN is not set', 500);
    }

    if (!fetchImpl) {
      throw new AppError(
        'FETCH_NOT_AVAILABLE',
        'Fetch API is not available in the current runtime',
        500
      );
    }

    this.token = token;
    this.baseUrl = baseUrl.replace(/\/$/, '');
    this.timeoutMs = timeoutMs;
    this.fetchImpl = fetchImpl;
  }

  async listDomains(): Promise<TimewebDomain[]> {
    const response = await this.request<TimewebDomainsResponse>('/domains');

    if (!response.domains || !Array.isArray(response.domains)) {
      throw new AppError(
        'TIMEWEB_INVALID_RESPONSE',
        'Timeweb API did not return a domains array',
        502,
        response
      );
    }

    return response.domains;
  }

  async getAccountFinances(): Promise<TimewebFinances> {
    const response = await this.request<TimewebFinancesResponse>('/account/finances');

    if (!response.finances) {
      throw new AppError(
        'TIMEWEB_INVALID_RESPONSE',
        'Timeweb API did not return finances data',
        502,
        response
      );
    }

    return response.finances;
  }

  private async request<T>(path: string, init: FetchRequestInit = {}): Promise<T> {
    const url = `${this.baseUrl}${path}`;
    const controller = new AbortController();
    const timeout = setTimeout(() => {
      controller.abort();
    }, this.timeoutMs);

    try {
      const response = await this.fetchImpl(url, {
        ...init,
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.token}`,
          ...(init.headers || {}),
        },
        signal: controller.signal,
      });

      const rawBody = await response.text();
      const body = rawBody ? (JSON.parse(rawBody) as T) : ({} as T);

      if (!response.ok) {
        logger.error(
          {
            status: response.status,
            statusText: response.statusText,
            body,
          },
          'Timeweb API request failed'
        );

        throw new AppError(
          'TIMEWEB_API_ERROR',
          `Timeweb API responded with status ${response.status}`,
          response.status || 502,
          body
        );
      }

      return body;
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }

      if (error instanceof Error && error.name === 'AbortError') {
        throw new AppError('TIMEWEB_API_TIMEOUT', 'Timeweb API request timed out', 504);
      }

      logger.error({ err: error }, 'Failed to execute Timeweb API request');

      throw new AppError(
        'TIMEWEB_API_REQUEST_FAILED',
        'Failed to execute Timeweb API request',
        502,
        error
      );
    } finally {
      clearTimeout(timeout);
    }
  }
}
