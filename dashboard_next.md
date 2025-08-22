Of course. Let's consolidate everything into a clear, actionable plan. We have a solid architectural foundation; now it's time to build the user-facing features on top of it.

Here are the definitive next steps to build the dashboard you've designed.

---

### **Next Steps: A Trello-Style Checklist for the Dashboard**

This plan is ordered by dependency. You must complete the data layer before you can build the UI.

#### **List 1: The Foundation (Backend & Data Layer)**

*   **Card: Add the `has_ever_set_a_goal` Column**
    *   [ ] **Action:** Run the `ALTER TABLE` command in your Supabase SQL Editor to add the `has_ever_set_a_goal BOOLEAN NOT NULL DEFAULT FALSE` column to the `profiles` table.
    *   [ ] **Action:** Update your `commit_onboarding_goal` RPC to set this flag to `true` during the final onboarding commit.
    *   [ ] **Action:** Update your `Profile` entity in Flutter to include this new boolean property.

*   **Card: Create the `GetDashboardDataUseCase`**
    *   [ ] **Action:** Create a new file: `lib/core/domain/usecases/get_dashboard_data.dart`.
    *   [ ] **Action:** Inside, define a `DashboardData` entity class that will hold all the data needed for the dashboard (the `Profile`, the active `Goal`, the pending `Goal`, and a `List<DailyResult>`).
    *   [ ] **Action:** Create the `GetDashboardDataUseCase` class. It will depend on the `IProfileRepository`, `IGoalRepository`, and a new `IDailyResultRepository`.
    *   [ ] **Action:** Implement the `call()` method, which will fetch all the necessary data from the repositories and return it bundled in the `DashboardData` object.

*   **Card: Create the `IDailyResultRepository`**
    *   [ ] **Action:** Create the necessary repository contract (`IDailyResultRepository`) and its implementation (`DailyResultRepositoryImpl`) in `core`.
    *   [ ] **Action:** The primary method will be `Future<List<DailyResult>> getRecentResults({int days = 7})`. This will query the `daily_results` table for the last 7 days of outcomes for the current user.

*   **Card: Update DI Providers**
    *   [ ] **Action:** Create `daily_result_providers.dart` in `core/di`.
    *   [ ] **Action:** Create a provider for the `getDashboardDataUseCaseProvider` (likely in a new `dashboard_providers.dart` file in `core/di`).

---

#### **List 2: The Logic (Presentation Layer - ViewModel)**

*   **Card: Build the `DashboardViewModel`**
    *   [ ] **Action:** Create the `DashboardViewModel` file in `lib/features/dashboard/presentation/viewmodels/`.
    *   [ ] **Action:** Create a `DashboardState` class. This class should contain an `enum` for the display state (`loading`, `goalPending`, `goalActive`, `goalActiveWithPendingChange`, `noGoalActive`) and properties to hold all the data from the `DashboardData` entity.
    *   [ ] **Action:** The ViewModel will depend on the `GetDashboardDataUseCase`.
    *   [ ] **Action:** Implement a `fetchDashboardData()` method. Inside this method, call the use case. On success, run the **decision tree logic** we discussed to determine the correct `DashboardDisplayState` and emit a new `DashboardState` object with all the data.

---

#### **List 3: The UI (Presentation Layer - View)**

*   **Card: Refactor the `DashboardPage`**
    *   [ ] **Action:** Convert `DashboardPage` to a `ConsumerWidget`.
    *   [ ] **Action:** In the `build` method, `watch` the `dashboardViewModelProvider`.
    *   [ ] **Action:** Use a `switch` statement on `state.displayState`. Based on the enum, render one of four private helper widgets: `_buildLoadingView()`, `_buildGoalPendingView()`, `_buildGoalActiveView()`, or `_buildNoGoalView()`.

*   **Card: Build the `_buildGoalPendingView`**
    *   [ ] **Action:** This is the UI for your first screenshot ("Your First Challenge Is Set!").
    *   [ ] **Action:** It will receive the `pendingGoal` data from the `DashboardState` to display the goal details (e.g., "3h 15m").
    *   [ ] **Action:** It will calculate and display the time remaining until midnight.

*   **Card: Build the `_buildGoalActiveView`**
    *   [ ] **Action:** This is the UI for your second screenshot ("Good Morning!").
    *   [ ] **Action:** It will receive the `activeGoal`, `profile`, and `recentResults` data.
    *   [ ] **Action:** It will contain the Progress Ring and the Weekly Progress Bar Chart.
    *   [ ] **Action:** It will also check for a `pendingGoal` and, if one exists, display the small banner at the bottom ("Your new goal of 2h 0m will begin tomorrow.").

---

### **How to Build the Progress Ring and Bar Chart**

This is a great question about the specifics of the UI implementation. You do not need to build these from scratch. The Flutter ecosystem has excellent, mature packages for this.

**1. The Progress/Countdown Ring:**

*   **Recommended Package:** `percent_indicator`
*   **Why:** It's a very popular, highly customizable, and easy-to-use package specifically for creating circular and linear progress indicators.
*   **How to Implement:**
    1.  Add `percent_indicator` to your `pubspec.yaml`.
    2.  In your `_buildGoalActiveView`, you will use the `CircularPercentIndicator` widget.
    3.  You will calculate the `percent` to display: `(timeRemaining / totalTimeLimit)`.
    4.  You will use the `center` property of the widget to place the `Text` widget with the remaining time ("1h 13m") inside the ring.
    5.  You can easily style the colors, line width, and add the mascot image below or within it.

**2. The Weekly Progress Bar Chart:**

*   **Recommended Package:** `fl_chart`
*   **Why:** This is the most powerful and flexible charting library for Flutter. It can create any kind of chart you can imagine, including beautiful bar charts. It has excellent documentation.
*   **How to Implement:**
    1.  Add `fl_chart` to your `pubspec.yaml`.
    2.  In your `_buildGoalActiveView`, you will use the `BarChart` widget.
    3.  You will transform your `List<DailyResult>` data into a list of `BarChartGroupData` objects.
    4.  You will loop through your `recentResults`. For each day, you will create a `BarChartRodData` object.
    5.  You will use a `switch` statement on the `daily_outcome` to set the `color` of each bar (green for `success`, red for `failure`, grey for `paused` or no data).
    6.  The `fl_chart` library gives you full control over the labels (M, T, W, etc.), tooltips, and overall styling.

By using these well-supported packages, you can focus on providing the correct data from your ViewModel and let the packages handle the complex work of rendering the beautiful visualizations you've designed.