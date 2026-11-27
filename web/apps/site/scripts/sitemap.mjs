// Writes sitemap.xml and robots.txt into the build output (runs after `react-router build`).
import { writeFileSync } from "node:fs";

const site = (process.env.VITE_SITE_URL ?? "https://mockgps.example.com").replace(/\/$/, "");
const paths = ["/", "/features", "/how-it-works", "/about", "/faq", "/contact", "/privacy", "/terms"];
const tr = (p) => (p === "/" ? "/tr" : `/tr${p}`);
const today = new Date().toISOString().slice(0, 10);

const url = (loc, p) => `  <url>
    <loc>${site}${loc}</loc>
    <lastmod>${today}</lastmod>
    <xhtml:link rel="alternate" hreflang="en" href="${site}${p}"/>
    <xhtml:link rel="alternate" hreflang="tr" href="${site}${tr(p)}"/>
  </url>`;

const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
${paths.flatMap((p) => [url(p, p), url(tr(p), p)]).join("\n")}
</urlset>
`;

writeFileSync("build/client/sitemap.xml", xml);
writeFileSync("build/client/robots.txt", `User-agent: *\nAllow: /\nSitemap: ${site}/sitemap.xml\n`);
console.log(`sitemap.xml + robots.txt written for ${site}`);
