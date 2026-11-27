import { Button, Card, Field, Input, Textarea } from "@mockgps/ui";
import { CheckCircle2 } from "lucide-react";
import { useState, type FormEvent } from "react";
import type { Route } from "./+types/contact";
import { Section } from "../components/sections";
import { ApiError, sendContact } from "../lib/api";
import { useI18n } from "../i18n";
import { langFromRouteId, pageMeta } from "../seo";

export const meta: Route.MetaFunction = ({ matches }) => pageMeta("contact", langFromRouteId(matches.at(-1)?.id ?? ""));

type Fields = { name: string; email: string; subject: string; message: string; website: string };
type Errors = Partial<Record<keyof Fields, string>>;

const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

/** Client-side validation mirrors the API rules (the API validates again). */
export function validateContact(f: Fields, msg: { name: string; email: string; subject: string; message: string }): Errors {
  const e: Errors = {};
  if (!f.name.trim()) e.name = msg.name;
  if (!EMAIL.test(f.email.trim())) e.email = msg.email;
  if (!f.subject.trim()) e.subject = msg.subject;
  if (f.message.trim().length < 10) e.message = msg.message;
  return e;
}

export default function Contact() {
  const { t } = useI18n();
  const c = t.contact;
  const [fields, setFields] = useState<Fields>({ name: "", email: "", subject: "", message: "", website: "" });
  const [errors, setErrors] = useState<Errors>({});
  const [status, setStatus] = useState<"idle" | "sending" | "sent">("idle");
  const [formError, setFormError] = useState<string | null>(null);

  const set = (k: keyof Fields) => (e: { target: { value: string } }) => setFields((f) => ({ ...f, [k]: e.target.value }));

  async function submit(e: FormEvent) {
    e.preventDefault();
    const found = validateContact(fields, c.errors);
    setErrors(found);
    setFormError(null);
    if (Object.keys(found).length) return;
    setStatus("sending");
    try {
      await sendContact({ ...fields, website: fields.website || null });
      setStatus("sent");
    } catch (err) {
      setStatus("idle");
      if (err instanceof ApiError) {
        if (err.status === 429) setFormError(c.errors.rateLimited);
        else if (err.code === "network") setFormError(c.errors.network);
        else if (err.status === 400) {
          const mapped: Errors = {};
          for (const key of Object.keys(err.fieldErrors) as (keyof Fields)[]) mapped[key] = err.fieldErrors[key]?.[0];
          setErrors(mapped);
        } else setFormError(c.errors.generic);
      } else setFormError(c.errors.generic);
    }
  }

  return (
    <Section title={c.title} intro={c.intro}>
      <Card className="mx-auto max-w-2xl p-6 sm:p-8">
        {status === "sent" ? (
          <div className="flex flex-col items-center gap-3 py-8 text-center" role="status">
            <CheckCircle2 className="size-10 text-success" aria-hidden />
            <p>{c.sent}</p>
          </div>
        ) : (
          <form onSubmit={submit} noValidate className="space-y-5">
            <div className="grid gap-5 sm:grid-cols-2">
              <Field label={c.name} htmlFor="name" error={errors.name}>
                <Input id="name" autoComplete="name" maxLength={100} value={fields.name} onChange={set("name")} aria-invalid={!!errors.name} aria-describedby={errors.name ? "name-error" : undefined} />
              </Field>
              <Field label={c.email} htmlFor="email" error={errors.email}>
                <Input id="email" type="email" autoComplete="email" maxLength={254} value={fields.email} onChange={set("email")} aria-invalid={!!errors.email} aria-describedby={errors.email ? "email-error" : undefined} />
              </Field>
            </div>
            <Field label={c.subject} htmlFor="subject" error={errors.subject}>
              <Input id="subject" maxLength={150} value={fields.subject} onChange={set("subject")} aria-invalid={!!errors.subject} aria-describedby={errors.subject ? "subject-error" : undefined} />
            </Field>
            <Field label={c.message} htmlFor="message" error={errors.message}>
              <Textarea id="message" maxLength={5000} value={fields.message} onChange={set("message")} aria-invalid={!!errors.message} aria-describedby={errors.message ? "message-error" : undefined} />
            </Field>
            {/* Honeypot: hidden from people and assistive tech; bots fill it. */}
            <div className="absolute -left-[9999px]" aria-hidden="true">
              <label htmlFor="website">Website</label>
              <input id="website" tabIndex={-1} autoComplete="off" value={fields.website} onChange={set("website")} />
            </div>
            {formError && (
              <p className="rounded-md bg-danger/10 px-4 py-3 text-sm text-danger" role="alert">
                {formError}
              </p>
            )}
            <Button type="submit" loading={status === "sending"} className="w-full sm:w-auto">
              {c.send}
            </Button>
          </form>
        )}
      </Card>
    </Section>
  );
}
