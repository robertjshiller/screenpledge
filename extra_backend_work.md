# Architectural Blueprint: Securing the User Onboarding Flow  
**Version:** 1.0  
**Date:** August 1, 2025  
**Author:** Gemini  

---

## Summary of Issues

The current user onboarding flow in the Flutter app has **two major vulnerabilities**:

1. **Unsubscribed User Sign-up Vulnerability**  
   - Anyone can bypass the app UI and create user accounts without an active subscription or trial.
   - Leads to database pollution, unnecessary costs, and maintenance burdens.

2. **Sign-up Attempts with an Existing Email**  
   - Users can attempt to sign up with an email already in the system and get stuck on a verification page, causing confusion and a dead-end experience.

Both issues stem from **trusting the client to decide whether a user should be created**, instead of enforcing the rules server-side.

---

## Problem 1: Unsubscribed User Sign-up Vulnerability

### 1.1 Description of the Problem
The current sign-up process calls `supabase.auth.signUp()` directly from the Flutter client, using only the public `anon` key and basic rate limiting.  
This means:
- **Database Pollution:** Fake “ghost” accounts can be mass-created via scripts.
- **Incurred Costs:** Every sign-up attempt sends an email, costing real money.
- **Maintenance Overhead:** Requires cleanup of unverified accounts.

**Root Cause:** The client decides if a user should be created, but only the server can securely verify subscription eligibility.

---

### 1.2 The Architectural Solution: A Server-Side “Gatekeeper” Edge Function
Move account creation to a secure server-side **Supabase Edge Function** that checks subscription eligibility with **RevenueCat** before creating a user.

**New Secure Workflow:**
1. **Client Action:** User taps “Create Account” → app calls `create-subscribed-user` Edge Function (not `supabase.auth.signUp()` directly).
2. **Data Sent to Function:**
   - Desired email
   - Desired password
   - Current `revenueCatId` (from trial start)
3. **Edge Function Logic:**
   - **Step A: Verify Subscription**  
     Call RevenueCat’s API (using server secret key) to confirm active subscription/trial.
   - **Step B: Decision:**
     - If **active**, use Supabase Admin Client (`service_role`) to create the user in `auth.users`.
     - If **inactive**, return `403 Forbidden` ("No active subscription found").
4. **Client Response:**
   - **200 OK:** Navigate to `VerifyEmailPage`.
   - **403 Forbidden:** Show error ("An active subscription is required").

**Outcome:**  
Prevents unauthorized sign-ups, stops database pollution, and makes the server the single source of truth.

---

## Problem 2: Handling Sign-up Attempts with an Existing Email

### 2.1 Description of the Problem
When an existing user tries to sign up again:
- `supabase.auth.signUp()` returns “success” but doesn’t send a new verification email (since the user is already confirmed).
- The app navigates to `VerifyEmailPage` → user waits for an email that will never come.
- Leads to a frustrating dead-end.

---

### 2.2 The Architectural Solution: Pre-emptive Check within the Gatekeeper Function
Add an **“existing user” check** at the start of `create-subscribed-user`.

**Updated Workflow:**
1. **Step A: Check for Existing User (New)**  
   - Query `auth.users` with Supabase Admin Client.  
   - If exists → return `409 Conflict` ("Account already exists. Please log in.").
2. **Step B: Verify Subscription**  
   - Same as Problem 1 logic.
3. **Step C: Decision:**  
   - **Active subscription:** Create user → `200 OK`.
   - **Inactive subscription:** Return `403 Forbidden`.
4. **Client Response:**
   - **409 Conflict:** Show “Account already exists” + button to go to Log In.

**Outcome:**  
Improves UX by preventing dead ends and guiding users to the correct login flow.

---

## Combined Benefits
- **Security:** No account creation without an active subscription.
- **Data Integrity:** Prevents ghost accounts and keeps metrics accurate.
- **UX Improvement:** Stops users from getting stuck in verification loops.
- **Centralized Logic:** All eligibility checks happen in one secure server-side function.

---

## Implementation Note
This architectural change will be implemented **in a later development phase** after other priority onboarding improvements are completed.

---
