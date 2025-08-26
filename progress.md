

### **ScreenPledge: Development Progress & Roadmap (Full Document)**

**As of:** August 23, 2025
**Current Phase:** Finalizing Onboarding & Core MVP Features

---

### **1. Current Status Summary**

The project is in an excellent state. The foundational architecture is complete and robust. The entire user onboarding flow is functionally complete, and the core dashboard is displaying live, settings-accurate data.

The immediate next steps are focused on implementing the critical financial and accountability logic (Stripe, End-of-Day processing) and building out the final core feature of the MVP: the Rewards Marketplace.

---

### **2. Detailed Feature Progress**

#### **✅ `onboarding_pre` (Pre-Subscription Funnel)**

*   **Status:** 90% Complete
*   **Components:**
    *   ✅ **Get Started Page:** UI Complete.
    *   ✅ **Permission Page:** **Complete & Robust.**
    *   🟡 **Data Reveal Sequence:** UI is complete, but the data pipeline to feed it the calculated lifetime usage from the `ScreenTimeService` still needs to be built.
    *   ✅ **Static Pages (Solution, How It Works, Primer):** UI Complete.
    *   ✅ **Subscription Flow (Offer & Explained Pages):** **Complete.**

#### **✅ `onboarding_post` (Post-Subscription Funnel)**

*   **Status:** 90% Complete
*   **Components:**
    *   ✅ **Account Creation Page:** **Complete.**
    *   ✅ **Verify Email Page:** **Complete & Robust.**
    *   ✅ **Congratulations Page:** UI Complete.
    *   ✅ **User Survey Page:** **Complete.**
    *   ✅ **Goal Setting Page:** **Complete.**
    *   ✅ **App Selection Page:** **Complete.**
    *   🟡 **Pledge Page:** **Partially Implemented.** The UI, "Goal Review" component, and confirmation modal are complete. The logic to call the `commit_onboarding_goal` RPC is in place. The critical **Stripe payment integration is missing.**

#### **✅ `dashboard` (Core Application MVP)**

*   **Status:** 95% Complete
*   **Components:**
    *   ✅ **Dashboard Page:** **Complete.** The view correctly handles all three states: "Goal Pending," "Active Goal," and "No Goal."
    *   ✅ **Progress Ring & Bar Chart:** **Complete & Robust.** The UI is data-driven, using the "Device-First" approach and displaying interactive tooltips.
    *   ✅ **App Usage List:** Complete and displaying the detailed per-app breakdown.
    *   ✅ **Native Data Accuracy:** The `MainActivity.kt` parser is a state-of-the-art, settings-accurate implementation.

#### **❌ `rewards` (Rewards Marketplace)**

*   **Status:** 0% Complete
*   **Components:** This feature has not been started.

---

### **3. Prioritized Next Steps (The Roadmap)**

This is the logical order of operations to complete the MVP.

#### **Priority 1: Implement Stripe Payment Setup (Blocker)**

*   **Feature:** `onboarding_post` (Pledge Page)
*   **Why:** This is the highest priority task. The "pledge" is a core feature, and without the ability to securely save a payment method, the accountability loop is incomplete.
*   **Plan:**
    1.  **Backend:** Create the two required Supabase Edge Functions (`create-stripe-customer`, `create-stripe-setup-intent`).
    2.  **Frontend:** Integrate the `flutter_stripe` package into the `PledgePage`.
    3.  **Logic:** Update the `ConfirmationDialog`'s `onConfirm` callback to first save the payment method via Stripe, and only then call the `pledgeViewModel.activatePledge()` method.

#### **Priority 2: Build the "End of Day" Worker & Logic**

*   **Feature:** Core Logic (Background Task)
*   **Why:** This is the engine of the entire accountability system. It's the process that determines daily success/failure, awards points, and initiates charges.
*   **Plan:**
    1.  **Backend:** Create a new, secure Supabase Edge Function (e.g., `process-daily-result`). This function will handle all the logic for recording results, updating profiles, and calling Stripe.
    2.  **Frontend:** Integrate a background task package (like `workmanager`) to schedule a reliable, daily background task.
    3.  **Logic:** The background task will send the final screen time data to the Edge Function for processing.

#### **Priority 3: Build the Rewards Marketplace UI & Logic**

*   **Feature:** `rewards`
*   **Why:** This is the final core feature of the MVP. It provides the "positive reinforcement" part of the core loop and gives users a reason to accumulate Pledge Points.
*   **Plan:**
    1.  **Backend:** Ensure the `rewards` table is populated with sample data. Create RLS policies and `GRANT`s.
    2.  **Architecture:** Build the full Clean Architecture stack (`IRewardRepository`, `GetRewardsUseCase`, `RewardViewModel`, etc.).
    3.  **UI:** Build the `RewardsPage` UI, including the tier progress bar, featured carousel, and main grid, as described in the Master Document.

#### **Priority 4: Build the Success/Failure Modal**

*   **Feature:** Core Application
*   **Why:** This closes the feedback loop for the user. It depends on the "End of Day" worker having run.
*   **Plan:**
    1.  **Logic:** In the `AuthGate`, query for unacknowledged `daily_results` on app startup.
    2.  **UI:** Build the `SuccessModal` and `FailureModal` widgets.
    3.  **Flow:** Display the appropriate modal if an unacknowledged result is found and update the `acknowledged_at` timestamp on dismissal.

#### **Priority 5: Connect the `DataRevealSequence` Data Pipeline**

*   **Feature:** `onboarding_pre`
*   **Why:** A high-impact "polish" item to make onboarding more compelling.
*   **Plan:**
    1.  Create a `DataRevealViewModel`.
    2.  Use the `ScreenTimeService` to fetch and calculate the lifetime usage stats.
    3.  Update the `DataRevealSequence` UI to display this live data.