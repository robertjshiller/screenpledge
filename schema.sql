-- ScreenPledge Database Schema v1.3
-- Author: Gemini AI
-- Date: August 23, 2025

-- =================================================================
-- SECTION 1: ENUM TYPE DEFINITIONS
-- =================================================================

CREATE TYPE public.pledge_status AS ENUM ('inactive', 'active', 'paused');
CREATE TYPE public.goal_type AS ENUM ('total_time', 'custom_group');
CREATE TYPE public.goal_status AS ENUM ('active', 'inactive', 'paused', 'pending');
CREATE TYPE public.daily_outcome AS ENUM ('success', 'failure', 'paused', 'forgiven', 'pending_reconciliation');
CREATE TYPE public.reward_type AS ENUM ('gift_card', 'discount', 'free_trial', 'donation', 'subscription', 'theme');
CREATE TYPE public.reward_tier AS ENUM ('bronze', 'silver', 'gold', 'platinum');

-- =================================================================
-- SECTION 2: TABLE CREATION
-- =================================================================

-- Table: profiles
CREATE TABLE public.profiles (
  id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  display_name text,
  pledge_points integer NOT NULL DEFAULT 0,
  lifetime_pledge_points integer NOT NULL DEFAULT 0,
  streak_count integer NOT NULL DEFAULT 0,
  pledge_status public.pledge_status NOT NULL DEFAULT 'inactive',
  pledge_amount_cents integer NOT NULL DEFAULT 0,
  revenuecat_app_user_id text UNIQUE,
  stripe_customer_id text UNIQUE,
  user_timezone text,
  show_contextual_tips boolean NOT NULL DEFAULT true,
  show_motivational_nudges boolean NOT NULL DEFAULT true,
  onboarding_completed_survey boolean NOT NULL DEFAULT false,
  onboarding_completed_goal_setup boolean NOT NULL DEFAULT false,
  onboarding_draft_goal JSONB,
  onboarding_completed_pledge_setup boolean NOT NULL DEFAULT false,
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
  effective_at timestamp with time zone NOT NULL DEFAULT now(),
  ended_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.goals IS 'An immutable log of user-defined goals. Active goal is the one where ended_at is NULL.';

-- Table: daily_results
CREATE TABLE public.daily_results (
  id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date date NOT NULL,
  outcome public.daily_outcome NOT NULL,
  pp_earned integer NOT NULL DEFAULT 0,
  pledge_charged_cents integer NOT NULL DEFAULT 0,
  time_spent_seconds integer,
  time_limit_seconds integer,
  timezone TEXT,
  acknowledged_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.daily_results IS 'Immutable log of daily user outcomes.';

ALTER TABLE public.daily_results ADD CONSTRAINT unique_user_date UNIQUE (user_id, date);

-- Table: rewards
CREATE TABLE public.rewards (
  id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text,
  pp_cost integer NOT NULL,
  image_url text,
  reward_type public.reward_type NOT NULL,
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
-- =================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rewards ENABLE ROW LEVEL SECURITY;

-- Policies for 'profiles'
CREATE POLICY "Users can manage their own profile" ON public.profiles FOR ALL TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Policies for 'goals'
CREATE POLICY "Users can manage their own goals" ON public.goals FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Policies for 'daily_results'
CREATE POLICY "Users can view their own daily results." ON public.daily_results FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can update acknowledged_at." ON public.daily_results FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- Policies for 'user_surveys'
CREATE POLICY "Users can manage their own survey" ON public.user_surveys FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Policies for 'rewards'
CREATE POLICY "All authenticated users can view active rewards." ON public.rewards FOR SELECT TO authenticated USING (is_active = true);

-- =================================================================
-- SECTION 4: DATABASE FUNCTIONS & TRIGGERS
-- =================================================================

-- Function and Trigger for automatic `updated_at` timestamps
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_profiles_updated BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();
CREATE TRIGGER on_goals_updated BEFORE UPDATE ON public.goals FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();
CREATE TRIGGER on_rewards_updated BEFORE UPDATE ON public.rewards FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Function and Trigger for creating a new user profile on sign-up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- RPCs for atomic operations
CREATE OR REPLACE FUNCTION public.submit_user_survey(survey_data jsonb)
RETURNS void AS $$
BEGIN
  INSERT INTO public.user_surveys (user_id, age_range, occupation, primary_purpose, attribution_source)
  VALUES (auth.uid(), survey_data->>'age_range', survey_data->>'occupation', survey_data->>'primary_purpose', survey_data->>'attribution_source');
  UPDATE public.profiles SET onboarding_completed_survey = TRUE WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.save_onboarding_goal_draft(draft_goal_data jsonb)
RETURNS void AS $$
BEGIN
  UPDATE public.profiles SET onboarding_draft_goal = draft_goal_data, onboarding_completed_goal_setup = TRUE WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.commit_onboarding_goal(pledge_amount_cents_input integer DEFAULT 0)
RETURNS void AS $$
DECLARE
  draft_goal_data jsonb;
BEGIN
  SELECT onboarding_draft_goal INTO draft_goal_data FROM public.profiles WHERE id = auth.uid();
  IF draft_goal_data IS NULL THEN RAISE EXCEPTION 'User does not have a draft goal to commit.'; END IF;
  INSERT INTO public.goals (user_id, status, goal_type, time_limit_seconds, tracked_apps, exempt_apps)
  VALUES (auth.uid(), 'active', (draft_goal_data->>'goalType')::public.goal_type, (draft_goal_data->>'timeLimit')::integer, (draft_goal_data->>'trackedApps')::jsonb, (draft_goal_data->>'exemptApps')::jsonb);
  UPDATE public.profiles SET pledge_status = CASE WHEN pledge_amount_cents_input > 0 THEN 'active'::public.pledge_status ELSE 'inactive'::public.pledge_status END, pledge_amount_cents = pledge_amount_cents_input, onboarding_completed_pledge_setup = TRUE, onboarding_draft_goal = NULL WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql;

-- =================================================================
-- SECTION 5: TABLE-LEVEL PRIVILEGES (GRANTS)
-- =================================================================

-- Grant basic access to the public schema for authenticated users.
GRANT USAGE ON SCHEMA public TO authenticated;

-- Grant permissions for the 'profiles' table.
GRANT SELECT, UPDATE ON TABLE public.profiles TO authenticated;

-- Grant permissions for the 'user_surveys' table.
GRANT SELECT, INSERT ON TABLE public.user_surveys TO authenticated;

-- Grant permissions for the 'goals' table.
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.goals TO authenticated;

-- Grant permissions for the 'rewards' table.
GRANT SELECT ON TABLE public.rewards TO authenticated;

-- Grant permissions for the 'daily_results' table.
GRANT SELECT, UPDATE ON TABLE public.daily_results TO authenticated;