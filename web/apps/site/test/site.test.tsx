import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { createRoutesStub } from "react-router";
import { afterEach, describe, expect, it, vi } from "vitest";
import { dictionaries, format, langFromPath, localePath, switchLanguagePath } from "../app/i18n";
import Contact, { validateContact } from "../app/routes/contact";
import { DownloadSection } from "../app/components/download";

describe("i18n paths", () => {
  it("detects language from the path", () => {
    expect(langFromPath("/")).toBe("en");
    expect(langFromPath("/tr")).toBe("tr");
    expect(langFromPath("/tr/faq")).toBe("tr");
    expect(langFromPath("/trivia")).toBe("en");
  });

  it("switches language keeping the page", () => {
    expect(switchLanguagePath("/faq", "tr")).toBe("/tr/faq");
    expect(switchLanguagePath("/tr/faq", "en")).toBe("/faq");
    expect(switchLanguagePath("/tr", "en")).toBe("/");
    expect(localePath("/", "tr")).toBe("/tr");
  });

  it("both languages define the same keys", () => {
    const keys = (o: object): string[] =>
      Object.entries(o).flatMap(([k, v]) => (v && typeof v === "object" && !Array.isArray(v) ? keys(v).map((s) => `${k}.${s}`) : [k]));
    expect(keys(dictionaries.tr).sort()).toEqual(keys(dictionaries.en).sort());
    expect(dictionaries.tr.faq.items.length).toBe(dictionaries.en.faq.items.length);
  });

  it("formats templates", () => {
    expect(format("Version {version} · build {build}", { version: "1.2.0", build: 7 })).toBe("Version 1.2.0 · build 7");
  });
});

describe("contact form", () => {
  const msg = dictionaries.en.contact.errors;

  it("validates required fields", () => {
    const e = validateContact({ name: "", email: "x", subject: "", message: "short", website: "" }, msg);
    expect(Object.keys(e).sort()).toEqual(["email", "message", "name", "subject"]);
    expect(validateContact({ name: "A", email: "a@b.co", subject: "Hi", message: "Hello there!", website: "" }, msg)).toEqual({});
  });

  afterEach(() => vi.restoreAllMocks());

  it("shows field errors and sends a valid message", async () => {
    const fetchMock = vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(null, { status: 202 }));
    const Stub = createRoutesStub([{ path: "/contact", Component: Contact }]);
    render(<Stub initialEntries={["/contact"]} />);
    const user = userEvent.setup();

    await user.click(screen.getByRole("button", { name: "Send message" }));
    expect(screen.getByText("Enter a valid email address.")).toBeInTheDocument();
    expect(fetchMock).not.toHaveBeenCalled();

    await user.type(screen.getByLabelText("Name"), "Ada");
    await user.type(screen.getByLabelText("Email"), "ada@example.com");
    await user.type(screen.getByLabelText("Subject"), "Feedback");
    await user.type(screen.getByLabelText("Message"), "Route playback works great.");
    await user.click(screen.getByRole("button", { name: "Send message" }));

    expect(await screen.findByText(/Your message has been sent/)).toBeInTheDocument();
    const request = fetchMock.mock.calls[0]![0] as Request;
    expect(request.url).toMatch(/\/api\/v1\/public\/contact$/);
    expect(await request.json()).toMatchObject({ name: "Ada", email: "ada@example.com", website: null });
  });

  it("explains rate limiting", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(JSON.stringify({ status: 429, code: "rate_limited" }), { status: 429, headers: { "content-type": "application/json" } }),
    );
    const Stub = createRoutesStub([{ path: "/tr/contact", Component: Contact }]);
    render(<Stub initialEntries={["/tr/contact"]} />);
    const user = userEvent.setup();
    await user.type(screen.getByLabelText("Ad"), "Ada");
    await user.type(screen.getByLabelText("E-posta"), "ada@example.com");
    await user.type(screen.getByLabelText("Konu"), "Merhaba");
    await user.type(screen.getByLabelText("Mesaj"), "Uzun bir test mesajı.");
    await user.click(screen.getByRole("button", { name: "Mesajı gönder" }));
    expect(await screen.findByRole("alert")).toHaveTextContent("Çok fazla mesaj");
  });
});

describe("download section", () => {
  afterEach(() => vi.restoreAllMocks());

  it("shows the latest release from the API", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(
        JSON.stringify({ platform: "android", version: "1.2.0", buildNumber: 12, minSupportedBuild: 1, downloadUrl: "https://cdn.example/app.apk", fileSizeBytes: 31457280, releaseNotes: null, publishedAt: null }),
        { status: 200, headers: { "content-type": "application/json" } },
      ),
    );
    const Stub = createRoutesStub([{ path: "/", Component: DownloadSection }]);
    render(<Stub initialEntries={["/"]} />);
    expect(await screen.findByText(/Version 1.2.0 · build 12/)).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Download APK/ })).toHaveAttribute("href", "https://cdn.example/app.apk");
  });

  it("says when nothing is published yet", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(null, { status: 204 }));
    const Stub = createRoutesStub([{ path: "/", Component: DownloadSection }]);
    render(<Stub initialEntries={["/"]} />);
    expect(await screen.findByText(/No public release is available yet/)).toBeInTheDocument();
  });
});
