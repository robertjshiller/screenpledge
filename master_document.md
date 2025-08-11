Of course. Here is the complete Master Development Document, updated with a new, detailed section that establishes the pure Clean Architecture workflow as the standard for all future development. This guide is designed to be the definitive reference for your team.

---

# ScreenPledge: The Definitive Master Development Document

**Version:** 1.1  
**Date:** August 1, 2025  
**Project:** ScreenPledge – MVP

---

## 1. Vision & Strategy

### 1.1. Premise & Mission

ScreenPledge is a mobile application for iOS and Android designed to combat digital distraction. It operates on the principle that true behavioral change is achieved through a combination of self-tracking, positive reinforcement, and meaningful accountability.

Unlike simple blockers, ScreenPledge creates a powerful psychological commitment by allowing users to set an optional, real-money "Accountability Pledge." Success is rewarded through a gamified points system, while failure results in the agreed-upon financial consequence—creating a strong incentive to stay on track.

**Mission:**  
To empower individuals to reclaim their time and focus by creating a powerful, positive, and fair accountability system.

### 1.2. Core Principles

- **Business Model:** Subscription-first with a 7-day free trial. The app is a premium service.
- **Design Philosophy:** “Delightful Discipline.” UI/UX must be world-class, inspired by Duolingo and Finch, with a friendly mascot ("Pledgey") central to the experience.
- **User Experience Philosophy:** “Tough but Fair.” The system is ungameable and holds users to a high standard of accountability, but it is designed with empathy and fairness (e.g., the Forgiveness Rule).

---

## 2. The User Experience (UX) & Feature Set

### 2.1. The Onboarding Funnel

The user journey is split into two distinct phases, managed by two separate features.

#### **Phase A: Pre-Subscription** (`onboarding_pre` feature)
*Goal: Convert an anonymous visitor into a trialist.*

- **Get Started Page:** "Get Started" and "Log In" options.
- **Permission Page:** Requests Screen Time access.
- **Data Reveal Sequence:** Multi-part, animated screen showing the user's screen time percentage and "Top 3 Time Sinks" with app icons.
- **Solution Page** A quick page explaining how money backed motivation is effective.
- **How It Works Sequence:** 4-card carousel explaining the core loop: Pledge → Success → Accountability → Reward.
- **Subscription Primer:** A page where we prime the user for their subscription.
- **Subscription Offer Page:** Pricing page where the user commits to the 7-day free trial via native IAP.
- **Free Trial Explained Page:** Explanation of free trial in 'Blinkist' style.

#### **Phase B: Post-Subscription** (`onboarding_post` feature)
*Goal: Get a new trialist fully configured.*

- **Account Creation Page:** Shown immediately after trial activation. User creates account (Email/OAuth) and links it to subscription.
- **User Survey Sequence:** Short survey (age, occupation, purpose, attribution).
- **Goal Setting Page:** User defines their first daily goal (Total Time vs. Custom Group).
- **Pledge Page:** Dedicated, persuasive screen for setting the Accountability Pledge.
- **Notification Permission Dialog:** "Pre-permission" dialog shown after saving accountability.

### 2.2. The Core Application

#### **Dashboard** (`dashboard` feature)
- **Dashboard Page:** One unified dashboard with a corresponding viewmodel that will provide different states for the dashboard.

#### **Rewards Marketplace** (`rewards` feature)
- **Unified, filterable marketplace**
- **Pledge Tiers:** Progress bar for lifetime PP and progress to next tier (Bronze, Silver, etc.)
- **Featured Section:** Carousel highlighting high-priority rewards.
- **Main Grid:** All other rewards (gift cards, donations).

#### **Settings** (`settings` feature)
- Sectioned list for managing Goal, Pledge, Subscription, Profile, and Communications.

### 2.3. The Modal System (Success/Failure)

A mandatory, blocking modal appears on app launch to report the previous day's result.

- **Success Modal:** Celebratory, shows PP earned and streak progress.
- **Failure Modal:** Empathetic, confirms the pledge was charged, resets streak.

---

## 3. System Logic & Business Rules

### 3.1. The Pledge Point (PP) Economy

- **No Pledge:** 1 PP per success
- **Pledge Activated:** 10 PP per success
- **Weekly Streak Bonus (Pledge Required):** +30 PP for a 7-day streak

### 3.2. The "Ungameable" Core Logic

- **The “Next Day” Rule:** Any change to goal or pledge takes effect at the next midnight.
- **Revoke Permission:** Day is Failure, pledge is charged, accountability is paused.
- **Delete Tracked App:** Day processed based on existing usage data.
- **Stripe Payment Fails:** Accountability immediately paused.

### 3.3. The "Fairness" Protocols

- **Reconciliation Protocol:** For users with a "sync gap," history is reconciled upon return.
- **Forgiveness Rule:** Only the first day of failure in a sync gap backlog is charged.

### 3.4. The Caching Strategy

- **Primary:** Forced cache refresh on critical app events.
- **Safety Net:** Long TTL (24h) on local cache.
- **Instant Update:** Silent push notifications for time-sensitive reward releases.

---

## 4. Technical Architecture & Stack

### 4.1. Technology Stack

- **Frontend:** Flutter (iOS & Android)
- **Backend & Database:** Supabase (PostgreSQL, Auth, Edge Functions)
- **Subscriptions (IAP):** RevenueCat
- **Accountability Pledges (Off-platform):** Stripe

### 4.2. Architecture: Feature-First Clean Architecture

- Codebase organized into a `core` folder for shared code, and `features` folders for modular user-facing verticals.
- Strict separation of concerns; dependencies point inward.

### 4.3. State Management: Riverpod

- **Services/Repositories:** Provided via Providers in `core` or feature-specific `di/` folders.
- **UI State:** Managed by Notifiers within each feature's `presentation/viewmodels/` directory.

### 4.4. Platform-Specific Code (iOS vs. Android)

- **Abstraction Layer:** Pure Dart `ScreenTimeService` defined in `core`.
- **Native Implementation:** Swift (DeviceActivity) and Kotlin (UsageStatsManager) connected via Platform Channels.

---

## 5. The Clean Architecture Workflow: A Developer's Guide

This section is the **source of truth** for building new features. Adhering to this workflow ensures our codebase remains modular, testable, and maintainable.

### 5.1. Guiding Principles

The entire architecture is governed by one rule: **The Dependency Rule**. Dependencies must only point **inwards**.

```
+-----------------------------------------------------------------+
|  PRESENTATION (Flutter Widgets, ViewModels)                     |
|        Depends on -> [ Domain Layer ]                           |
|-----------------------------------------------------------------|
|  DOMAIN (Pure Dart Business Logic)                              |
|       - Use Cases (e.g., GetUserProfile)                        |
|       - Repository Contracts (e.g., abstract class IProfileRepository) |
|       - Entities (e.g., Profile)                                |
|       -> Depends on NOTHING                                     |
|-----------------------------------------------------------------|
|  DATA (Implementations & External Tools)                        |
|       Depends on -> [ Domain Layer ]                            |
|       - Repository Implementations (e.g., ProfileRepositoryImpl)|
|       - DataSources (e.g., SupabaseProfileDataSource)           |
+-----------------------------------------------------------------+
```

-   **Domain Layer:** The center of the universe. It contains pure Dart code defining the business rules (`UseCases`), data structures (`Entities`), and data access contracts (`Repository Contracts`). It knows nothing about the outside world.
-   **Data Layer:** The implementation layer. It provides concrete implementations of the Repository Contracts, using `DataSources` to talk to external services like Supabase and RevenueCat. It translates raw data into Domain Entities.
-   **Presentation Layer:** The UI layer. It contains Flutter widgets (`Views`) and state management logic (`ViewModels`). It triggers business logic by calling `UseCases` and displays the results.

### 5.2. The Feature Development Blueprint

Follow these 8 steps **in order** when building a new feature vertical (e.g., `rewards`, `settings`).

> **Scenario:** We are building a new feature to fetch and display a list of `Reward` items.

---

#### **Phase 1: Define the Business Logic (The Domain Layer)**

*Location: `lib/features/your_feature/domain/`*

1.  **Create the Entity:** Define the pure Dart class that represents the core business object. It should be simple, with no external dependencies.

    *File: `.../domain/entities/reward.dart`*
    ```dart
    class Reward {
      final String id;
      final String name;
      final int ppCost;
      // ... other fields
      Reward({required this.id, required this.name, ...});
    }
    ```

2.  **Create the Repository Contract:** Define the abstract class (the "interface") that specifies *what* data operations are required for this feature.

    *File: `.../domain/repositories/reward_repository.dart`*
    ```dart
    import '.../entities/reward.dart';

    abstract class IRewardRepository {
      Future<List<Reward>> getAvailableRewards();
      Future<void> redeemReward(String rewardId);
    }
    ```

3.  **Create the Use Case(s):** Create a separate class for each individual user action. Each use case should have a single public method, typically named `call`.

    *File: `.../domain/usecases/get_available_rewards.dart`*
    ```dart
    import '.../repositories/reward_repository.dart';

    class GetAvailableRewards {
      final IRewardRepository _repository;
      GetAvailableRewards(this._repository);

      Future<List<Reward>> call() async {
        return await _repository.getAvailableRewards();
      }
    }
    ```

---

#### **Phase 2: Implement the Data Handling (The Data Layer)**

*Location: `lib/features/your_feature/data/`*

4.  **Create the DataSource:** This class is responsible for making the actual API/database call. It deals with raw data (e.g., JSON) and external SDKs.

    *File: `.../data/datasources/reward_remote_datasource.dart`*
    ```dart
    // This class would use the Supabase client.
    class RewardRemoteDataSource {
      // ... Supabase client setup
      Future<List<Map<String, dynamic>>> fetchRewardsFromDB() async {
        // final data = await supabase.from('rewards').select();
        // return data;
      }
    }
    ```

5.  **Implement the Repository:** Create the concrete implementation of the Domain contract. Its job is to call the DataSource, get the raw data, transform it into a Domain Entity, and return it.

    *File: `.../data/repositories/reward_repository_impl.dart`*
    ```dart
    import '.../datasources/reward_remote_datasource.dart';
    import '.../domain/entities/reward.dart';
    import '.../domain/repositories/reward_repository.dart';

    class RewardRepositoryImpl implements IRewardRepository {
      final RewardRemoteDataSource _remoteDataSource;
      RewardRepositoryImpl(this._remoteDataSource);

      @override
      Future<List<Reward>> getAvailableRewards() async {
        final rawData = await _remoteDataSource.fetchRewardsFromDB();
        // Map the raw JSON/Map into a list of Reward entities.
        return rawData.map((json) => Reward.fromJson(json)).toList();
      }
      // ... implement other methods
    }
    ```

---

#### **Phase 3: Connect the Layers (Dependency Injection)**

*Location: `lib/features/your_feature/di/`*

6.  **Create the Riverpod Providers:** Wire everything together so Riverpod knows how to build the classes. The dependency chain is crucial.

    *File: `.../di/reward_providers.dart`*
    ```dart
    import 'package:flutter_riverpod/flutter_riverpod.dart';

    // 1. DataSource Provider
    final rewardRemoteDataSourceProvider = Provider((ref) => RewardRemoteDataSource());

    // 2. Repository Provider (depends on DataSource)
    final rewardRepositoryProvider = Provider<IRewardRepository>((ref) {
      final dataSource = ref.read(rewardRemoteDataSourceProvider);
      return RewardRepositoryImpl(dataSource);
    });

    // 3. UseCase Provider (depends on Repository)
    final getAvailableRewardsUseCaseProvider = Provider((ref) {
      final repository = ref.read(rewardRepositoryProvider);
      return GetAvailableRewards(repository);
    });
    ```

---

#### **Phase 4: Build the User Interface (The Presentation Layer)**

*Location: `lib/features/your_feature/presentation/`*

7.  **Create the ViewModel:** This class manages the UI state and contains the UI logic. It **only** depends on Use Cases.

    *File: `.../presentation/viewmodels/rewards_viewmodel.dart`*
    ```dart
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import '.../domain/usecases/get_available_rewards.dart';

    class RewardsViewModel extends StateNotifier<AsyncValue<List<Reward>>> {
      final GetAvailableRewards _getAvailableRewards;
      RewardsViewModel(this._getAvailableRewards) : super(const AsyncValue.loading()) {
        fetchRewards();
      }

      Future<void> fetchRewards() async {
        state = const AsyncValue.loading();
        try {
          final rewards = await _getAvailableRewards();
          state = AsyncValue.data(rewards);
        } catch (e, st) {
          state = AsyncValue.error(e, st);
        }
      }
    }

    // ViewModel Provider (depends on UseCase)
    final rewardsViewModelProvider = StateNotifierProvider((ref) {
      final getRewards = ref.read(getAvailableRewardsUseCaseProvider);
      return RewardsViewModel(getRewards);
    });
    ```

8.  **Create the View:** This is the "dumb" Flutter widget. It watches the ViewModel provider and rebuilds itself based on the state (`AsyncValue`'s `when` method is perfect for this). It forwards user actions to the ViewModel.

    *File: `.../presentation/views/rewards_page.dart`*
    ```dart
    import 'package:flutter_riverpod/flutter_riverpod.dart';

    class RewardsPage extends ConsumerWidget {
      @override
      Widget build(BuildContext context, WidgetRef ref) {
        final state = ref.watch(rewardsViewModelProvider);

        return state.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, st) => Text('Error: $err'),
          data: (rewards) => ListView.builder(
            itemCount: rewards.length,
            itemBuilder: (context, index) => Text(rewards[index].name),
          ),
        );
      }
    }
    ```

---

## 6. Database Schema

-- ScreenPledge Database Schema v1.0
-- Author: Gemini AI
-- Date: August 1, 2025

-- =================================================================
-- SECTION 1: ENUM TYPE DEFINITIONS
-- These custom types ensure data integrity for status columns.
-- =================================================================

CREATE TYPE public.accountability_status AS ENUM ('inactive', 'active', 'paused');
CREATE TYPE public.goal_type AS ENUM ('total_time', 'custom_group');
CREATE TYPE public.goal_status AS ENUM ('active', 'inactive');
CREATE TYPE public.daily_outcome AS ENUM ('success', 'failure', 'paused', 'forgiven');
CREATE TYPE public.reward_type AS ENUM ('gift_card', 'discount', 'free_trial', 'donation', 'subscription', 'theme');
CREATE TYPE public.reward_tier AS ENUM ('bronze', 'silver', 'gold', 'platinum');

-- =================================================================
-- SECTION 2: TABLE CREATION
-- Defines the core tables for the application.
-- =================================================================

-- Table: profiles
-- Purpose: Stores public user data, extending the private auth.users table.
CREATE TABLE public.profiles (
  id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  full_name text,
  pledge_points integer NOT NULL DEFAULT 0,
  lifetime_pledge_points integer NOT NULL DEFAULT 0,
  streak_count integer NOT NULL DEFAULT 0,
  accountability_status public.accountability_status NOT NULL DEFAULT 'inactive',
  accountability_amount_cents integer NOT NULL DEFAULT 0,
  revenuecat_app_user_id text UNIQUE;
  stripe_customer_id text UNIQUE,
  user_timezone text NOT NULL,
  show_contextual_tips boolean NOT NULL DEFAULT true,
  show_motivational_nudges boolean NOT NULL DEFAULT true,
  has_completed_onboarding boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.profiles IS 'Stores public user data linked to authentication.';

-- Table: goals
-- Purpose: Stores user-defined screen time goals.
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
COMMENT ON TABLE public.goals IS 'Stores user-defined screen time goals.';

-- Table: daily_results
-- Purpose: An immutable audit log of daily outcomes for each user.
CREATE TABLE public.daily_results (
  id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date date NOT NULL,
  outcome public.daily_outcome NOT NULL,
  pp_earned integer NOT NULL DEFAULT 0,
  fee_charged_cents integer NOT NULL DEFAULT 0,
  acknowledged_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.daily_results IS 'Immutable log of daily user outcomes.';

-- Add a unique constraint to prevent duplicate results for the same user on the same day.
ALTER TABLE public.daily_results ADD CONSTRAINT unique_user_date UNIQUE (user_id, date);

-- Table: rewards
-- Purpose: The master catalog for the Rewards Marketplace, managed by admins.
CREATE TABLE public.rewards (
  id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text,
  pp_cost integer NOT NULL,
  image_url text,
  display_type public.reward_type NOT NULL,
  required_tier public.reward_tier NOT NULL DEFAULT 'bronze',
  total_inventory integer,
  tier_reserved_inventory integer NOT NULL DEFAULT 0,
  redeemed_count integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.rewards IS 'Catalog of all available rewards in the marketplace.';

-- Table: user_surveys
-- Purpose: Stores the one-time responses from the onboarding user questionnaire.
CREATE TABLE public.user_surveys (
  id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  age_range text,
  occupation text,
  primary_purpose text,
  attribution_source text,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.user_surveys IS 'Stores one-time onboarding survey responses.';

-- =================================================================
-- SECTION 3: ROW LEVEL SECURITY (RLS) POLICIES
-- CRITICAL: These policies ensure users can only access their own data.
-- =================================================================

-- Enable RLS for all user-specific tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rewards ENABLE ROW LEVEL SECURITY;

-- --- Policies for `profiles` table ---
CREATE POLICY "Users can view their own profile."
ON public.profiles FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile."
ON public.profiles FOR UPDATE
USING (auth.uid() = id);

-- --- Policies for `goals` table ---
CREATE POLICY "Users can view their own goals."
ON public.goals FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own goals."
ON public.goals FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own goals."
ON public.goals FOR UPDATE
USING (auth.uid() = user_id);

-- --- Policies for `daily_results` table ---
CREATE POLICY "Users can view their own daily results."
ON public.daily_results FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update the acknowledged_at status for their own results."
ON public.daily_results FOR UPDATE
USING (auth.uid() = user_id);
-- Note: Inserts into this table should only be done by a server-side function with elevated privileges.

-- --- Policies for `user_surveys` table ---
CREATE POLICY "Users can view their own survey responses."
ON public.user_surveys FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own survey response once."
ON public.user_surveys FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- --- Policies for `rewards` table ---
CREATE POLICY "All authenticated users can view active rewards."
ON public.rewards FOR SELECT
USING (is_active = true AND auth.role() = 'authenticated');
-- Note: Rewards are managed by admins, so no INSERT/UPDATE policies are needed for users.


-- =================================================================
-- SECTION 4: AUTOMATIC `updated_at` TIMESTAMP
-- This function and trigger automatically update the `updated_at` column on any change.
-- =================================================================

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER on_goals_updated
  BEFORE UPDATE ON public.goals
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER on_rewards_updated
  BEFORE UPDATE ON public.rewards
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();
## 7. Directory Structure

```
# ScreenPledge: Architectural Overview & Directory Guide

## 1. Introduction: Our Architectural Philosophy

This project is built upon a **Feature-First Clean Architecture**—a modern, scalable approach designed to enforce a strict separation of concerns, as detailed in Section 5.

## 2. The `lib/` Directory: The Root of the Application

- **`main.dart`**: Entry point. Initializes services, sets up `ProviderScope`.

## 3. The `core/` Directory: The Shared Foundation

Contains foundational, shared code. If a repository or entity is used by more than one unrelated feature, it lives here.

- **`config/`**: App-wide configuration (router, theme).
- **`data/`**: Shared `RepositoryImpl` classes and `DataSources`.
- **`domain/`**: Shared `Entities` and `Repository Contracts`.
- **`di/`**: Global Riverpod `Providers` for core services.
- **`common_widgets/`**: Universal, reusable UI components.

## 4. The `features/` Directory: Modular Verticals

Contains all user-facing, vertical slices of the app. Each feature is a self-contained module following the blueprint in Section 5.

- **`onboarding_pre_subscription/`**
- **`onboarding_post_subscription/`**
- **`dashboard/`**
- **`rewards/`**
- **`settings/`**

Each feature folder contains its own `data`, `domain`, and `presentation` layers, specific to that feature.
```