/** Single list of site pages; used by routes, prerendering, navigation and the sitemap. */
export const PAGES = [
  { key: "home", path: "/", file: "routes/home.tsx" },
  { key: "features", path: "/features", file: "routes/features.tsx" },
  { key: "how", path: "/how-it-works", file: "routes/how-it-works.tsx" },
  { key: "about", path: "/about", file: "routes/about.tsx" },
  { key: "faq", path: "/faq", file: "routes/faq.tsx" },
  { key: "contact", path: "/contact", file: "routes/contact.tsx" },
  { key: "privacy", path: "/privacy", file: "routes/privacy.tsx" },
  { key: "terms", path: "/terms", file: "routes/terms.tsx" },
] as const;

export type PageKey = (typeof PAGES)[number]["key"];
