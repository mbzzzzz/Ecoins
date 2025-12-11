# 🌱 EcoAdmin Portal

A React + Vite dashboard for managing Ecoins rewards and analyzing data.

## 🚀 Getting Started

1.  **Install Dependencies**
    ```bash
    npm install
    ```
    *Required: `react-router-dom`, `recharts`, `lucide-react`, `@supabase/supabase-js`, `vite`.*

2.  **Environment Setup**
    Ensure `.env` exists with `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.

3.  **Run Development Server**
    ```bash
    npm run dev
    ```

## 🛠️ Features

*   **Dashboard**: View total users, active brands, and CO2 saved.
*   **Rewards**: Create, edit, and delete rewards.
*   **Brands**: View registered brands and webhook status.

## 📦 Build for Production

```bash
npm run build
```
The output will be in `dist/`. You can deploy this to Vercel, Netlify, or AWS S3.
