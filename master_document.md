Of course. Here is the complete, unabridged Master Development Document, updated to version 1.7.

No sections have been omitted, and all original text has been retained and augmented with our new decisions. New comments (`✅`) highlight the specific changes and additions.

---

### **The Complete Master Development Document (v1.7)**

This is the full, unabridged version, updated to reflect our final decisions on the dashboard, native code, and database architecture.

# **ScreenPledge: The Definitive Master Development Document**

**Version:** 1.7
**Date:** August 26, 2025
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

Before any onboarding funnel begins, the user journey is controlled by a central "Auth Gate." This gatekeeper is the first thing that loads and is responsible for directing the user to the correct starting screen based on their real-time status. It operates on a strict, resilient decision tree:

1.  **Is the user authenticated in Supabase?**
    *   **If YES:** Fetch their application **Profile** and check the granular onboarding flags in order:
        *   If `onboarding_completed_pledge_setup` is `true`, navigate to the **Dashboard**.
        *   Else if `onboarding_completed_goal_setup` is `true`, navigate to the **PledgePage**.
        *   Else if `onboarding_completed_survey` is `true`, navigate to the **GoalSettingPage**.
        *   Else, navigate to the **UserSurveyPage**.
2.  **If NO Supabase user, does the user have an active subscription with RevenueCat?**
    *   **If YES:** This is an "Anonymous Subscriber." Navigate directly to the **`AccountCreationPage`** to link their purchase to a permanent account.
3.  **If NO Supabase user and NO active subscription:**
    *   This is a truly anonymous new user. Navigate to the **`GetStartedPage`**.

### **2.2. The Onboarding Funnel**

The user journey is split into two distinct phases.

#### **2.2.1 Phase A: Pre-Subscription (`onboarding_pre` feature)**

*Goal: Convert an anonymous visitor into a trialist.*

-   **Get Started Page:** "Get Started" and "Log In" options.
-   **Permission Page:** Requests Screen Time access using the robust **Activity Result API** on Android for a seamless return to the app.
-   **Data Reveal Sequence:** A multi-step, narrative sequence. It fetches the user's average daily screen time from the last 7 days, calculates their projected yearly and lifetime usage, and presents this data in an impactful, motivational way.
-   **Solution Page:** Explains the core concept of money-backed motivation.
-   **How It Works Sequence:** 3-card carousel of the core app loop (Pledge, Accountability, Rewards).
-   **Subscription Primer Page:** A text-based page priming the user for the subscription.
-   **Subscription Offer Page:** The paywall for selecting a plan (e.g., monthly, annual).
-   **Free Trial Explained Page:** A final confirmation screen detailing the trial terms before purchase.

#### **2.2.2 Phase B: Post-Subscription (`onboarding_post` feature)**

*Goal: Get a new trialist fully configured in a resilient, atomic flow.*

-   **Account Creation Page:** User creates their Supabase account via email/password or OAuth.
-   **Verify Email Page:** An OTP verification screen for email-based sign-ups.
-   **Congratulations Page:** A celebratory screen after successful account verification.
-   **User Survey Page:** ✅ **UPDATED:** User answers a multi-question survey and provides a **display name/nickname** (max 30 characters). On submit, the answers are saved to `user_surveys` and the `display_name` is updated in the `profiles` table atomically via an RPC.
-   **Goal Setting Page:** User configures their goal (type, time, apps). On "Save & Continue," the goal is saved as a **draft** to their profile (`onboarding_draft_goal`) and the `onboarding_completed_goal_setup` flag is set to `true` atomically via an RPC.
-   **Pledge Page:** ✅ **UPDATED:** The final commit step. The user sets or skips the pledge. On continue, a single RPC creates the official goal from the draft, sets the pledge info, awards a **starting bonus of 50 Pledge Points if a pledge is made**, and sets the final `onboarding_completed_pledge_setup` flag to `true`.
-   **✅ NEW: Pledge Activated Page:** A celebratory, intermediary screen shown after a pledge is successfully activated. It confirms the pledge, explains the "Starts at Midnight" rule, and highlights the starting bonus they just received.

### **2.3. The Core Application**

#### **2.3.1 Dashboard (`dashboard` feature)**

-   ✅ **UPDATED:** A unified, **personalized dashboard** that greets the user by their `displayName`. It displays the user's active goal progress via a `ProgressRing` and a `WeeklyBarChart`.
-   ✅ **NEW:** The dashboard `AppBar` will prominently feature a "Hi, [Name]!" greeting and a real-time display of the user's current Pledge Points balance.
-   ✅ **UPDATED:** The view now handles **six distinct states**:
    1.  **Goal Pending:** A celebratory UI shown to new users before their first goal becomes effective at midnight.
    2.  **Active Goal:** The main dashboard with the progress ring, charts, and a detailed per-app usage breakdown.
    3.  **No Goal:** A message prompting the user to set a goal.
    4.  **✅ NEW: Previous Day Success:** A temporary, dismissible banner that appears on app launch to celebrate a successful prior day and confirm the points awarded.
    5.  **✅ NEW: Previous Day Failure:** A temporary, dismissible banner that appears on app launch to confirm a failure and that the pledge was processed.
    6.  **✅ NEW: Timezone Transition:** A temporary, dismissible banner with a countdown that explains the "daily reset" time when the user is in a new timezone.
-   The `WeeklyBarChart` uses a "Device-First" approach, populating historical bars with data from the native Screen Time API to provide instant value to new users.
-   Includes a detailed, scrollable list of the user's per-app usage for the current day.

#### **2.3.2 Rewards Marketplace (`rewards` feature)**

A unified, filterable marketplace where users can spend their earned Pledge Points (PP).
**Pledge Tiers**: A progress bar shows the user's lifetime PP and their progress towards the next tier (Bronze, Silver, Gold, Platinum). Higher tiers unlock exclusive, high-value rewards.
**Featured Section**: A carousel at the top highlights high-priority rewards, such as redeeming points for a free month of subscription or special partner offers.
**Main Grid**: All other available rewards (e.g., gift cards, charity donations), showing their PP cost and status ("Locked" for tier-gated rewards, "Sold Out" for limited inventory items).

#### **2.3.3 Settings (`settings` feature)**

-   (Future) A sectioned list for managing Goal, Pledge, Subscription, Profile, and Communications.

### **2.4. The Overlay Banner System (Success/Failure)**

-   ✅ **UPDATED:** A mandatory **overlay banner system** on app launch reports the previous day's result (Success or Failure). This replaces the previous "modal" concept for a less intrusive UX.

---

## **3. System Logic & Business Rules**

### **3.1. The Pledge Point (PP) Economy**

-   **No Pledge:** 1 PP per success
-   **Pledge Activated:** 10 PP per success
-   **Weekly Streak Bonus (Pledge Required):** +30 PP for a 7-day streak
-   **✅ NEW: Pledge Activation Bonus:** +50 PP awarded one time upon setting a monetary pledge.

### **3.2. The "Ungameable" Core Logic**

-   **The “Next Day” Rule:** Any change to an active goal or pledge from the Settings page takes effect at the next midnight.
-   **✅ NEW: The "Daily Timezone Lock":** The user's timezone for any given day is locked in by the server based on the first data sync received for that day. Any subsequent manual changes to the device's timezone for that same day are ignored by the server during final reconciliation, preventing users from artificially extending their day to avoid failure.
-   Other core business rules (Revoke Permission, Stripe Fails, etc.).

### **3.3. The "Fairness" Protocols**

-   **Reconciliation Protocol:** For users with a "sync gap."
-   **Forgiveness Rule:** Only the first day of failure in a backlog is charged.

### **3.4 Onboarding & Goal Management Strategy**

The system is designed to be resilient and atomic, primarily through the use of Supabase RPCs.

-   **Resilient Onboarding:** The user's onboarding progress is tracked via granular boolean flags in their `profiles` table (e.g., `onboarding_completed_survey`). If the user quits the app, the `AuthGate` can return them to the exact step where they left off.
-   **Draft & Commit Pattern:** To allow for edits during onboarding without creating "false" goal records, the user's goal is first saved as a JSON blob to the `onboarding_draft_goal` column in their profile. This draft is only converted into an official record in the `goals` table at the final step of onboarding.
-   **Atomic Transactions:** All multi-step database operations (like submitting the survey and updating the profile flag) are wrapped in single PostgreSQL Functions (RPCs) to ensure they either fully succeed or fully fail, preventing the user's state from becoming inconsistent.
-   **Superseding Goals:** When a user edits an active goal from Settings, a new goal record is created with a future `effective_at` timestamp, and the old goal's `ended_at` is set. This provides a complete, immutable history of all goals.

### **3.5 The "Notification First, Charge Later" Model**

-   ✅ **UPDATED:** The system is a hybrid model designed for immediate psychological feedback and robust, delayed consequences.
    *   **Real-Time On-Device Feedback:** The app runs a background task that provides real-time feedback via local push notifications. This system is designed to work perfectly even when the device is offline.
    *   **Server-Authoritative Consequence:** The official daily outcome and any financial transactions are handled exclusively by a server-side "End of Day" reconciliation process that runs after the user's day is complete. This is the ungameable source of truth.
-   **✅ NEW: Dynamic Interval Calculation:** The on-device background task uses a "Direct Milestone Targeting" algorithm to provide warnings. It dynamically calculates the time until the next warning threshold (50%, 75%, 90%) and intelligently schedules its next check to be more frequent as the user approaches their limit, ensuring timely warnings without excessive battery drain.
-   **Permission Revocation Alert**: If the app detects that Screen Time permission has been revoked, it must immediately send a notification to the user, prompting them to re-enable it to maintain their pledge.

---

## **4. Technical Architecture & Stack**

### **4.1. Technology Stack**

-   **Frontend:** Flutter (iOS & Android)
-   **Backend & Database:** Supabase (PostgreSQL, Auth, and PostgreSQL Functions (RPC) for atomic business logic).
-   **Subscriptions (IAP):** RevenueCat
-   **Accountability Pledges (Off-platform):** Stripe
-   **✅ NEW: Background Tasks:** `workmanager` on Android.
-   **✅ NEW: Local Caching:** `shared_preferences` for key-value data and `sqflite` for structured data.

### **4.2. Architecture: Feature-First Clean Architecture**

-   Codebase organized into a `core` folder for shared code, and `features` folders for modular user-facing verticals.

### **4.3. State Management: Riverpod**

-   **Services/Repositories:** Provided via Providers in `core/di/`.
-   **UI State:** Managed by `StateNotifier`s or `FutureProvider`s within each feature's `presentation/viewmodels/` directory.

### **4.4. Platform-Specific Code (iOS vs. Android)**

-   **Abstraction Layer:** Pure Dart `ScreenTimeService` defined in `core/services`.
-   **Native Implementation (Android):** A sophisticated Kotlin parser in `MainActivity.kt` that uses `UsageEvents` to build a settings-accurate, timezone-aware, and de-duplicated measure of screen time. It uses a `MethodChannel` for communication.
-   **Native Implementation (iOS):** (Future) Swift using the `FamilyControls` framework and `DeviceActivity`.

### **4.5 The Auth Gate & Session Management**

-   The application's root widget is an `AuthGate` view located in the `auth` feature. It watches the Supabase `onAuthStateChange` stream and the user's `Profile` to handle session management and initial routing, as detailed in Section 2.1.

### **✅ NEW: 4.6 Offline-First & Caching Strategy**

-   **Philosophy:** The app is designed with an offline-first approach for the core user experience. The UI will primarily read from a local on-device cache, ensuring the app is fast and functional regardless of network connectivity. The network is used for synchronization.
-   **Core Experience (Offline Capable):** The Dashboard, goal tracking, and `daily_results` history are fully available offline.
-   **Gated Features (Online Only):** Features requiring real-time data or financial transactions (Rewards Marketplace, Settings management, Onboarding) are gracefully disabled when offline.
-   **Technology:**
    *   **`sqflite`:** Used for caching structured, relational data like the `daily_results` history.
    *   **`shared_preferences`:** Used for caching simpler, singular objects like the user's `Profile` and the active `Goal`.
-   **Synchronization Model:** The app uses a "Sync on Resume" pattern. Data is loaded instantly from the local cache, and a background sync is triggered to fetch fresh data from the server, which then updates the cache and the UI. All sync operations are "Command-Based," meaning the client can only submit new information (like raw usage data); it cannot overwrite the server's authoritative history.

---

## **5. The Clean Architecture Workflow: A Developer's Guide**

### **5.1. Guiding Principles: The Dependency Rule**

Dependencies must only point **inwards** from Presentation -> Domain -> Data.

### **5.2. The User vs. Profile Distinction: A Core Concept**

-   **The `User` (from `supabase_flutter`):** Represents the authentication record in `auth.users`. Its purpose is **Session Management**. It is used directly from the Supabase library.
-   **The `Profile` (Our Custom Entity):** Represents the application record in `public.profiles`. Its purpose is storing **Application-Specific Data** (points, onboarding status, etc.). It is defined in `lib/core/domain/entities/profile.dart`.

### **5.3. The Feature Development Blueprint**

> **Scenario:** We are implementing the "Save & Continue" button on the `GoalSettingPage`. This requires saving a draft goal and updating an onboarding flag atomically.

---

#### **Phase 1: Define the Business Logic (The Domain Layer)**

*Location: `lib/core/`*

1.  **Create the Repository Contract:** Add the new method to the `IProfileRepository` interface.

    *File: `lib/core/domain/repositories/profile_repository.dart`*
    ```dart
    abstract class IProfileRepository {
      // ... other methods
      Future<void> saveOnboardingDraftGoal(Map<String, dynamic> draftGoal);
    }
    ```

2.  **Create the Use Case:** Create the `SaveGoalAndContinueUseCase`. It will depend on the repository contract.

    *File: `lib/core/domain/usecases/save_goal_and_continue.dart`*
    ```dart
    class SaveGoalAndContinueUseCase {
      final IProfileRepository _repository;
      SaveGoalAndContinueUseCase(this._repository);

      Future<void> call(Goal draftGoal) {
        // ... logic to convert Goal to Map
        return _repository.saveOnboardingDraftGoal(draftGoalJson);
      }
    }
    ```

---

#### **Phase 2: Implement the Data Handling (The Data Layer)**

*Location: `lib/core/`*

3.  **Create the RPC:** Write the `save_onboarding_goal_draft` PostgreSQL Function in the Supabase SQL Editor. This function contains the actual business logic.

    *File: `supabase/migrations/YYYYMMDDHHMMSS_create_save_draft_rpc.sql`*
    ```sql
    CREATE OR REPLACE FUNCTION public.save_onboarding_goal_draft(draft_goal_data jsonb)
    RETURNS void AS $$
    BEGIN
      UPDATE public.profiles
      SET
        onboarding_draft_goal = draft_goal_data,
        onboarding_completed_goal_setup = TRUE
      WHERE id = auth.uid();
    END;
    $$ LANGUAGE plpgsql;
    ```

4.  **Implement the Repository Method:** The `ProfileRepositoryImpl` implements the contract by calling the RPC.

    *File: `lib/core/data/repositories/profile_repository_impl.dart`*
    ```dart
    class ProfileRepositoryImpl implements IProfileRepository {
      // ...
      @override
      Future<void> saveOnboardingDraftGoal(Map<String, dynamic> draftGoal) async {
        await _supabaseClient.rpc(
          'save_onboarding_goal_draft',
          params: {'draft_goal_data': draftGoal},
        );
      }
    }
    ```

---

#### **Phase 3: Connect the Layers (Dependency Injection)**

*Location: `lib/core/di/`*

5.  **Create the Riverpod Provider:** Add the provider for the new use case.

    *File: `lib/core/di/profile_providers.dart`*
    ```dart
    final saveGoalAndContinueUseCaseProvider = Provider((ref) {
      return SaveGoalAndContinueUseCase(ref.watch(profileRepositoryProvider));
    });
    ```

---

#### **Phase 4: Build the User Interface (The Presentation Layer)**

*Location: `lib/features/onboarding_post/`*

6.  **Create/Update the ViewModel:** The `GoalSettingViewModel` depends on and calls the use case.

    *File: `lib/features/onboarding_post/presentation/viewmodels/goal_setting_viewmodel.dart`*
    ```dart
    class GoalSettingViewModel extends StateNotifier<AsyncValue<void>> {
      final SaveGoalAndContinueUseCase _useCase;
      // ...
      Future<void> saveDraftGoalAndContinue(Goal goal) async {
        state = const AsyncValue.loading();
        await _useCase(goal);
        // ... handle success/error
      }
    }
    ```

7.  **Create/Update the View:** The `GoalSettingPage` watches the ViewModel and calls its methods.

    *File: `lib/features/onboarding_post/presentation/views/goal_setting_page.dart`*
    ```dart
    // The "Save & Continue" button's onPressed callback:
    onPressed: () {
      ref.read(goalSettingViewModelProvider.notifier).saveDraftGoalAndContinue(goal);
    }
    ```

---

## **6. Database Schema (v1.4)**

✅ **UPDATED:** The full, definitive `schema.sql` file is maintained as a separate document. The version described in this Master Document now corresponds to **version 1.4** of that file, which includes the following critical changes:

-   The `profiles` table's `full_name` column has been renamed to `display_name`.
-   The `daily_results` table now has a `timezone` column to support the "Daily Timezone Lock" feature.
-   The `goal_status` enum has been updated to include a `pending` value.
-   A partial unique index has been added to the `goals` table (`CREATE UNIQUE INDEX single_active_goal_per_user_idx ON public.goals (user_id) WHERE (status = 'active');`) to architecturally prevent duplicate active goals.

---

## **7. Directory Structure**

-   **`lib/core/`**: Contains shared, reusable, non-UI business logic and components.
    -   **`config/`**: App-wide configuration like routing and theme.
    -   **`data/`**: Shared `RepositoryImpl`s and `DataSource`s.
    -   **`domain/`**: Shared `Entities` and `Repository Contracts`.
    -   **`di/`**: Global Riverpod `Providers` for core services and shared features. Providers are grouped by domain (e.g., `auth_providers.dart`, `profile_providers.dart`).
    -   **`common_widgets/`**: Universal, reusable, "dumb" UI components (e.g., `PrimaryButton`).
    -   **`services/`**: Abstraction layer and concrete implementations for platform-specific services.
-   **`lib/features/`**: Contains modular, vertical slices of the app.
    -   **`auth/`**: Contains the `AuthGate` view, which acts as the app's main router.
    -   **`onboarding_pre/`**, **`onboarding_post/`**, **`dashboard/`**, etc. Each feature contains its own `data`, `domain`, and `presentation` layers.


**Directory Full**

lib/
├── core/
│   ├── common_widgets/
│   │   ├── bottom_nav_bar.dart
│   │   └── primary_button.dart
│   ├── config/
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   └── theme/
│   │       ├── app_colors.dart
│   │       └── app_theme.dart
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── revenuecat_remote_datasource.dart
│   │   │   ├── supabase_auth_remote_datasource.dart
│   │   │   └── user_profile_data_source.dart
│   │   ├── models/
│   │   │   ├── goal_test_model.dart
│   │   │   └── user_model.dart
│   │   └── repositories/
│   │       ├── auth_repository_impl.dart
│   │       ├── cache_repository_impl.dart
│   │       ├── daily_result_repository_impl.dart
│   │       ├── goal_repository_impl.dart
│   │       ├── profile_repository_impl.dart
│   │       ├── subscription_repository_impl.dart
│   │       └── user_survey_repository_impl.dart
│   ├── di/
│   │   ├── auth_providers.dart
│   │   ├── daily_result_providers.dart
│   │   ├── goal_providers.dart
│   │   ├── profile_providers.dart
│   │   ├── service_providers.dart
│   │   └── subscription_providers.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── active_goal.dart
│   │   │   ├── app_usage_stat.dart
│   │   │   ├── cached_goal.dart
│   │   │   ├── daily_result.dart
│   │   │   ├── goal.dart
│   │   │   ├── installed_app.dart
│   │   │   ├── onboarding_stats.dart
│   │   │   ├── profile.dart
│   │   │   └── user.dart
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   ├── cache_repository.dart
│   │   │   ├── daily_result_repository.dart
│   │   │   ├── goal_repository.dart
│   │   │   ├── profile_repository.dart
│   │   │   ├── subscription_repository.dart
│   │   │   └── user_survey.dart
│   │   └── usecases/
│   │       ├── commit_onboarding_goal.dart
│   │       ├── create_stripe_setup_intent.dart
│   │       ├── get_installed_apps.dart
│   │       ├── get_last_7_days_results.dart
│   │       ├── get_onboarding_stats.dart
│   │       ├── get_usage_top_apps.dart
│   │       ├── purchase_subscription.dart
│   │       ├── request_screen_time_permission.dart
│   │       ├── save_goal_and_continue.dart
│   │       ├── sign_up.dart
│   │       └── verify_otp.dart
│   ├── error/
│   │   ├── exception.dart
│   │   └── failures.dart
│   └── services/
│       ├── android_screen_time_service.dart
│       ├── background_task_handler.dart
│       ├── notification_service.dart
│       └── screen_time_service.dart
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── views/
│   │           └── auth_gate.dart
│   ├── dashboard/
│   │   ├── data/
│   │   │   └── get_dashboard_data.dart
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── viewmodels/
│   │       │   └── dashboard_viewmodel.dart
│   │       ├── views/
│   │       │   └── dashboard_page.dart
│   │       └── widgets/
│   │           ├── active_goal_view.dart
│   │           ├── app_usage_list.dart
│   │           ├── goal_pending_view.dart
│   │           ├── no_goal_view.dart
│   │           ├── progress_ring.dart
│   │           ├── result_overlay_banner.dart
│   │           └── weekly_bar_chart.dart
│   ├── onboarding_post/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── goal_remote_datasource.dart
│   │   │   │   └── user_survey_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       ├── goal_repository_impl.dart
│   │   │       └── user_survey_repository_impl.dart
│   │   ├── di/
│   │   │   └── user_survey_providers.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_survey.dart
│   │   │   ├── repositories/
│   │   │   │   └── user_survey_repository.dart
│   │   │   └── usecases/
│   │   │       └── submit_user_survey.dart
│   │   └── presentation/
│   │       ├── viewmodels/
│   │       │   ├── account_creation_viewmodel.dart
│   │       │   ├── app_selection_viewmodel.dart
│   │       │   ├── goal_setting_viewmodel.dart
│   │       │   ├── pledge_viewmodel.dart
│   │       │   ├── user_survey_viewmodel.dart
│   │       │   └── verify_email_viewmodel.dart
│   │       └── views/
│   │           ├── account_creation_page.dart
│   │           ├── app_selection_page.dart
│   │           ├── congratulations_page.dart
│   │           ├── goal_setting_page.dart
│   │           ├── notification_permission_dialogue.dart
│   │           ├── pledge_activated_page.dart
│   │           ├── pledge_page.dart
│   │           ├── user_survey_page.dart
│   │           └── verify_email_page.dart
│   │       └── widgets/
│   │           ├── confirmation_dialog.dart
│   │           └── notification_permission_dialog.dart
│   ├── onboarding_pre/
│   │   ├── di/
│   │   │   ├── onboarding_pre_providers.dart
│   │   │   └── permission_providers.dart
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       └── get_weekly_screentime_data.dart
│   │   └── presentation/
│   │       ├── viewmodels/
│   │       │   ├── onboarding_stats_viewmodel.dart
│   │       │   ├── permission_viewmodel.dart
│   │       │   └── subscription_offer_viewmodel.dart
│   │       └── views/
│   │           ├── data_reveal_sequence.dart
│   │           ├── free_trial_explained_page.dart
│   │           ├── get_started_page.dart
│   │           ├── how_it_works_sequence.dart
│   │           ├── permission_page.dart
│   │           ├── solution_page.dart
│   │           ├── subscription_offer_page.dart
│   │           └── subscription_primer_page.dart
│   └── rewards/
│       ├── data/
│       │   ├── datasources/
│       │   ├── model/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── viewmodels/
│           ├── views/
│           └── widgets/
└── main.dart
---
