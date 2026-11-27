import { Button, Card, Field, Input } from "@mockgps/ui";
import { useState, type FormEvent } from "react";
import { useAuth } from "../lib/auth";
import { format, useI18n } from "../lib/i18n";
import { missingConfig } from "../lib/supabase";

export function LoginPage() {
  const { t } = useI18n();
  const { signIn, status, error, signOut } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      await signIn(email, password);
    } catch {
      /* message comes from auth context */
    } finally {
      setBusy(false);
    }
  }

  const message =
    status === "noAccess" ? (error === "account_disabled" ? t.login.disabled : t.login.noAccess)
    : error === "invalid" ? t.login.invalid
    : error === "network" ? t.errors.network
    : error ? error
    : null;

  return (
    <main className="flex min-h-dvh items-center justify-center px-4">
      <Card className="w-full max-w-sm p-8">
        <h1 className="text-xl font-bold">{t.login.title}</h1>
        <p className="mt-1 text-sm text-muted">{t.login.subtitle}</p>
        {missingConfig.length > 0 && (
          <p className="mt-4 rounded-md bg-danger/10 px-3 py-2 text-sm text-danger" role="alert">
            {format(t.login.configMissing, { keys: missingConfig.join(", ") })}
          </p>
        )}
        <form onSubmit={submit} className="mt-6 space-y-4">
          <Field label={t.login.email} htmlFor="email">
            <Input id="email" type="email" autoComplete="username" required value={email} onChange={(e) => setEmail(e.target.value)} />
          </Field>
          <Field label={t.login.password} htmlFor="password">
            <Input id="password" type="password" autoComplete="current-password" required value={password} onChange={(e) => setPassword(e.target.value)} />
          </Field>
          {message && (
            <p className="rounded-md bg-danger/10 px-3 py-2 text-sm text-danger" role="alert">
              {message}
            </p>
          )}
          <Button type="submit" className="w-full" loading={busy}>
            {t.login.submit}
          </Button>
          {status === "noAccess" && (
            <Button type="button" variant="ghost" className="w-full" onClick={signOut}>
              {t.nav.signOut}
            </Button>
          )}
        </form>
      </Card>
    </main>
  );
}
