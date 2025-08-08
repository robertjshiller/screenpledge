# ScreenPledge: Architectural Overview & Directory Guide

**Version:** 1.0  
**Date:** August 1, 2025

---

## 1. Introduction: Our Architectural Philosophy

This project is built upon a **Feature-First Clean Architecture**—a modern, scalable approach designed to enforce a strict separation of concerns.

### Core Principles

- **The Dependency Rule:**  
  Inner layers must not know about outer layers. Dependencies always point inward, making business logic independent of UI and database.

- **Feature-First Organization:**  
  Files are grouped by feature (e.g., `dashboard`, `rewards`) rather than by type. Each "vertical slice" is modular, self-contained, and easy to manage.

- **Separation of Concerns:**  
  The architecture is divided into three primary layers:
  - **Presentation:** The UI layer (what the user sees).
  - **Domain:** The business logic layer (the rules of the app).
  - **Data:** The data access layer (how we talk to the outside world).

This document walks through the directory structure, explaining the role of each component within this architectural framework.

---

## 2. The `lib/` Directory: The Root of the Application

The `lib/` folder is the heart of the Flutter project. It is organized into two primary directories: `core/` and `features/`.

- **`main.dart`**  
  The entry point of the application. Responsibilities:
  - Initialize services (like Supabase)
  - Set up the root Riverpod `ProviderScope`
  - Run the main `App` widget

---

## 3. The `core/` Directory: The Shared Foundation

The `core/` folder contains all foundational, shared code required by multiple, unrelated features. It is the stable center of the application.

- **`config/`**  
  App-wide configuration.

- **`router/app_router.dart`**  
  Defines all navigation routes using GoRouter. Single source of truth for navigation.

- **`theme/`**
  - `app_colors.dart`: Const Color definitions for the app's palette.
  - `app_theme.dart`: Defines the main `ThemeData`, including typography.

- **`data/`**  
  Concrete data implementations for universal entities.

- **`models/`**  
  Data Transfer Objects (DTOs) for universal entities. Classes like `UserModel`, `GoalModel` with `fromJson` methods.

- **`datasources/`**  
  Specialist classes that make network calls (e.g., `UserRemoteDataSource` for Supabase profiles).

- **`repositories/`**  
  `RepositoryImpl` classes (e.g., `UserRepositoryImpl`) that implement abstract contracts from `core/domain`. Coordinate data sources and transform Models into Entities.

- **`domain/`**
  - `entities/`: Pure Dart classes representing business objects (e.g., `User`, `Goal`).
  - `repositories/`: Abstract "contracts" defining data layer requirements (e.g., `UserRepository`).

- **`di/service_locator.dart`**  
  The Dependency Injection hub. Global Riverpod Provider definitions for services and repositories.

- **`error/`**  
  App’s error handling model with custom `Exception` and `Failure` classes.

- **`common_widgets/`**  
  Universal, reusable UI components not tied to any specific feature (e.g., `PrimaryButton`, `InputField`).

---

## 4. The `features/` Directory: Modular Verticals

Contains all user-facing, vertical slices of the app. Each feature is a self-contained module.

### Example Feature Modules

---

#### `onboarding_pre_subscription/`
- **Purpose:**  
  Manages the anonymous user journey from first launch to starting a trial.

- **Key Folders:**
  - `domain/usecases/`: Use cases like `GetWeeklyScreenTimeData`.
  - `presentation/`
    - `viewmodels/onboarding_pre_viewmodel.dart`: Riverpod Notifier for pre-subscription state.
    - `views/`: Screens for this funnel (`GetStartedPage`, `PermissionPage`, etc.).

---

#### `onboarding_post_subscription/`
- **Purpose:**  
  Manages mandatory setup for a new, subscribed user.

- **Key Folders:**
  - `data/` & `domain/`: Owns `UserSurvey` entity, includes layers for backend data saving.
  - `presentation/`: Setup screens (`AccountCreationPage`, `UserQuestionnairePage`, `GoalSettingPage`, etc.) and their ViewModel.

---

#### `dashboard/`
- **Purpose:**  
  Main "home" screen for active users.

- **Key Folders:**
  - `domain/usecases/`: Use cases like `GetDashboardData`.
  - `presentation/`
    - `viewmodels/dashboard_viewmodel.dart`: State management for dashboard.
    - `views/`: Pages such as `...GoalPending` and `...GoalActive`.
    - `widgets/`: Complex, feature-specific widgets (`ProgressRing`, `WeeklyProgressChart`).

---

#### `rewards/`
- **Purpose:**  
  Self-contained Rewards Marketplace.

- **Key Folders:**
  - `data/` & `domain/`: Owns `Reward` entity and related logic.
  - `presentation/`: `RewardsPage`, its ViewModel, and widgets (`TierProgressBar`, `RewardCard`).

---

#### `settings/`
- **Purpose:**  
  Hub for user-facing app management.

- **Key Folders:**
  - `domain/usecases/`: Use cases like `PausePledge`.
  - `presentation/`: Main `SettingsPage` and sub-pages (`ManagePledgePage`, `CommunicationsPage`, etc.).

---

