import type { Session } from "@supabase/supabase-js";
import { useQueryClient } from "@tanstack/react-query";
import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from "react";
import { ApiError, api, unwrap, type Me } from "./api";
import { supabase } from "./supabase";

export type AuthStatus = "loading" | "signedOut" | "noAccess" | "ready";

interface AuthValue {
  status: AuthStatus;
  me: Me | null;
  error: string | null;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  can: (permission: string) => boolean;
}

const AuthContext = createContext<AuthValue | null>(null);

/**
 * Supabase handles the session; the API decides access. A user is let in only when `/me`
 * returns at least one admin permission (roles are never read from the JWT).
 */
export function AuthProvider({ children }: { children: ReactNode }) {
  const queryClient = useQueryClient();
  const [status, setStatus] = useState<AuthStatus>("loading");
  const [me, setMe] = useState<Me | null>(null);
  const [error, setError] = useState<string | null>(null);

  const loadMe = useCallback(async (session: Session | null) => {
    if (!session) {
      setMe(null);
      setStatus("signedOut");
      return;
    }
    try {
      const profile = await unwrap(api.GET("/api/v1/me"));
      setMe(profile);
      setStatus(profile.permissions.length > 0 ? "ready" : "noAccess");
      setError(null);
    } catch (e) {
      const code = e instanceof ApiError ? e.code : "generic";
      setError(code);
      setMe(null);
      setStatus(code === "network" ? "signedOut" : "noAccess");
      if (code === "account_disabled" || code === "account_not_found") await supabase.auth.signOut();
    }
  }, []);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => loadMe(data.session));
    const { data } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === "SIGNED_IN" || event === "SIGNED_OUT") void loadMe(session);
    });
    return () => data.subscription.unsubscribe();
  }, [loadMe]);

  const signIn = async (email: string, password: string) => {
    setError(null);
    const { error: authError } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
    if (authError) {
      setError(authError.code === "invalid_credentials" ? "invalid" : authError.message);
      throw authError;
    }
  };

  const signOut = async () => {
    await supabase.auth.signOut();
    queryClient.clear();
  };

  const can = (permission: string) => me?.permissions.includes(permission) ?? false;

  return <AuthContext.Provider value={{ status, me, error, signIn, signOut, can }}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthValue {
  const value = useContext(AuthContext);
  if (!value) throw new Error("useAuth must be used inside AuthProvider");
  return value;
}
