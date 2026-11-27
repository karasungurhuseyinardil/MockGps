import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { ReactNode } from "react";
import { MemoryRouter } from "react-router";
import { afterEach, describe, expect, it, vi } from "vitest";
import { DataTable, ToastProvider, errorMessage } from "../src/components/ui";
import { ApiError } from "../src/lib/api";
import { I18nProvider, dictionaries, format } from "../src/lib/i18n";

// The real auth context talks to Supabase; tests swap in a controllable fake.
const auth = vi.hoisted(() => ({
  status: "ready" as "loading" | "signedOut" | "noAccess" | "ready",
  permissions: [] as string[],
  error: null as string | null,
  signIn: vi.fn(),
}));

vi.mock("../src/lib/auth", () => ({
  AuthProvider: ({ children }: { children: ReactNode }) => <>{children}</>,
  useAuth: () => ({
    status: auth.status,
    me: { id: "me", email: "admin@test.local", roles: [], permissions: auth.permissions },
    error: auth.error,
    signIn: auth.signIn,
    signOut: vi.fn(),
    can: (p: string) => auth.permissions.includes(p),
  }),
}));

vi.mock("../src/lib/supabase", () => ({ supabase: { auth: { getSession: async () => ({ data: { session: null } }) } }, missingConfig: [] }));

const { AppRoutes } = await import("../src/main");

function renderApp(path: string) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={qc}>
      <I18nProvider lang="en">
        <ToastProvider>
          <MemoryRouter initialEntries={[path]}>
            <AppRoutes />
          </MemoryRouter>
        </ToastProvider>
      </I18nProvider>
    </QueryClientProvider>,
  );
}

afterEach(() => {
  vi.restoreAllMocks();
  auth.status = "ready";
  auth.permissions = [];
  auth.error = null;
});

describe("access control", () => {
  it("shows the login form when signed out", () => {
    auth.status = "signedOut";
    renderApp("/");
    expect(screen.getByRole("heading", { name: "Sign in to admin" })).toBeInTheDocument();
  });

  it("explains when an account has no admin permissions", () => {
    auth.status = "noAccess";
    renderApp("/");
    expect(screen.getByRole("alert")).toHaveTextContent("This account has no administrator permissions.");
  });

  it("only shows navigation the admin is allowed to use", () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify([]), { status: 200, headers: { "content-type": "application/json" } }));
    auth.permissions = ["dashboard.read", "audit.read"];
    renderApp("/audit");
    const nav = screen.getAllByRole("navigation", { name: "Admin" })[0]!;
    expect(nav).toHaveTextContent("Dashboard");
    expect(nav).toHaveTextContent("Audit log");
    expect(nav).not.toHaveTextContent("Roles & permissions");
    expect(nav).not.toHaveTextContent("Users");
  });

  it("redirects away from pages without permission", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify({ items: [], page: 1, pageSize: 25, totalCount: 0 }), { status: 200, headers: { "content-type": "application/json" } }));
    auth.permissions = ["audit.read"];
    renderApp("/roles");
    expect(await screen.findByRole("heading", { name: "Audit log" })).toBeInTheDocument();
  });

  it("submits credentials", async () => {
    auth.status = "signedOut";
    renderApp("/");
    const user = userEvent.setup();
    await user.type(screen.getByLabelText("Email"), "admin@test.local");
    await user.type(screen.getByLabelText("Password"), "Passw0rd123");
    await user.click(screen.getByRole("button", { name: "Sign in" }));
    expect(auth.signIn).toHaveBeenCalledWith("admin@test.local", "Passw0rd123");
  });
});

describe("helpers", () => {
  const t = dictionaries.en;

  it("maps API errors to readable messages", () => {
    expect(errorMessage(t, ApiError.network())).toBe(t.errors.network);
    expect(errorMessage(t, new ApiError({ status: 403 }))).toBe(t.errors.forbidden);
    expect(errorMessage(t, new ApiError({ status: 500, detail: "stack trace" }))).toBe(t.errors.generic);
    expect(errorMessage(t, new ApiError({ status: 422, detail: "The last superadmin cannot be deactivated." }))).toBe("The last superadmin cannot be deactivated.");
  });

  it("both languages have the same keys", () => {
    const keys = (o: object): string[] =>
      Object.entries(o).flatMap(([k, v]) => (v && typeof v === "object" ? keys(v).map((s) => `${k}.${s}`) : [k]));
    expect(keys(dictionaries.tr).sort()).toEqual(keys(dictionaries.en).sort());
  });

  it("formats templates", () => {
    expect(format(t.common.pageOf, { page: 2, pages: 5 })).toBe("Page 2 of 5");
  });

  it("table shows empty and error states", () => {
    const cols = [{ key: "a", header: "A", cell: (r: { a: string }) => r.a }];
    const { rerender } = render(
      <I18nProvider lang="en">
        <DataTable columns={cols} rows={[]} rowKey={(r) => r.a} loading={false} error={null} />
      </I18nProvider>,
    );
    expect(screen.getByText(t.common.empty)).toBeInTheDocument();
    rerender(
      <I18nProvider lang="en">
        <DataTable columns={cols} rows={undefined} rowKey={(r) => r.a} loading={false} error={ApiError.network()} onRetry={() => {}} />
      </I18nProvider>,
    );
    expect(screen.getByRole("alert")).toHaveTextContent(t.errors.network);
  });
});
