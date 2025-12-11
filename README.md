# 🌱 Ecoins - Sustainable Rewards App

Ecoins is a mobile application built with **Flutter** and **Supabase** that gamifies eco-friendly habits. Users earn points for sustainable activities (like biking, recycling, conserving energy) and redeem them for real-world rewards from partner brands.

## 🚀 Features

*   **Impact Dashboard**: Track your CO₂ savings and Points balance.
*   **Activity Logging**: Quickly log sustainable actions with a carbon calculator.
*   **Rewards Marketplace**: Redeem points for exclusive brand offers.
*   **Gamification**: Daily challenges, Leaderboards, and Streaks.
*   **Social**: Add friends, view activity feeds, and compete.
*   **Brand API**: Secure Edge Functions for brands to manage rewards and view analytics.

## 🛠️ Tech Stack

*   **Frontend**: Flutter (Dart) - iOS & Android
*   **Backend**: Supabase (PostgreSQL)
*   **Auth**: Supabase Auth (Email/Password, Google Sign-In)
*   **State Management**: Provider (Simple & Scalable)
*   **Navigation**: GoRouter

## 🏃‍♂️ Getting Started

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install/windows)
*   VS Code or Android Studio

### Installation

1.  **Clone the repository** (or open this folder).
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the App**:
    ```bash
    flutter run
    ```

### 🔑 Authentication Setup
This project uses Supabase Auth.
*   **Google Sign-In**: Requires configuring SHA-1 keys in Google Cloud Console and adding Client IDs to `lib/ui/screens/login_screen.dart`.

## 💻 Admin Web Portal
Located in `admin-dashboard/`.
*   **Run**: `cd admin-dashboard && npm install && npm run dev`
*   **Features**: Manage Rewards, View Analytics.

## 📁 Project Structure

```
admin-dashboard/    # React Web Portal
lib/
├── core/           # Constants, Theme, Utils
├── data/           # Supabase Client, Repositories
├── ui/
│   ├── screens/    # Full page widgets (Home, Profile, etc.)
│   └── widgets/    # Reusable components (Cards, Modals)
└── main.dart       # Entry point
```

## 🎨 Asset Generation
*   **App Icons**: `flutter pub run flutter_launcher_icons:main` (Requires `icon.png` in root)
*   **Splash Screen**: configured in `lib/ui/screens/splash_screen.dart`.

## 🤝 Contributing
1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request
