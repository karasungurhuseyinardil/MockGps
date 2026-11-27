import { Monitor, Moon, Sun } from "lucide-react";
import { useEffect, useState } from "react";

export type ThemePreference = "system" | "light" | "dark";
const KEY = "mockgps.theme";

function read(): ThemePreference {
  try {
    const v = localStorage.getItem(KEY);
    return v === "light" || v === "dark" ? v : "system";
  } catch {
    return "system";
  }
}

export function applyTheme(pref: ThemePreference) {
  const root = document.documentElement;
  if (pref === "system") root.removeAttribute("data-theme");
  else root.setAttribute("data-theme", pref);
}

/** Inline script for <head> that applies the saved theme before first paint (no flash). */
export const themeBootScript = `try{var t=localStorage.getItem('${KEY}');if(t==='light'||t==='dark')document.documentElement.setAttribute('data-theme',t)}catch(e){}`;

export function useTheme() {
  const [pref, setPref] = useState<ThemePreference>("system");
  useEffect(() => setPref(read()), []);
  const set = (next: ThemePreference) => {
    setPref(next);
    applyTheme(next);
    try {
      if (next === "system") localStorage.removeItem(KEY);
      else localStorage.setItem(KEY, next);
    } catch {
      /* storage unavailable: theme still applies for this page view */
    }
  };
  return { pref, set };
}

const ORDER: ThemePreference[] = ["system", "light", "dark"];

export function ThemeToggle({ labels }: { labels: Record<ThemePreference, string> }) {
  const { pref, set } = useTheme();
  const Icon = pref === "light" ? Sun : pref === "dark" ? Moon : Monitor;
  const next = ORDER[(ORDER.indexOf(pref) + 1) % ORDER.length]!;
  return (
    <button
      type="button"
      onClick={() => set(next)}
      className="inline-flex size-10 items-center justify-center rounded-full text-muted transition-colors hover:bg-line hover:text-fg"
      aria-label={labels[pref]}
      title={labels[pref]}
    >
      <Icon className="size-[18px]" aria-hidden />
    </button>
  );
}
