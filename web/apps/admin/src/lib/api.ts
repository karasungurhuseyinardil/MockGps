import { ApiError, createApiClient, unwrap, type Schemas } from "@mockgps/api-client";
import { supabase } from "./supabase";

const baseUrl = (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? "http://localhost:5080";

export const api = createApiClient({
  baseUrl,
  getToken: async () => (await supabase.auth.getSession()).data.session?.access_token,
});

export { ApiError, unwrap };
export type { Schemas };

export type Me = Schemas["Me.MeResponse"];
export type DashboardSummary = Schemas["Admin.DashboardSummary"];
export type TimeseriesPoint = Schemas["Admin.TimeseriesPoint"];
export type FeatureUsageItem = Schemas["Admin.FeatureUsageItem"];
export type SystemHealth = Schemas["Admin.SystemHealth"];
export type UserListItem = Schemas["Admin.AdminUserListItem"];
export type UserDetail = Schemas["Admin.AdminUserDetail"];
export type UserStats = Schemas["Admin.AdminUserStats"];
export type Role = Schemas["Admin.RoleDto"];
export type SystemSetting = Schemas["Admin.SystemSettingDto"];
export type AppVersion = Schemas["Admin.AppVersionDto"];
export type AppVersionRequest = Schemas["Admin.AppVersionRequest"];
export type Announcement = Schemas["Admin.AdminAnnouncementDto"];
export type AnnouncementRequest = Schemas["Admin.AnnouncementRequest"];
export type AuditLog = Schemas["Admin.AuditLogDto"];
export type ContactMessage = Schemas["Admin.ContactMessageDto"];

export interface Page<T> {
  items: T[];
  page: number;
  pageSize: number;
  totalCount: number;
  totalPages: number;
}
