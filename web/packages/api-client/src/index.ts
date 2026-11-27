import createClient, { type Middleware } from "openapi-fetch";
import type { components, paths } from "./schema";

export type { components, paths };
export type Schemas = components["schemas"];

/** RFC 9457 problem details returned by the API. */
export interface Problem {
  status: number;
  title?: string;
  detail?: string;
  code?: string;
  errors?: Record<string, string[]>;
}

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly fieldErrors: Record<string, string[]>;

  constructor(problem: Problem) {
    super(problem.detail ?? problem.title ?? "Request failed");
    this.status = problem.status;
    this.code = problem.code ?? `http_${problem.status}`;
    this.fieldErrors = problem.errors ?? {};
  }

  static network() {
    return new ApiError({ status: 0, code: "network", detail: "No connection to the server." });
  }
}

export interface ApiClientOptions {
  baseUrl: string;
  /** Returns the current Supabase access token, if signed in. */
  getToken?: () => Promise<string | null | undefined> | string | null | undefined;
  /** Called on 401 so the app can sign out. */
  onUnauthorized?: () => void;
}

/** Typed client generated from the API's OpenAPI document (see `npm run api:types`). */
export function createApiClient({ baseUrl, getToken, onUnauthorized }: ApiClientOptions) {
  const client = createClient<paths>({
    baseUrl: baseUrl.replace(/\/$/, ""),
    // Resolve fetch at call time (not at import) so polyfills and test doubles are honoured.
    fetch: (request) => globalThis.fetch(request),
  });

  const auth: Middleware = {
    async onRequest({ request }) {
      const token = await getToken?.();
      if (token) request.headers.set("Authorization", `Bearer ${token}`);
      return request;
    },
    async onResponse({ response }) {
      if (response.status === 401) onUnauthorized?.();
      return response;
    },
  };
  client.use(auth);
  return client;
}

export type ApiClient = ReturnType<typeof createApiClient>;

/**
 * Unwraps an openapi-fetch result: returns data or throws {@link ApiError}.
 * Network failures (fetch throws) become ApiError with code "network".
 */
export async function unwrap<T>(call: Promise<{ data?: T; error?: unknown; response: Response }>): Promise<T> {
  let result: { data?: T; error?: unknown; response: Response };
  try {
    result = await call;
  } catch {
    throw ApiError.network();
  }
  if (!result.response.ok) {
    const problem = (result.error ?? {}) as Partial<Problem>;
    throw new ApiError({ ...problem, status: result.response.status });
  }
  return result.data as T;
}
