import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: {
          950: "rgb(var(--bg) / <alpha-value>)",
          900: "rgb(var(--panel) / <alpha-value>)",
          850: "rgb(var(--panel-2) / <alpha-value>)",
          800: "rgb(var(--panel-3) / <alpha-value>)",
          700: "rgb(var(--line-strong) / <alpha-value>)",
          400: "rgb(var(--muted) / <alpha-value>)",
          300: "rgb(var(--muted-2) / <alpha-value>)",
          200: "rgb(var(--fg-soft) / <alpha-value>)",
          100: "rgb(var(--fg) / <alpha-value>)",
        },
        accent: {
          DEFAULT: "rgb(var(--accent) / <alpha-value>)",
          soft: "rgb(var(--accent) / 0.12)",
          deep: "rgb(var(--accent-deep) / <alpha-value>)",
        },
        violet: {
          DEFAULT: "rgb(var(--accent-2) / <alpha-value>)",
        },
        success: "rgb(var(--ok) / <alpha-value>)",
        warning: "rgb(var(--warn) / <alpha-value>)",
        danger: "rgb(var(--danger) / <alpha-value>)",
      },
      fontFamily: {
        sans: [
          "var(--font-sans)",
          "Segoe UI Variable Text",
          "Segoe UI",
          "system-ui",
          "sans-serif",
        ],
        mono: [
          "var(--font-mono)",
          "Cascadia Code",
          "JetBrains Mono",
          "Consolas",
          "monospace",
        ],
      },
      boxShadow: {
        panel: "0 1px 0 0 rgb(255 255 255 / 0.03) inset, 0 24px 60px -30px rgb(0 0 0 / 0.8)",
        glow: "0 0 0 1px rgb(var(--accent) / 0.25), 0 8px 30px -12px rgb(var(--accent) / 0.5)",
        float: "0 30px 80px -20px rgb(0 0 0 / 0.75)",
      },
      keyframes: {
        rise: {
          "0%": { opacity: "0", transform: "translateY(6px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        fade: {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
        caret: {
          "0%, 45%": { opacity: "1" },
          "50%, 100%": { opacity: "0" },
        },
        "pulse-dot": {
          "0%, 100%": { opacity: "1", boxShadow: "0 0 0 0 rgb(var(--accent) / 0.5)" },
          "50%": { opacity: "0.65", boxShadow: "0 0 0 4px rgb(var(--accent) / 0)" },
        },
        shimmer: {
          "0%": { backgroundPosition: "-200% 0" },
          "100%": { backgroundPosition: "200% 0" },
        },
        "spin-slow": {
          to: { transform: "rotate(360deg)" },
        },
      },
      animation: {
        rise: "rise 280ms cubic-bezier(0.22, 1, 0.36, 1)",
        fade: "fade 220ms ease-out",
        caret: "caret 1s step-end infinite",
        "pulse-dot": "pulse-dot 2.4s ease-in-out infinite",
        shimmer: "shimmer 2.2s linear infinite",
        "spin-slow": "spin-slow 14s linear infinite",
      },
      transitionTimingFunction: {
        adi: "cubic-bezier(0.22, 1, 0.36, 1)",
      },
    },
  },
  plugins: [],
};

export default config;
