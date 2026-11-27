/** App icon as SVG (same geometry as mobile/tool/generate_icons.py). */
export function Logo({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 108 108" className={className} aria-hidden="true">
      <defs>
        <linearGradient id="mg-bg" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#4A6CFF" />
          <stop offset="1" stopColor="#243FD6" />
        </linearGradient>
      </defs>
      <rect width="108" height="108" rx="26" fill="url(#mg-bg)" />
      <ellipse cx="54" cy="79" rx="13" ry="3.6" fill="#fff" opacity="0.35" />
      <path d="M54,77 L39.98,56.6 A17,17 0 1,1 68.02,56.6 Z" fill="#fff" />
      <circle cx="54" cy="47" r="7" fill="#F2542D" />
    </svg>
  );
}
