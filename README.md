# AedusWeb 🚀

**AedusWeb** is a high-performance, premium Dart/Flutter application designed for mission-critical operations, incident management, and real-time communication. Migrated from a robust legacy architecture, this version features a state-of-the-art **Dark Theme** designed for elite user experience and AI-driven efficiency.

## ✨ Key Features

- **Dashboard Intelligence**: Dynamic KPI tracking and trend analysis using `fl_chart`.
- **Aedus AI Engine**: AI-assisted incident categorization and solution suggestions powered by **Groq / Llama 3.3**.
- **Connect Hub**: A triple-panel communication center featuring real-time chat, contact management, and contextual details.
- **Incident Management**: Dual-panel ticketing system with image attachment capability and status tracking.
- **Gamification System**: Integrated **AeduCoins** and achievement tracking to boost team productivity.
- **Robust Backend**: Seamless integration with **Neon PostgreSQL** and **Cloudinary** for high-availability data and image storage.

## 🎨 Design Philosophy (Premium Dark)

Aedus uses a custom-tuned **"Premium Dark"** design system:
- **Primary Blue**: `#4F8EF7` (Precision UI)
- **Secondary Indigo**: `#818CF8` (State emphasis)
- **Background**: `#060D1C` (Deep space blue)
- **Typography**: Optimized Inter (Google Fonts) with advanced hierarchy.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Database**: [PostgreSQL (Neon)](https://neon.tech)
- **AI Integration**: [Groq Cloud (Llama 3.3)](https://groq.com)
- **Styling**: Vanilla Flutter Custom Theme
- **Assets**: [Font Awesome](https://fontawesome.com)

## 🚀 Getting Started

1.  **Clone the Repo**:
    ```bash
    git clone https://github.com/YourUser/AedusWeb.git
    ```
2.  **Configuration**: Create a `.env` file in the root directory:
    ```env
    DB_URL=your_postgres_url
    DB_USER=your_user
    DB_PASS=your_pass
    AI_API_KEY=your_groq_key
    AI_MODEL=llama-3.3-70b-versatile
    ```
3.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
4.  **Run the App**:
    ```bash
    flutter run
    ```

---
*Created with ❤️ by the Aedus Team.*
