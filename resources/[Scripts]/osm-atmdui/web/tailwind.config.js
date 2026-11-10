/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        fleeca: {
          green: '#2e8b3e',     // buttons
          bright: '#33a34a',    // logo "EE", balances
          shape: '#5db273',     // background triangle
          soft: '#93d3a5',      // background triangle on panel screens
          ink: '#141414',
          paper: '#f3f3f3',
          key: '#e4e4e4',
        },
      },
      fontFamily: {
        cond: ['"Barlow Condensed"', 'sans-serif'],
        sans: ['"Barlow"', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
