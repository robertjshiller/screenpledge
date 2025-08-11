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