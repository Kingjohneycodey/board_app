# Board App

A project management application built with Flutter. This app allows users to create boards, organize them into columns, and manage tasks with tags, deadlines, and comments.

## 🚀 Features

- **Auth System**: Secure login and registration with session management.
- **Board Dashboard**: High-level overview of all projects with pull-to-refresh.
- **Kanban Board**: horizontal scrollable columns with vertical card lists.
- **Card Management**: Full CRUD for cards including descriptions, tags, and due dates.
- **Comments System**: Real-time card commenting with optimistic UI updates.
- **Dark Mode**: Premium dark and light theme support.
- **Onboarding**: Multi-step guide for new users.

## 🏗 Architecture

The project follows a **Feature-First Architecture**. This modular approach ensures that the app remains scalable and maintainable as it grows. Each feature is self-contained, encapsulating its own UI, state, and data logic.

### Structural Overview:

- **`lib/core`**: Contains shared infrastructure used across the entire application.
  - `models`: Global data structures.
  - `services`: Singleton services for low-level operations (e.g., SharedPreferences).
  - `router`: GoRouter configuration for deep-linking and navigation.
  - `theme`: Global styling, color palettes, and theme modes.
  - `widgets`: Reusable, generic UI components (e.g., AppErrorWidget).
- **`lib/features`**: Contains business-logic modules scoped by feature.
  - Each feature folder typically contains:
    - `view`: UI screens and feature-specific widgets.
    - `providers`: State management using Riverpod Notifiers.
    - `repository`: Data fetching logic and API abstractions.

## 🧠 State Management: Riverpod

The application uses **Flutter Riverpod** (specifically the 3.x Notifier API) for state management. This choice was driven by:

1.  **Reactivity**: Seamless UI updates when state changes.
2.  **Testability**: Decoupling business logic from the widget tree makes it easy to unit test.
3.  **Scalability**: Proper scoping prevents "bloated" widgets and ensures each state is easily maintainable.
4.  **AsyncValue**: Built-in handling for loading and error states, ensuring a smooth user experience.

## 📁 Folder Structure Breakdown

```text
lib/
├── core/
│   ├── models/           # Shared models (e.g., User, Board)
│   ├── router/           # Navigation logic (GoRouter)
│   ├── services/         # Storage and external services
│   ├── theme/            # Theme constants and logic
│   └── widgets/          # Shared UI (Empty/Error states)
├── features/
│   ├── auth/             # Login, Register, Session management
│   ├── boards/           # Board list and management
│   ├── profile/          # User settings and theme switching
│   └── workspace/        # Kanban board, columns, and card logic
└── main.dart             # App entry and provider overrides
```

## 📡 API Integration Strategy

The app utilizes a **Repository Pattern** to integrate with external data sources.

- **Data Abstraction**: Repositories act as a bridge between the business logic (Providers) and the data sources (API/Database).
- **Service Layer**: Low-level details (like handling authentication tokens) are isolated into dedicated Service classes.
- **Optimistic Updates**: For high-frequency interactions like adding comments, the app provides immediate UI feedback while the background request resolves.
- **Error Handling**: Standardized error widgets and retry mechanisms are integrated into every data-fetching flow.
