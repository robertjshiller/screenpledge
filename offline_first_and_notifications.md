
---

### **ScreenPledge: Offline-First & Timezone Management Architecture**

**Version:** 1.0
**Date:** August 26, 2025
**Status:** Approved Design for Implementation

#### **1. Introduction & Guiding Principles**

This document outlines the architectural strategy for making the ScreenPledge application robust, reliable, and functional regardless of the user's network connectivity or location. It formalizes the "Tough but Fair" principle in the context of data synchronization and global user travel.

*   **Server is the Authority:** The Supabase backend is the single, immutable source of truth for all historical data and user-initiated changes. The client is treated as an untrusted source.
*   **Core Experience is Paramount:** The user's core daily loop—tracking their progress against their goal—must be seamless and instantaneous, whether online or offline.
*   **Data Integrity Over Immediacy:** The system is designed to prevent data corruption and fraudulent user actions, prioritizing the integrity of the user's record over the immediacy of non-critical updates.
*   **User Context is Respected:** The system is designed to gracefully handle real-world complexities like timezone changes, Daylight Saving Time, and cross-midnight usage sessions.

#### **2. Offline-First Architecture**

The application will be architected to primarily read from a local, on-device database, ensuring an instantaneous UI and a seamless core experience.

##### **2.1. Technology Stack**

*   **Local Database (`sqflite`):** For storing structured, relational data (goals, daily results, profile summary) on the device. This is the primary data source for the UI.
*   **Key-Value Cache (`shared_preferences`):** For storing simple, non-relational data required by the background task, such as the `cached_active_goal` JSON and the `lastNotifiedThreshold`.

##### **2.2. The "Sync on Resume" Data Flow**

1.  **Instant UI Load:** When the app is opened, all core UI elements (Dashboard, etc.) will immediately load their state from the local SQLite database.
2.  **Background Sync:** Simultaneously, a network request is dispatched to Supabase to fetch the latest, authoritative data.
3.  **Update & Refresh:** Upon a successful network response, the fresh data is written to the local SQLite database, and the UI is signaled (via Riverpod) to refresh itself.
4.  **Graceful Failure:** If the network sync fails, the user is left with the last-known good data from the cache. A subtle UI element will indicate the offline status (e.g., "Offline. Last synced: 2 hours ago").

##### **2.3. Gated Features (Online-Only)**

Features that are not part of the core daily loop and require real-time, secure data will be gracefully disabled when the user is offline.

*   **Gated Features List:**
    *   Rewards Marketplace
    *   All Settings that mutate server data (e.g., changing profile name, managing subscription, editing pledge).
    *   The initial user onboarding and account creation flow.
*   **UX for Gated Features:** Buttons will appear disabled. Tapping them will produce a snackbar: `An internet connection is required to access this feature.`

#### **3. Secure Synchronization & Data Integrity**

To prevent malicious data manipulation, the app will use a **"Command-Based" Synchronization Model.** The client never sends its "state" to the server; it only sends new information or commands.

##### **3.1. `daily_results` Synchronization (The Immutable Past)**

*   **Client Role:** The client's only job is to send raw, unprocessed data for a day the server has not yet seen. The payload is minimal: `{ "date": "YYYY-MM-DD", "timezone": "IANA/Timezone", "final_usage_seconds": 12345 }`.
*   **Server Role (The Unbreakable Rule):** The `process-daily-result` Edge Function will **NEVER** overwrite an existing `daily_results` record. If a record for the given user and date already exists, the server ignores the client's request. This makes a user's history immutable and tamper-proof.

##### **3.2. Settings & Goal Changes**

*   **Client Role:** The client sends a "command" to the server (e.g., `updateGoal(new_limit: 3600)`).
*   **Server Role:** The server validates the command, applies its business logic (like the "Next Day Rule"), updates its own authoritative database, and then sends the new, correct state back to the client to be cached.

#### **4. Timezone Management**

The system is designed to be robust against both legitimate travel and malicious timezone manipulation.

##### **4.1. The "Daily Timezone Lock"**

*   **Mechanism:** A `timezone` column will be added to the `daily_results` table. The **first time** the server receives any data for a user on a new day, it will create a record and **lock in the client-reported timezone** for that entire day.
*   **Security:** Any subsequent data submissions for that same day that report a *different* timezone will be ignored by the server. The server will always use the originally locked-in timezone to calculate the day's true boundaries. This completely nullifies any attempt to gain "extra time" by changing the device clock.

##### **4.2. The "Cross-Midnight Session Splitter"**

*   **Scenario:** A user has a single, continuous usage session that starts before midnight and ends after midnight (e.g., 11:30 PM to 12:15 AM).
*   **Mechanism:** The on-device native screen time parser must be implemented to be "midnight-aware." It will be responsible for splitting the duration of such sessions and correctly allocating the usage to the respective days.
    *   *Example:* A 45-minute session from 11:30 PM to 12:15 AM will be recorded as **30 minutes for Day 1** and **15 minutes for Day 2**.

#### **5. Offline-Capable Settings: The OS as the Source of Truth**

A distinction is made between app data settings and OS-level permissions.

*   **App Data Settings (e.g., "Motivational Nudges"):** These are tied to the Supabase database. For the MVP, changing these settings will be **gated and require an online connection** to avoid the complexity of a command queue.
*   **OS Permissions (e.g., "Enable Notifications"):** This is not our data; it belongs to the OS.
    *   **Implementation:** The in-app toggle will simply link the user to the native OS settings screen for our app.
    *   **Offline Behavior:** The `workmanager` background task will **always** check for OS-level notification permission *before* executing its logic. If permission is denied, the task will immediately exit. This ensures the user's choice is respected instantly, with no network connection required.

This comprehensive strategy ensures that ScreenPledge will function as a fast, reliable, and truly ungameable accountability partner for our users, anywhere in the world.