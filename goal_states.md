Of course. This is a brilliant area to explore, as it gets to the very heart of your "Tough but Fair" principle and the user's daily experience.

You are absolutely correct. The dashboard needs a specific state for a new user whose goal is set but not yet active. Let's call this the **"Goal Pending"** state.

### **Part 1: The "Goal Pending" State (For New Users)**

This state is shown exclusively to a brand-new user who has just completed the entire onboarding flow (including setting their first goal and pledge) and lands on the dashboard for the first time.

**Purpose:**
*   **Acknowledge & Congratulate:** To celebrate the completion of their setup.
*   **Manage Expectations:** To clearly communicate the "Next Day" rule so they aren't confused about why their goal isn't tracking immediately.
*   **Build Anticipation:** To create a positive sense of a fresh start beginning tomorrow.

**Text Wireframe for the "Goal Pending" Dashboard View:**

```
//====================================================================//
//                 [DASHBOARD STATE: Goal Pending]
//====================================================================//

// [VISUAL: Your mascot, "Pledgey", could be shown sleeping or
//           looking at a clock, waiting for midnight.]

// --- Main Headline (Large, Bold, Exciting) ---
You're All Set!

// --- Body Text (Clear and Informational) ---
Your new goal to limit your [Goal Summary e.g., "Total Screen Time"]
to [Time Limit e.g., "2h 30m"] is ready to go.

Your first day of accountability begins at midnight.

// --- Countdown Timer (Engaging Visual Element) ---
[ 07 : 23 : 45 ]
Hours : Mins : Secs
UNTIL YOUR GOAL IS ACTIVE

// --- Button / Action Link (Optional but recommended) ---
[ Review My Goal ]

//====================================================================//
```

---

### **Part 2: Handling Goal Changes for Existing Users**

Now, let's explore the scenarios for an existing user. The entire system is governed by one, unbreakable principle you defined in your Master Document: **The "Next Day" Rule.**

> **The "Next Day" Rule:** Any change (edit or cancellation) to an active goal does not take effect until the next midnight (00:00) in the user's local timezone.

This rule is the foundation of your "ungameable" system. It prevents a user at 11 PM who is about to fail their goal from quickly changing or deleting it to avoid the consequence. They must honor the commitment they made for the full day.

Here are the scenarios and how to handle them, keeping this rule in mind.

---

### **Scenario A: User EDITS Their Active Goal**

*   **The Action:** A user has been active for a week with a 2-hour daily limit. On Tuesday afternoon, they go to `Settings > Goal` and change their limit to 1 hour 30 minutes, then press "Save."

*   **How to Handle It:**
    1.  **Immediate UI Feedback:** As soon as they hit "Save," show a non-blocking toast or snackbar at the bottom of the screen.
        > **Toast Message:** "Your new goal has been saved and will become active at midnight."
    2.  **Dashboard State (Rest of Tuesday):** The dashboard remains **completely unchanged**. It continues to show the original 2-hour goal. The user is still accountable to the 2-hour limit for all of Tuesday. The progress ring and charts all work towards the 2-hour limit.
    3.  **The Switch (Wednesday at 00:00):** At midnight, the system automatically makes the new goal active. When the user opens the app on Wednesday, their dashboard will now show the new 1 hour 30 minute goal as the target.

---

### **Scenario B: User CANCELS Their Active Goal**

*   **The Action:** On Thursday, the user decides they want to stop using the app's goal system. They go to `Settings > Goal`, press "Cancel My Goal," and confirm their choice in a dialog.

*   **How to Handle It:**
    1.  **Immediate UI Feedback:** After they confirm, show a toast message.
        > **Toast Message:** "Your goal will be canceled at midnight. You are still accountable for today."
    2.  **Dashboard State (Rest of Thursday):** The dashboard remains **completely unchanged**. They are still accountable for their goal for the entirety of Thursday.
    3.  **The Switch (Friday at 00:00):** At midnight, the active goal is officially ended. When the user opens the app on Friday, they will see the **"No Goal"** state on the dashboard. This view should be simple and encouraging.

**Text Wireframe for the "No Goal" Dashboard View:**

```
//====================================================================//
//                   [DASHBOARD STATE: No Goal]
//====================================================================//

[VISUAL: Pledgey looking thoughtful or encouraging.]

// --- Main Headline ---
Ready to build a new habit?

// --- Body Text ---
Setting a goal is the first step to reclaiming your focus.
You can still track your daily usage below.

// --- Primary Call to Action Button ---
[ Set a New Goal ]

// --- (Below the button, the app usage list for the day is still shown) ---
// App Usage List...
//====================================================================//
```

---

### **Scenario C: User with NO GOAL Sets a NEW ONE**

*   **The Action:** A user who previously canceled their goal (or skipped it during onboarding) is on the "No Goal" dashboard. They click "Set a New Goal" and complete the goal-setting flow.

*   **How to Handle It:**
    1.  **The Flow:** After they save their new goal, the app should navigate them **directly to the "Goal Pending" screen** we defined in Part 1.
    2.  **The Logic:** This reuses the exact same logic and UI as a brand-new user. The "Next Day" rule applies, and their new goal will become active at the next midnight. This creates a consistent and predictable user experience.

---

### **How This Works Technically (The "Superseding Goals" Model)**

This entire UX is supported perfectly by the "Superseding Goals" database architecture you defined.

*   **When a user EDITS a goal:** You `UPDATE` the current goal's `ended_at` timestamp to be the end of the current day. Then, you `INSERT` a new goal record with the new settings, setting its `effective_at` timestamp to be the start of the next day.
*   **When a user CANCELS a goal:** You simply `UPDATE` the current goal's `ended_at` timestamp to be the end of the current day. No new goal is inserted.

This creates a clean, immutable history of every commitment a user has ever made, which is perfect for both the app's logic and for future data analysis.