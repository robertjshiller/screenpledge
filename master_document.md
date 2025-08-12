
---

# **ScreenPledge: The Definitive Master Development Document**

**Version:** 1.3
**Date:** August 3, 2025
**Project:** ScreenPledge – MVP

---

## **1. Vision & Strategy**

### **1.1. Premise & Mission**

ScreenPledge is a mobile application for iOS and Android designed to combat digital distraction. It operates on the principle that true behavioral change is achieved through a combination of self-tracking, positive reinforcement, and meaningful accountability.

Unlike simple blockers, ScreenPledge creates a powerful psychological commitment by allowing users to set an optional, real-money "Accountability Pledge." Success is rewarded through a gamified points system, while failure results in the agreed-upon financial consequence—creating a strong incentive to stay on track.

**Mission:**
To empower individuals to reclaim their time and focus by creating a powerful, positive, and fair accountability system.

### **1.2. Core Principles**

-   **Business Model:** Subscription-first with a 7-day free trial. The app is a premium service.
-   **Design Philosophy:** “Delightful Discipline.” UI/UX must be world-class, inspired by Duolingo and Finch, with a friendly mascot ("Pledgey") central to the experience.
-   **User Experience Philosophy:** “Tough but Fair.” The system is ungameable and holds users to a high standard of accountability, but it is designed with empathy and fairness (e.g., the Forgiveness Rule).

---

## **2. The User Experience (UX) & Feature Set**

### **2.1 The Entry Point: The "Auth Gate"**

Before any onboarding funnel begins, the user journey is controlled by a central "Auth Gate." This gatekeeper is the first thing that loads and is responsible for directing the user to the correct starting screen based on their real-time status. It operates on a strict decision tree:

1.  **Is the user authenticated in Supabase?**
    *   **If YES:** Fetch their application **Profile**. Check the `has_completed_onboarding` flag.
        *   If `true`, navigate to the **Dashboard**.
        *   If `false`, navigate to the next required step in the **Post-Subscription Onboarding** (e.g., `UserSurveyPage`).
2.  **If NO Supabase user, does the user have an active subscription with RevenueCat?**
    *   **If YES:** This is an "Anonymous Subscriber." They have paid but not created an account. Navigate directly to the **`AccountCreationPage`** to force them to link their purchase to a permanent account.
3.  **If NO Supabase user and NO active subscription:**
    *   This is a truly anonymous new user. Navigate to the **`GetStartedPage`** to begin the Pre-Subscription Onboarding flow.

### **2.2. The Onboarding Funnel**

The user journey is split into two distinct phases, managed by two separate features.

#### **2.2.1 Phase A: Pre-Subscription (`onboarding_pre` feature)**

*Goal: Convert an anonymous visitor into a trialist.*

-   **Get Started Page:** "Get Started" and "Log In" options.
-   **Permission Page:** Requests Screen Time access.
-   **Data Reveal Sequence:** Multi-part, animated screen showing the user's screen time percentage and "Top 3 Time Sinks" with app icons.
-   **Solution Page:** A quick page explaining how money backed motivation is effective.
-   **How It Works Sequence:** 4-card carousel explaining the core loop: Pledge → Success → Accountability → Reward.
-   **Subscription Primer:** A page where we prime the user for their subscription.
-   **Subscription Offer Page:** Pricing page where the user commits to the 7-day free trial via native IAP.
-   **Free Trial Explained Page:** Explanation of free trial in 'Blinkist' style.

#### **2.2.2 Phase B: Post-Subscription (`onboarding_post` feature)**

*Goal: Get a new trialist fully configured.*

-   **Account Creation Page:** Shown immediately after trial activation. User creates account (Email/OAuth) and links it to subscription.
-   **User Survey Sequence:** Short survey (age, occupation, purpose, attribution).
-   **Goal Setting Page:** User defines their first daily goal (Total Time vs. Custom Group).
-   **Pledge Page:** Dedicated, persuasive screen for setting the Accountability Pledge.
-   **Notification Permission Dialog:** "Pre-permission" dialog shown after saving accountability.

### **2.3. The Core Application**

#### **2.3.1 Dashboard (`dashboard` feature)**

-   **Dashboard Page:** One unified dashboard with a corresponding viewmodel that will provide different states for the dashboard.

#### **2.3.2 Rewards Marketplace (`rewards` feature)**

-   **Unified, filterable marketplace**
-   **Pledge Tiers:** Progress bar for lifetime PP and progress to next tier (Bronze, Silver, etc.)
-   **Featured Section:** Carousel highlighting high-priority rewards.
-   **Main Grid:** All other rewards (gift cards, donations).

#### **2.3.3 Settings (`settings` feature)**

-   A sectioned list for managing Goal, Pledge, Subscription, Profile, and Communications, as detailed in the brainstormed mockup.

### **2.4. The Modal System (Success/Failure)**

A mandatory, blocking modal appears on app launch to report the previous day's result.

-   **Success Modal:** Celebratory, shows PP earned and streak progress.
-   **Failure Modal:** Empathetic, confirms the pledge was charged, resets streak.

---

## **3. System Logic & Business Rules**

### **3.1. The Pledge Point (PP) Economy**

-   **No Pledge:** 1 PP per success
-   **Pledge Activated:** 10 PP per success
-   **Weekly Streak Bonus (Pledge Required):** +30 PP for a 7-day streak

### **3.2. The "Ungameable" Core Logic**

-   **The “Next Day” Rule:** Any change to goal or pledge takes effect at the next midnight.
-   **Revoke Permission:** Day is Failure, pledge is charged, accountability is paused.
-   **Delete Tracked App:** Day processed based on existing usage data.
-   **Stripe Payment Fails:** Accountability immediately paused.

### **3.3. The "Fairness" Protocols**

-   **Reconciliation Protocol:** For users with a "sync gap," history is reconciled upon return.
-   **Forgiveness Rule:** Only the first day of failure in a sync gap backlog is charged.

### **3.4 The "Superseding" Goal Logic (Immutability)**

The `goals` table is treated as an immutable historical log. A user never "edits" a goal in the database. Instead, an atomic transaction is performed (via a PostgreSQL Function):
1.  The currently active goal has its `status` updated to `'inactive'`.
2.  A new row is `INSERT`ed with the new goal settings and a `status` of `'active'`.

---

## **4. Technical Architecture & Stack**

### **4.1. Technology Stack**

-   **Frontend:** Flutter (iOS & Android)
-   **Backend & Database:** Supabase (PostgreSQL, Auth, Edge Functions, and PostgreSQL Functions (RPC) for atomic database transactions).
-   **Subscriptions (IAP):** RevenueCat
-   **Accountability Pledges (Off-platform):** Stripe

### **4.2. Architecture: Feature-First Clean Architecture**

-   Codebase organized into a `core` folder for shared code, and `features` folders for modular user-facing verticals.
-   Strict separation of concerns; dependencies point inward.

### **4.3. State Management: Riverpod**

-   **Services/Repositories:** Provided via Providers in `core` or feature-specific `di/` folders.
-   **UI State:** Managed by Notifiers within each feature's `presentation/viewmodels/` directory.

### **4.4. Platform-Specific Code (iOS vs. Android)**

-   **Abstraction Layer:** Pure Dart `ScreenTimeService` defined in `core`.
-   **Native Implementation (Android):** Kotlin using `UsageStatsManager` and `PackageManager`.
-   **Native Implementation (iOS):** Swift using `FamilyControls` framework and the `FamilyActivityPicker`.

### **4.5 The Auth Gate & Session Management**

The application's root widget is an `AuthGate` view located in the `auth` feature. This `ConsumerWidget` watches a Riverpod `StreamProvider` connected to Supabase's `onAuthStateChange` stream and is responsible for session management and initial routing, as detailed in Section 2.1.

---

## **5. The Clean Architecture Workflow: A Developer's Guide**

### **5.1. Guiding Principles: The Dependency Rule**

Dependencies must only point **inwards**.

```
+-----------------------------------------------------------------+
|  PRESENTATION (Flutter Widgets, ViewModels)                     |
|        Depends on -> [ Domain Layer ]                           |
|-----------------------------------------------------------------|
|  DOMAIN (Pure Dart Business Logic)                              |
|       - Use Cases, Repository Contracts, Entities              |
|       -> Depends on NOTHING                                     |
|-----------------------------------------------------------------|
|  DATA (Implementations & External Tools)                        |
|       Depends on -> [ Domain Layer ]                            |
|       - Repository Implementations, DataSources                 |
+-----------------------------------------------------------------+
```

### **5.2. The User vs. Profile Distinction: A Core Concept**

To avoid confusion, it is critical to understand the separation between the authentication user and the application profile.

-   **The `User` (from `supabase_flutter`)**
    -   **Represents:** The record in Supabase's private `auth.users` table.
    -   **Purpose:** Authentication and Session Management. Its job is to answer the question, *"Are you who you say you are?"*
    -   **Usage:** Used almost exclusively by the `AuthGate` and auth-related use cases to check for a valid session (`if user != null`). Its `id` is used to link to the profile.

-   **The `Profile` (Our Custom Entity)**
    -   **Represents:** The record in our public `profiles` table.
    -   **Purpose:** Storing Application-Specific Data. Its job is to answer the question, *"What is your status within our app?"*
    -   **Usage:** Used everywhere else. When you need the user's name, `pledge_points`, or `has_completed_onboarding` flag, you must fetch and use the `Profile` entity.

**Guideline:** Never store application-state data in the `User` object's metadata. Always create a `profiles` table and a corresponding `Profile` entity in your app.

### **5.3. The Feature Development Blueprint**

Follow these 8 steps **in order** when building a new feature.

> **Scenario:** We are building the feature to fetch the current user's `Profile`.

---

#### **Phase 1: Define the Business Logic (The Domain Layer)**

*Location: `lib/core/domain/`*

1.  **Create the Entity:** Define the `Profile` class.

    *File: `.../entities/profile.dart`*
    ```dart
    class Profile {
      final String id;
      final String email;
      final int pledgePoints;
      final bool hasCompletedOnboarding;
      // ... other fields
      Profile({required this.id, ...});
    }
    ```

2.  **Create the Repository Contract:** Define the `IProfileRepository` interface.

    *File: `.../repositories/profile_repository.dart`*
    ```dart
    abstract class IProfileRepository {
      Future<Profile> getMyProfile();
    }
    ```

3.  **Create the Use Case:** Create the `GetMyProfile` use case.

    *File: `.../usecases/get_my_profile.dart`*
    ```dart
    class GetMyProfile {
      final IProfileRepository _repository;
      GetMyProfile(this._repository);

      Future<Profile> call() => _repository.getMyProfile();
    }
    ```

---

#### **Phase 2: Implement the Data Handling (The Data Layer)**

*Location: `lib/core/data/`*

4.  **Create the DataSource:** Create `ProfileRemoteDataSource` to talk to Supabase.

    *File: `.../datasources/profile_remote_datasource.dart`*
    ```dart
    class ProfileRemoteDataSource {
      // ... Supabase client setup
      Future<Map<String, dynamic>> fetchProfile(String userId) async {
        // final data = await supabase.from('profiles').select().eq('id', userId).single();
        // return data;
      }
    }
    ```

5.  **Implement the Repository:** Create `ProfileRepositoryImpl`.

    *File: `.../repositories/profile_repository_impl.dart`*
    ```dart
    class ProfileRepositoryImpl implements IProfileRepository {
      // ... constructor and dependencies
      @override
      Future<Profile> getMyProfile() async {
        // final userId = _supabase.auth.currentUser!.id;
        // final rawData = await _remoteDataSource.fetchProfile(userId);
        // return Profile.fromJson(rawData);
      }
    }
    ```

---

#### **Phase 3: Connect the Layers (Dependency Injection)**

*Location: `lib/core/di/`*

6.  **Create the Riverpod Providers:** Create `profile_providers.dart`.

    *File: `.../di/profile_providers.dart`*
    ```dart
    // Provider for DataSource
    final profileDataSourceProvider = Provider((ref) => ...);

    // Provider for Repository
    final profileRepositoryProvider = Provider<IProfileRepository>((ref) => ...);

    // Provider for UseCase
    final getMyProfileUseCaseProvider = Provider((ref) => ...);
    ```

---

#### **Phase 4: Build the User Interface (The Presentation Layer)**

*Location: `lib/features/settings/presentation/`*

7.  **Create the ViewModel:** Create `SettingsViewModel` that calls the use case.

    *File: `.../viewmodels/settings_viewmodel.dart`*
    ```dart
    class SettingsViewModel extends StateNotifier<AsyncValue<Profile>> {
      // ... constructor and fetch logic
    }
    ```

8.  **Create the View:** Create `SettingsPage` that watches the provider.

    *File: `.../views/settings_page.dart`*
    ```dart
    class SettingsPage extends ConsumerWidget {
      // ... build method with state.when(...)
    }
    ```

---

## **6. Database Schema**

-- ScreenPledge Database Schema v1.0
-- Author: Gemini AI
-- Date: August 1, 2025

-- =================================================================
-- SECTION 1: ENUM TYPE DEFINITIONS
-- =================================================================

CREATE TYPE public.accountability_status AS ENUM ('inactive', 'active', 'paused');
CREATE TYPE public.goal_type AS ENUM ('total_time', 'custom_group');
CREATE TYPE public.goal_status AS ENUM ('active', 'inactive', 'paused');
CREATE TYPE public.daily_outcome AS ENUM ('success', 'failure', 'paused', 'forgiven');
CREATE TYPE public.reward_type AS ENUM ('gift_card', 'discount', 'free_trial', 'donation', 'subscription', 'theme');
CREATE TYPE public.reward_tier AS ENUM ('bronze', 'silver', 'gold', 'platinum');

-- =================================================================
-- SECTION 2: TABLE CREATION
-- =================================================================

-- Table: profiles
CREATE TABLE public.profiles (
  id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  full_name text,
  pledge_points integer NOT NULL DEFAULT 0,
  lifetime_pledge_points integer NOT NULL DEFAULT 0,
  streak_count integer NOT NULL DEFAULT 0,
  accountability_status public.accountability_status NOT NULL DEFAULT 'inactive',
  accountability_amount_cents integer NOT NULL DEFAULT 0,
  revenuecat_app_user_id text UNIQUE,
  stripe_customer_id text UNIQUE,
  user_timezone text NOT NULL,
  show_contextual_tips boolean NOT NULL DEFAULT true,
  show_motivational_nudges boolean NOT NULL DEFAULT true,
  has_completed_onboarding boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.profiles IS 'Stores public application data for a user, linked to their auth record.';

-- Table: goals
CREATE TABLE public.goals (
  id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status public.goal_status NOT NULL DEFAULT 'active',
  goal_type public.goal_type NOT NULL,
  time_limit_seconds integer NOT NULL,
  tracked_apps jsonb,
  exempt_apps jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.goals IS 'An immutable log of user-defined goals.';
COMMENT ON COLUMN public.goals.user_id IS 'References the public profile, not the private auth user.';

-- (The rest of the schema remains the same as v1.1)

---

## **7. Directory Structure**

```
# ScreenPledge: Architectural Overview & Directory Guide

## 1. The `lib/` Directory: The Root of the Application

- **`main.dart`**: Entry point. Initializes services, sets up `ProviderScope`.

## 2. The `core/` Directory: The Shared Foundation

Contains foundational, shared code. **If a component (Entity, Repository, Use Case, Provider) is, or could foreseeably be, used by more than one unrelated feature, it belongs in `core`.**

- **`config/`**: App-wide configuration (router, theme).
- **`data/`**: Shared `RepositoryImpl` classes and `DataSources`.
- **`domain/`**: Shared `Entities` and `Repository Contracts`.
- **`di/`**: Global Riverpod `Providers` for core services and shared features.
- **`common_widgets/`**: Universal, reusable, "dumb" UI components (e.g., PrimaryButton).

## 3. The `features/` Directory: Modular Verticals

Contains all user-facing, vertical slices of the app. **Code within a feature folder should generally not be imported by another feature folder.** Features should communicate via the shared use cases and repositories defined in `core`.

- **`auth/`**: Contains the `AuthGate` and all authentication-related screens (Login, Sign Up, Verify).
- **`onboarding_pre/`**
- **`onboarding_post/`**
- **`dashboard/`**
- **`rewards/`**
- **`settings/`**

Each feature folder contains its own `data`, `domain`, and `presentation` layers, specific to that feature.
```