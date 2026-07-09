# Pro-Inspector Daily Tracker 🚀

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white) ![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black) ![Riverpod](https://img.shields.io/badge/Riverpod-State%20Management-blue)

**Pro-Inspector Daily Tracker** (by Mayvel) is an enterprise-grade Daily Matrix Planner designed to help teams prioritize tasks using the Eisenhower Matrix (Quadrants) and track their daily productivity with advanced analytics. 

## ✨ Key Features

- **Auth & Secure Sync**: Firebase Authentication and Firestore real-time cloud sync ensures your tasks securely follow you everywhere.
- **Eisenhower Quadrant System**: Categorize your tasks efficiently.
  - 🔥 **Do First (Q1)** - Urgent & Important
  - 📅 **Schedule (Q2)** - Important, Not Urgent
  - 🤝 **Delegate (Q3)** - Urgent, Not Important
  - 🗑️ **Drop/Later (Q4)** - Not Urgent & Not Important
- **Advanced Dashboard & Intelligence**: 
  - **Focus Score**: Calculates percentage of completed tasks that fall into high-priority output.
  - **Rollover Index**: Tracks accumulated days tasks have been delayed or carried over.
  - **7-Day Moving Average** & Weekly charts.
  - Interactive, dynamic popups for all metrics.
- **Visual Flourishes**: Next-generation UI utilizing fluid `.animate()` features, soft glow filters, and full 3D animated assets (like the floating isometric gem).
- **Responsive Layout**: Seamlessly adapts from desktop web browsers down to mobile phone form factors.

## 🛠 Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: [Riverpod (v2)](https://riverpod.dev/) for robust, testable state handling.
- **Backend / Database**: Firebase (Auth & Firestore)
- **Routing**: `go_router` for deep linking and declarative web routing.
- **Animations**: `flutter_animate` for smooth, multi-stage staggered animations.

## 📂 Project Structure

```text
lib/
├── core/             # Global configurations, top-level providers, and themes
├── features/         # Feature-based modular structure
│   ├── auth/         # Login, Auth state, Firebase configuration
│   ├── dashboard/    # KPI charts, interactive visualizations, moving averages
│   └── planner/      # Task management, quad sorting, persistence logic
├── shared/           # Reusable components, helpers, and state models
│   ├── models/       # Data models (TaskModel, DayData, User)
│   ├── widgets/      # Shared scaffold, navigation sidebars
│   └── utils/        # Pure computation functions (e.g., dashboard_calcs.dart)
```

## 🚀 Getting Started

### Prerequisites

1. Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
2. Install [Firebase CLI](https://firebase.google.com/docs/cli) and flutterfire CLI if you intend to configure a new Firebase project.

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository_url>
   cd daily-task-tracker-site
   ```

2. **Fetch Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Code Generation:**
   The project uses `riverpod_generator`. Run the build runner to generate Riverpod providers:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   *(Or run it in watch mode during development: `dart run build_runner watch`)*

4. **Run the App:**
   ```bash
   flutter run -d chrome
   ```

## 🧪 Testing

The codebase is engineered with pure, testable calculation functions (`shared/utils/dashboard_calcs.dart`). 
Execute the test suite using:
```bash
flutter test
```

## 🎨 UI/UX Philosophy
The UI follows a soft "Glassmorphism & Crisp White" language. Key colors are drawn from the `AppTheme` class (lib/core/theme.dart). It focuses on minimizing cognitive load while keeping motivation high via subtle gamification (e.g., Daily Streaks).

---
*Developed with focus, built for productivity.*
