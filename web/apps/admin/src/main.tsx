import { Spinner } from "@mockgps/ui";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { StrictMode, Suspense, lazy, type ReactNode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Navigate, Route, Routes } from "react-router";
import "./app.css";
import { AdminLayout, NAV } from "./components/layout";
import { ToastProvider } from "./components/ui";
import { ApiError } from "./lib/api";
import { AuthProvider, useAuth } from "./lib/auth";
import { I18nProvider, useI18n } from "./lib/i18n";
import { LoginPage } from "./pages/login";

// Pages load on demand; the dashboard pulls in the chart library only when opened.
const DashboardPage = lazy(() => import("./pages/dashboard").then((m) => ({ default: m.DashboardPage })));
const UsersPage = lazy(() => import("./pages/users").then((m) => ({ default: m.UsersPage })));
const UserDetailPage = lazy(() => import("./pages/users").then((m) => ({ default: m.UserDetailPage })));
const RolesPage = lazy(() => import("./pages/roles").then((m) => ({ default: m.RolesPage })));
const SettingsPage = lazy(() => import("./pages/settings").then((m) => ({ default: m.SettingsPage })));
const VersionsPage = lazy(() => import("./pages/versions").then((m) => ({ default: m.VersionsPage })));
const AnnouncementsPage = lazy(() => import("./pages/announcements").then((m) => ({ default: m.AnnouncementsPage })));
const AuditPage = lazy(() => import("./pages/audit-messages").then((m) => ({ default: m.AuditPage })));
const MessagesPage = lazy(() => import("./pages/audit-messages").then((m) => ({ default: m.MessagesPage })));

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      refetchOnWindowFocus: false,
      // Don't retry client errors (403, 404, validation); retry network/5xx once.
      retry: (count, error) => !(error instanceof ApiError && error.status >= 400 && error.status < 500) && count < 1,
    },
  },
});

/** Only renders a page when the signed-in admin holds the permission. */
function Guard({ permission, children }: { permission: string; children: ReactNode }) {
  const { can } = useAuth();
  const { t } = useI18n();
  if (can(permission)) return <Suspense fallback={<Spinner label={t.common.loading} />}>{children}</Suspense>;
  const first = NAV.find((n) => can(n.permission));
  return first && first.permission !== permission ? <Navigate to={first.to} replace /> : <ForbiddenPage />;
}

function ForbiddenPage() {
  const { t } = useI18n();
  return <p className="py-24 text-center text-muted">{t.errors.forbidden}</p>;
}

function NotFoundPage() {
  const { t } = useI18n();
  return <p className="py-24 text-center text-muted">{t.notFound}</p>;
}

export function AppRoutes() {
  const { status } = useAuth();
  const { t } = useI18n();
  if (status === "loading") return <Spinner label={t.common.loading} />;
  if (status !== "ready") return <LoginPage />;
  return (
    <Routes>
      <Route element={<AdminLayout />}>
        <Route index element={<Guard permission="dashboard.read"><DashboardPage /></Guard>} />
        <Route path="users" element={<Guard permission="users.read"><UsersPage /></Guard>} />
        <Route path="users/:id" element={<Guard permission="users.read"><UserDetailPage /></Guard>} />
        <Route path="admins" element={<Guard permission="users.read"><UsersPage adminsOnly /></Guard>} />
        <Route path="roles" element={<Guard permission="roles.manage"><RolesPage /></Guard>} />
        <Route path="settings" element={<Guard permission="settings.manage"><SettingsPage /></Guard>} />
        <Route path="versions" element={<Guard permission="versions.manage"><VersionsPage /></Guard>} />
        <Route path="announcements" element={<Guard permission="announcements.manage"><AnnouncementsPage /></Guard>} />
        <Route path="audit" element={<Guard permission="audit.read"><AuditPage /></Guard>} />
        <Route path="messages" element={<Guard permission="messages.manage"><MessagesPage /></Guard>} />
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  );
}

const root = document.getElementById("root");
if (root) {
  createRoot(root).render(
    <StrictMode>
      <QueryClientProvider client={queryClient}>
        <I18nProvider>
          <ToastProvider>
            <BrowserRouter>
              <AuthProvider>
                <AppRoutes />
              </AuthProvider>
            </BrowserRouter>
          </ToastProvider>
        </I18nProvider>
      </QueryClientProvider>
    </StrictMode>,
  );
}
