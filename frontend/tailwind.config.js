/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        bg: {
          DEFAULT: '#0b0d12',
          soft: '#11141b',
          card: '#161a23',
          border: '#222836',
        },
        ink: {
          DEFAULT: '#e7e9ee',
          muted: '#9aa3b2',
          dim: '#6b7280',
        },
        brand: {
          DEFAULT: '#7c5cff',
          accent: '#22d3ee',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'Segoe UI', 'sans-serif'],
        serif: ['"Source Serif 4"', 'Georgia', 'serif'],
      },
      boxShadow: {
        card: '0 1px 0 rgba(255,255,255,0.04), 0 8px 24px rgba(0,0,0,0.35)',
      },
    },
  },
  plugins: [],
};
