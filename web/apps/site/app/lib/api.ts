import { ApiError, createApiClient, unwrap, type Schemas } from "@mockgps/api-client";

const baseUrl = (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? "http://localhost:5080";

/** The site uses only public, anonymous endpoints. */
export const api = createApiClient({ baseUrl: baseUrl.replace(/\/api\/v1\/?$/, "") });

export type Release = Schemas["Public.ReleaseDto"];
export type ContactRequest = Schemas["Public.ContactRequest"];

export async function fetchLatestRelease(platform: "android" | "ios"): Promise<Release | null> {
  const res = await unwrap(api.GET("/api/v1/public/releases/latest", { params: { query: { platform } } }));
  // 204 = no published release yet.
  return (res as Release | undefined) ?? null;
}

export async function sendContact(body: ContactRequest): Promise<void> {
  await unwrap(api.POST("/api/v1/public/contact", { body }));
}

export { ApiError };
