/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        forest: {
          50: '#f0f7f4',
          100: '#dbeee5',
          500: '#2b7a5a',
          700: '#1e5a42',
          800: '#174734',
          900: '#13392a',
          DEFAULT: '#1B4D3E',
        },
        gold: {
          50: '#fbf9f0',
          100: '#f6f1da',
          400: '#e5c968',
          500: '#D4AF37',
          600: '#b89427',
        },
        charcoal: '#1F2937',
      }
    },
  },
  plugins: [],
}
