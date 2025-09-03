ScreenPledge: Development Progress & Roadmap (Corrected)
As of: August 26, 2025
Current Phase: DEBUGGING: Core Accountability Engine
1. Current Status Summary
The project has made significant architectural progress by implementing an offline-first data layer and completing the entire user onboarding and payment setup flow.
However, we have hit a critical blocker: the on-device background task, which is essential for our real-time notification system, is failing to run correctly. The workmanager plugin is unable to communicate with our custom native ScreenTimeService from a background process, resulting in a MissingPluginException.
Our immediate and highest priority is to diagnose and resolve this native integration issue. The completion of the core MVP is blocked until this is fixed.
2. Detailed Feature Progress
✅ onboarding_pre (Pre-Subscription Funnel)
Status: 100% Complete
✅ onboarding_post (Post-Subscription Funnel)
Status: 100% Complete
Components: All components, including Stripe integration, personalization, and the "Pledge Activated" screen, are functionally complete.
🟡 dashboard (Core Application MVP)
Status: 75% Complete
Components:
✅ Offline-First Architecture: Complete. The ViewModel and repositories are fully refactored for an offline experience.
✅ Personalization: Complete. The UI correctly displays the user's name and pledge points.
✅ UI States: Complete. All six dashboard states and their corresponding UI widgets are built and integrated.
✅ Native Data Accuracy: The native parser is robust.
🔴 core_logic (Accountability Engine)
Status: 50% Complete (BLOCKED)
Components:
✅ "End of Day" Worker (Backend): Complete & Robust. The process-daily-result Supabase Edge Function is deployed and tested. It correctly handles all server-side logic.
🔴 On-Device Notification System (Frontend): BLOCKED. The Dart logic for the "smart" background task is written. However, the task is not functional due to the MissingPluginException. It cannot communicate with the native code to get screen time data, and therefore cannot fire any notifications. This is the current highest-priority bug.
❌ rewards (Rewards Marketplace)
Status: 0% Complete
3. Prioritized Next Steps (The Roadmap)
The roadmap has been re-prioritized to reflect our critical blocker.
Priority 1: Fix the Background Execution MissingPluginException (BLOCKER)
Feature: core_logic
Why: This is the highest priority task. The "Notification First" part of our core accountability model is completely non-functional until this is resolved. The app cannot provide any of the promised real-time warnings.
Plan:
Diagnose: Continue our methodical diagnostic process to understand why the MethodChannel is not available to the background isolate.
Implement the Correct Native Solution: Based on our diagnosis, apply the standard, community-vetted solution for registering custom platform channels for background execution on Android (e.g., the custom Application class pattern).
Verify: Use the debug button to confirm that the background task can successfully call getTotalDeviceUsage and that notifications are being delivered as expected.
Priority 2: Finalize the Dashboard UI & States
Feature: dashboard
Why: Once the background engine is working and producing daily_results, we can fully test and finalize the UI that displays this information.
Plan:
Integrate Overlay Banners: Fully test the success/failure and timezone banners.
Finalize WeeklyBarChart: Ensure the chart correctly displays data.
Priority 3: Build the Rewards Marketplace UI & Logic
Feature: rewards
Why: The final core feature of the MVP.
Plan: (Plan remains the same)
Priority 4: Build the Settings Feature
Feature: settings
Why: Allow users to manage their account and goals.
Plan: (Plan remains the same)