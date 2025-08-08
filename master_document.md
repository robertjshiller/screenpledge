# ScreenPledge: The Definitive Master Development Document

**Version:** 1.0  
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

#### **Phase A: Pre-Subscription** (`onboarding_pre_subscription` feature)
*Goal: Convert an anonymous visitor into a trialist.*

- **Get Started Page:** "Get Started" and "Log In" options.
- **Permission Page:** Requests Screen Time access.
- **Data Reveal Sequence:** Multi-part, animated screen showing the user's screen time percentage and "Top 3 Time Sinks" with app icons.
- **Solution Page** A quick page explaining how money backed motivation is effective.
- **How It Works Sequence:** 4-card carousel explaining the core loop: Pledge → Success → Accountability → Reward.
- **Subscription Offer Page:** Pricing page where the user commits to the 7-day free trial via native IAP.

#### **Phase B: Post-Subscription** (`onboarding_post_subscription` feature)
*Goal: Get a new trialist fully configured.*

- **Account Creation Page:** Shown immediately after trial activation. User creates account (Email/OAuth) and links it to subscription.
- **User Questionnaire Page:** Short, skippable survey (age, occupation, purpose, attribution).
- **Goal Setting Page:** User defines their first daily goal (Total Time vs. Custom Group).
- **Notification Permission Dialog:** "Pre-permission" dialog shown after saving goal.
- **Accountability Pledge Page:** Dedicated, persuasive screen for setting the Accountability Pledge.

### 2.2. The Core Application

#### **Dashboard** (`dashboard` feature)

- **Goal Pending State:** Shown on Day 1. Confirms the goal and shows a countdown to midnight start time.
- **Goal Active State:** Main dashboard with real-time progress ring, mascot, streak counter, and a 7-day analytics bar chart.

#### **Rewards Marketplace** (`rewards` feature)

- **Unified, filterable marketplace**
- **Pledge Tiers:** Progress bar for lifetime PP and progress to next tier (Bronze, Silver, etc.)
- **Featured Section:** Carousel highlighting high-priority rewards (subscription redemption, partner offers)
- **Main Grid:** All other rewards (gift cards, donations), showing "Locked" (tier-gated) and "Sold Out" states

#### **Settings** (`settings` feature)

- Sectioned list for managing Goal, Pledge, Subscription, Profile, and Communications

### 2.3. The Modal System (Success/Failure)

A mandatory, blocking modal appears on app launch to report the previous day's result.

- **Success Modal:** Celebratory, shows PP earned and streak progress
- **Failure Modal:** Empathetic, confirms the pledge was charged, resets streak. Copy adapts after 2–3 consecutive failures to offer help.

---

## 3. System Logic & Business Rules

### 3.1. The Pledge Point (PP) Economy

- **No Pledge:** 1 PP per success
- **Pledge Activated:** 10 PP per success
- **Weekly Streak Bonus (Pledge Required):** +30 PP for a 7-day streak

### 3.2. The "Ungameable" Core Logic

- **The “Next Day” Rule:** Any change to goal or pledge takes effect at the next midnight
- **Revoke Permission:** Day is Failure, pledge is charged, accountability is paused for future days
- **Delete Tracked App:** Day processed based on existing usage data before deletion
- **Stripe Payment Fails:** Accountability immediately paused, notification sent

### 3.3. The "Fairness" Protocols

- **Reconciliation Protocol:** For users with a "sync gap" (offline, app deleted), history is reconciled upon return
- **Forgiveness Rule:** Only the first day of failure in a sync gap backlog is charged

### 3.4. The Caching Strategy

- **Primary:** Forced cache refresh on critical app events (app launch, success/failure, reward redemption)
- **Safety Net:** Long TTL (24h) on local cache
- **Instant Update:** Silent push notifications for time-sensitive reward releases, invalidating client cache

---

## 4. Technical Architecture & Stack

### 4.1. Technology Stack

- **Frontend:** Flutter (iOS & Android)
- **Backend & Database:** Supabase (PostgreSQL, Auth, Edge Functions)
- **Subscriptions (IAP):** RevenueCat
- **Accountability Pledges (Off-platform):** Stripe

### 4.2. Architecture: Feature-First Clean Architecture

- Codebase organized into a `core` folder for shared code, and `features` folders for modular user-facing verticals
- Strict separation of concerns; dependencies point inward

### 4.3. State Management: Riverpod

- **Services/Repositories:** Provided via Providers in `core`
- **UI State:** Managed by Notifiers within each feature's `presentation/viewmodels/` directory

### 4.4. Platform-Specific Code (iOS vs. Android)

- **Abstraction Layer:** Pure Dart `ScreenTimeService` defined in `core`
- **Native Implementation:**  
  - iOS: Swift using DeviceActivity  
  - Android: Kotlin using UsageStatsManager  
  - Connected via Flutter's Platform Channels

### 4.5. Database Schema

```sql
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
RETURNS TRIGGER AS $
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE TRIGGER on_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER on_goals_updated
  BEFORE UPDATE ON public.goals
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER on_rewards_updated
  BEFORE UPDATE ON public.rewards
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();
```

### 4.6. Directory Structure
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


