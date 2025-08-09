Based on the Master Development Document, here is a specific list of backend work required to support the frontend development up until the dashboard feature.

This list covers the `onboarding_pre` and `onboarding_post` features, focusing on setting up the database, authentication, third-party integrations, and the necessary API endpoints to make the onboarding flow functional.

---

### Phase 1: Foundational Setup (Supabase)

This is the essential groundwork required before any feature-specific logic can be built.

*   **1.1. Database Schema Deployment:**
    *   Execute the provided SQL script in the Supabase SQL Editor to create all tables (`profiles`, `goals`, `daily_results`, etc.), ENUM types, and Row Level Security (RLS) policies.
    *   Verify that the `handle_updated_at` function and its associated triggers are created and active on the `profiles`, `goals`, and `rewards` tables.

*   **1.2. Authentication Configuration (Supabase Auth):**
    *   Enable and configure the required authentication providers in the Supabase dashboard. At a minimum, this includes "Email/Password".
    *   If supporting social login, configure the OAuth providers (e.g., Google, Apple) with the necessary client IDs and secrets.

*   **1.3. Automated Profile Creation:**
    *   Create a database trigger and function that automatically inserts a new row into the `public.profiles` table whenever a new user signs up and is added to the `auth.users` table.
    *   This function should copy the `id` and `email` from `auth.users` into the new `profiles` row.

### Phase 2: Third-Party Service Integration

These tasks involve creating server-side logic (Supabase Edge Functions) to securely communicate with RevenueCat and Stripe.

*   **2.1. RevenueCat Webhook Integration:**
    *   Create a Supabase Edge Function to act as a webhook receiver for RevenueCat events.
    *   This function must securely handle `INITIAL_PURCHASE` events to know when a user has started their 7-day free trial.
    *   **Goal:** While you can't link the trial to a user *before* they create an account, this endpoint is necessary to log trial activations. The client will later link the RevenueCat anonymous ID to the created user profile.

*   **2.2. Stripe Customer & Pledge Setup:**
    *   **Create Stripe Customer Function:**
        *   **Trigger:** Called from the client when the user first interacts with the Pledge Page.
        *   **Action:** Creates a new `Customer` object in your Stripe account.
        *   **Output:** Securely saves the returned `stripe_customer_id` to the `stripe_customer_id` column in the user's `public.profiles` row. This function is critical for linking a user to their Stripe payment details.
    *   **Create Stripe SetupIntent Function:**
        *   **Trigger:** Called from the client when the Pledge Page loads to prepare the payment form.
        *   **Action:** Creates a Stripe `SetupIntent` using the user's `stripe_customer_id`.
        *   **Output:** Returns the `client_secret` from the SetupIntent to the frontend, allowing the client to securely collect payment information.

### Phase 3: Onboarding API Endpoints (Supabase Edge Functions)

These are the specific server-side functions required to save user data and choices during the `onboarding_post` flow.

*   **3.1. Link Subscription to User Profile:**
    *   **Trigger:** Called from the client immediately after the user creates their account on the "Account Creation Page".
    *   **Input:** The function should accept the RevenueCat App User ID.
    *   **Action:** This function updates the user's `public.profiles` record to associate it with their active subscription status from RevenueCat.

*   **3.2. Save User Survey:**
    *   **Trigger:** Called when the user submits the form on the "User Survey Sequence" page.
    *   **Input:** Receives survey data (age, occupation, purpose, attribution).
    *   **Action:** Inserts a new record into the `user_surveys` table, linking it to the `user_id` of the currently authenticated user.

*   **3.3. Create Initial Goal:**
    *   **Trigger:** Called when the user saves their goal on the "Goal Setting Page".
    *   **Input:** Receives goal data (`goal_type`, `time_limit_seconds`, and `tracked_apps` as a JSON object).
    *   **Action:** Inserts a new record into the `goals` table with `status` set to `'active'`. It must be associated with the correct `user_id`.

*   **3.4. Activate Accountability Pledge:**
    *   **Trigger:** Called when the user confirms their pledge amount on the "Pledge Page" after their payment method has been successfully added via the Stripe SetupIntent.
    *   **Input:** Receives the pledge amount in cents.
    *   **Action:** Updates the user's record in the `public.profiles` table by:
        *   Setting `accountability_amount_cents` to the specified value.
        *   Changing `accountability_status` from `'inactive'` to `'active'`.

*   **3.5. Finalize Onboarding:**
    *   **Trigger:** Called from the client after the final step of the `onboarding_post` flow (e.g., after the notification permission dialog is handled).
    *   **Action:** Updates the `has_completed_onboarding` boolean field in the user's `public.profiles` table to `true`.