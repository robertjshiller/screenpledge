Here is the comprehensive document detailing the notification system, goal caching, and the full "Notification First, Charge Later" accountability model.

---

### **ScreenPledge: Notification & Accountability System Design**

**Version:** 1.0
**Date:** August 26, 2025
**Author:** Gemini

#### **1. Guiding Principles**

This system is designed to be the core of the ScreenPledge experience, embodying our "Tough but Fair" and "Delightful Discipline" philosophies.

*   **Fairness:** The system must provide users with timely, proactive warnings to help them succeed. All financial consequences must be based on the most accurate and complete data.
*   **Toughness:** The system must be ungameable. Accountability is guaranteed and cannot be circumvented by technical loopholes like going offline or changing device settings.
*   **Efficiency:** The system must be highly efficient, with minimal impact on the user's device battery and performance.

To achieve this, we will implement a hybrid model: a **Real-Time Feedback System** running on the user's device, and a **Server-Authoritative Reconciliation System** for all official consequences.

---

### **2. The Real-Time Feedback System (On-Device)**

This system is responsible for all immediate, contextual user communication. It is designed to work perfectly even when the device is offline.

#### **2.1. Core Technology Stack**

*   **Background Processing (`workmanager`):** To schedule and run Dart code reliably in the background, even when the app is terminated.
*   **Local Notifications (`flutter_local_notifications`):** To display native notifications directly from the app without needing a server.
*   **Data Caching (`shared_preferences`):** To store the user's active goal data locally, enabling full offline functionality.

#### **2.2. The Goal Caching Mechanism**

To ensure the background task can always function, it must read goal data from a local cache, not the network.

*   **What is Cached:** Two JSON strings are stored in `shared_preferences`:
    1.  `cached_active_goal`: The goal that is currently in effect.
    2.  `cached_pending_goal`: A new goal that will become active at the next midnight (to support the "Next Day Rule").

    **Example JSON for `cached_active_goal`:**
    ```json
    {
      "goalType": "total_time",
      "timeLimitSeconds": 7200, // 2 hours
      "exemptApps": ["com.slack", "com.google.android.gm"],
      "endedAt": "2025-08-27T04:59:59.999Z" // Midnight in user's timezone
    }
    ```

*   **How the Cache is Updated:**
    1.  **Sync on Resume (Primary):** Every time the user opens or brings the app to the foreground, the app will make a lightweight network call to Supabase to fetch the latest goal data and overwrite the local cache. This is the self-healing mechanism that ensures data is always consistent, even across multiple devices.
    2.  **Immediate Update on Change (Optimization):** When a user successfully saves a goal change in the app's settings, the cache is updated instantly, providing a seamless UX.

#### **2.3. The "Dynamic Interval Calculation" Algorithm**

To provide timely warnings without draining the battery, the background task will intelligently adjust its own frequency. It will be a self-perpetuating chain of `OneTimeWorkRequest`s.

*   **Warning Thresholds:** Notifications will be triggered at **50%**, **75%**, and **90%** of the goal limit, with a final failure alert at **100%**.

*   **The Algorithm:** Each time the background task runs, it performs the following steps:
    1.  **Get State:** Fetch `goalLimit`, `currentUsage`, and the `lastNotifiedThreshold` from the local cache.
    2.  **Fire Notifications:** Check if `currentUsage` has crossed any new thresholds. If so, fire the appropriate notification and update `lastNotifiedThreshold`.
    3.  **Find Next Milestone:** Determine the next upcoming threshold (e.g., if the 50% warning was just sent, the next milestone is 75%).
    4.  **Calculate Time Remaining:** Calculate `timeToNextMilestone` in minutes.
    5.  **Calculate Next Delay:** The next check's delay is calculated as `timeToNextMilestone / 2`. This safety buffer ensures the check runs *before* the milestone is reached, even with 100% engagement.
    6.  **Clamp and Schedule:** The calculated delay is clamped to a reasonable range (e.g., a minimum of **5 minutes** and a maximum of **30 minutes**). A new `OneTimeWorkRequest` is scheduled with this final delay.

*   **Example Walkthrough (5-Hour / 300-Minute Goal):**

| Current Usage | % Used | Last Notified | Next Milestone | Time to Milestone | Calculated Delay | Final Delay (Clamped) | Action |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 0 mins | 0% | 0% | 50% (150m) | 150 mins | 75 mins | **30 mins** | Schedule next check in 30 mins. |
| 145 mins | 48.3% | 0% | 50% (150m) | 5 mins | 2.5 mins | **5 mins** | Schedule next check in 5 mins. |
| 152 mins | 50.6% | 0% | 75% (225m) | 73 mins | 36.5 mins | **30 mins** | **Fire 50% Warning**. Schedule next check in 30 mins. |
| 220 mins | 73.3% | 50% | 75% (225m) | 5 mins | 2.5 mins | **5 mins** | Schedule next check in 5 mins. |
| 301 mins | 100.3% | 90% | 100% (300m) | - | - | - | **Fire 100% Failure Alert**. Stop scheduling for today. |

---

### **3. The "Notify First, Charge Later" Model**

This is the core of our accountability system. We separate the immediate psychological feedback from the delayed, robust financial transaction.

#### **3.1. The "Notify First" Component (Immediate Feedback)**

This is the user-facing "shout" that provides instant accountability.

*   **Trigger:** The on-device background task detects that `currentUsage` has exceeded `goalLimit`.
*   **Action:** The app uses `flutter_local_notifications` to immediately fire a critical, non-dismissible notification.
*   **Notification Content:**
    *   **Title:** `Accountability Alert: Limit Exceeded`
    *   **Body:** `You've gone over your screen time limit. Your pledge for today is now confirmed and will be processed.`
*   **Result:** The user receives instant feedback. They know they have failed and that the consequence is locked in. This works perfectly even if they are offline.

#### **3.2. The "Charge Later" Component (EOD Reconciliation)**

This is the server-side "settlement." It is the secure, ungameable system that handles all official outcomes and financial transactions.

*   **Trigger:** A scheduled task (cron job) runs on Supabase's infrastructure once every 24 hours, after midnight UTC. It will process outcomes for all users for the previous day.

*   **The `process-daily-result` Edge Function:** This is the server-side engine.
    1.  **Data Submission:** The function receives the final, complete screen time data for a given user and day from their device. (The Reconciliation Protocol ensures that if a user was offline for days, their app will submit the backlog of data when it reconnects).
    2.  **Determine Outcome:** The function performs the *final, official calculation* of success or failure based on this complete data and the user's goal stored in the database.
    3.  **Handle Success:** If the user succeeded, the function updates their `pledge_points` and `streak_count` in the `profiles` table and writes a `success` record to `daily_results`.
    4.  **Handle Failure (The Charge Logic):**
        *   **a. Create Record:** It first writes a new record to the `daily_results` table with an `outcome` of `failure` and a status of `pending_charge`.
        *   **b. Call Stripe:** It then makes an API call to Stripe to charge the user's saved payment method for the `pledge_amount_cents`.
        *   **c. On Stripe Success:** It updates the `daily_results` record status to `charge_successful`. It then makes an API call to **Resend** to send the user an official "Payment Successful" email receipt.
        *   **d. On Stripe Failure (e.g., expired card):** It updates the `daily_results` record status to `charge_failed`. It then calls **Resend** to send a "Payment Failed - Please Update Your Card" email and triggers an in-app alert for the user.

*   **Robustness:** This server-authoritative model is immune to all client-side loopholes:
    *   **Offline Users:** The system simply waits for the data to be submitted. The charge is based on the event day, not the processing day.
    *   **Permission Revoked / App Uninstalled:** If the server has a user with an active pledge but receives no data for a completed day, it will correctly interpret this as a failure and process the pledge.

This document serves as our definitive blueprint. The system provides immediate, psychologically effective feedback via offline-capable notifications, while guaranteeing that all financial consequences are handled with the utmost security, accuracy, and integrity on the server.