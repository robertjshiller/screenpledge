### **The Complete Master Development Document (v1.5)**

# **ScreenPledge: The Definitive Master Development Document**

**Version:** 1.5
**Date:** August 22, 2025
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
-   **Permission Page:** Requests Screen Time access using a "fire and re-check" strategy.
-   **Data Reveal Sequence:** A multi-step sequence revealing screen time impact.
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
-   **User Survey Page:** User answers a multi-question survey. On submit, the answers are saved and the `onboarding_completed_survey` flag is set to `true` atomically via an RPC.
-   **Goal Setting Page:** User configures their goal (type, time, apps). On "Save & Continue," the goal is saved as a **draft** to their profile (`onboarding_draft_goal`) and the `onboarding_completed_goal_setup` flag is set to `true` atomically via an RPC.
-   **Pledge Page:** The final commit step. The user sets or skips the pledge. On continue, a single RPC creates the official goal from the draft, sets the pledge info, and sets the final `onboarding_completed_pledge_setup` flag to `true`.

### **2.3. The Core Application**

#### **2.3.1 Dashboard (`dashboard` feature)**

-   A unified dashboard displaying the user's active goal progress via a `ProgressRing` and a `WeeklyBarChart`. The view handles states for when a goal is active or not found.

#### **2.3.2 Rewards Marketplace (`rewards` feature)**

-   (Future) A unified, filterable marketplace for redeeming Pledge Points.

#### **2.3.3 Settings (`settings` feature)**

-   (Future) A sectioned list for managing Goal, Pledge, Subscription, Profile, and Communications.

### **2.4. The Modal System (Success/Failure)**

-   (Future) A mandatory modal on app launch reports the previous day's result.

---

## **3. System Logic & Business Rules**

### **3.1. The Pledge Point (PP) Economy**

-   **No Pledge:** 1 PP per success
-   **Pledge Activated:** 10 PP per success
-   **Weekly Streak Bonus (Pledge Required):** +30 PP for a 7-day streak

### **3.2. The "Ungameable" Core Logic**

-   **The “Next Day” Rule:** Any change to an active goal or pledge from the Settings page takes effect at the next midnight.
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

---

## **4. Technical Architecture & Stack**

### **4.1. Technology Stack**

-   **Frontend:** Flutter (iOS & Android)
-   **Backend & Database:** Supabase (PostgreSQL, Auth, and PostgreSQL Functions (RPC) for atomic business logic).
-   **Subscriptions (IAP):** RevenueCat
-   **Accountability Pledges (Off-platform):** Stripe

### **4.2. Architecture: Feature-First Clean Architecture**

-   Codebase organized into a `core` folder for shared code, and `features` folders for modular user-facing verticals.

### **4.3. State Management: Riverpod**

-   **Services/Repositories:** Provided via Providers in `core/di/`.
-   **UI State:** Managed by `StateNotifier`s or `FutureProvider`s within each feature's `presentation/viewmodels/` directory.

### **4.4. Platform-Specific Code (iOS vs. Android)**

-   **Abstraction Layer:** Pure Dart `ScreenTimeService` defined in `core/services`.
-   **Native Implementation (Android):** Kotlin using `MethodChannel` to access `PackageManager.queryIntentActivities` and `UsageStatsManager`.
-   **Native Implementation (iOS):** (Future) Swift using the `FamilyControls` framework and `DeviceActivity`.

### **4.5 The Auth Gate & Session Management**

-   The application's root widget is an `AuthGate` view located in the `auth` feature. It watches the Supabase `onAuthStateChange` stream and the user's `Profile` to handle session management and initial routing, as detailed in Section 2.1.

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

    *File: `.../domain/repositories/profile_repository.dart`*
    ```dart
    abstract class IProfileRepository {
      // ... other methods
      Future<void> saveOnboardingDraftGoal(Map<String, dynamic> draftGoal);
    }
    ```

2.  **Create the Use Case:** Create the `SaveGoalAndContinueUseCase`. It will depend on the repository contract.

    *File: `.../domain/usecases/save_goal_and_continue.dart`*
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

    *File: `supabase/migrations/..._create_rpc.sql`*
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

    *File: `.../data/repositories/profile_repository_impl.dart`*
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

    *File: `.../di/profile_providers.dart`*
    ```dart
    final saveGoalAndContinueUseCaseProvider = Provider((ref) {
      return SaveGoalAndContinueUseCase(ref.watch(profileRepositoryProvider));
    });
    ```

---

#### **Phase 4: Build the User Interface (The Presentation Layer)**

*Location: `lib/features/onboarding_post/`*

6.  **Create/Update the ViewModel:** The `GoalSettingViewModel` depends on and calls the use case.

    *File: `.../presentation/viewmodels/goal_setting_viewmodel.dart`*
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

    *File: `.../presentation/views/goal_setting_page.dart`*
    ```dart
    // The "Save & Continue" button's onPressed callback:
    onPressed: () {
      ref.read(goalSettingViewModelProvider.notifier).saveDraftGoalAndContinue(goal);
    }
    ```

---

## **6. Database Schema (v1.1)**

The full, definitive `schema.sql` file, including all tables, enums, RLS policies, triggers, and RPCs, is maintained as a separate `schema.sql` document. The version described in this Master Document corresponds to version 1.1 of that file.

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
