/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,jsx}"
  ],
  theme: {
    extend: {
      colors: {
        primary: "#f27f0d",
        "background-light": "#f8f7f5",
        "background-dark": "#221910",
      },

      fontFamily: {
        sans: ["Sarabun", "sans-serif"],
        lanna: ["LannaAkkhara", "serif"],
      },

      keyframes: {
        fadeInScale: {
          "0%":   { opacity: "0", transform: "scale(0.88)" },
          "100%": { opacity: "1", transform: "scale(1)" },
        },
      },
      animation: {
        fadeInScale: "fadeInScale 0.25s ease-out",
      },
    },
  },
  plugins: [],
};
