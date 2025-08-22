// lib/features/onboarding_post/presentation/views/app_selection_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/domain/entities/installed_app.dart';
import 'package:screenpledge/features/onboarding_post/presentation/viewmodels/app_selection_viewmodel.dart';

/// A reusable, full-screen modal page for selecting applications.
///
/// It is configured via constructor arguments to be used for different purposes
/// (e.g., selecting tracked apps vs. exempt apps).
class AppSelectionPage extends ConsumerWidget {
  final String title;
  final Set<InstalledApp> initialSelection;

  const AppSelectionPage({
    super.key,
    required this.title,
    required this.initialSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the ViewModel provider, passing the initial selection.
    final viewModel = appSelectionViewModelProvider(initialSelection);
    final state = ref.watch(viewModel);
    final notifier = ref.read(viewModel.notifier);

    return Scaffold(
      // ✅ CHANGED: Set the AppBar background color explicitly to white for better contrast.
      // This ensures the "Done" button and title are always visible against a clean background.
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(), // Dismiss without saving
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Pop the page and return the final set of selected apps.
              Navigator.of(context).pop(state.selectedApps);
            },
            // ✅ CHANGED: Explicitly style the TextButton to ensure visibility.
            // We use the buttonStroke color from AppColors for high contrast.
            child: Text(
              'Done',
              style: TextStyle(
                color: AppColors.buttonStroke,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: notifier.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search apps...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  // Use a very light, subtle color for the search bar background.
                  fillColor: AppColors.inactive.withAlpha(50),
                ),
              ),
            ),
            // ✅ CHANGED: The TabBar is now wrapped in a Container with a white background
            // and styled explicitly to ensure visibility and contrast.
            Container(
              color: Colors.white, // White background for the tab bar area
              child: TabBar(
                // Color of the text for the selected tab.
                labelColor: AppColors.primaryText,
                // Color of the text for unselected tabs.
                unselectedLabelColor: AppColors.secondaryText,
                // Color of the indicator line below the selected tab.
                indicatorColor: AppColors.buttonStroke,
                // Makes the indicator line thicker and more prominent.
                indicatorWeight: 3.0,
                tabs: const [
                  Tab(text: 'Suggested'),
                  Tab(text: 'All Apps'),
                ],
              ),
            ),
            // Content
            Expanded(
              child: state.data.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Error: $err')),
                data: (appData) {
                  // Filter lists based on the search query.
                  final query = state.searchQuery.toLowerCase();
                  final suggested = appData.suggestedApps
                      .where((app) => app.name.toLowerCase().contains(query))
                      .toList();
                  final all = appData.allApps
                      .where((app) => app.name.toLowerCase().contains(query))
                      .toList();

                  return TabBarView(
                    children: [
                      _AppList(
                        apps: suggested,
                        selectedApps: state.selectedApps,
                        onToggle: notifier.toggleAppSelection,
                      ),
                      _AppList(
                        apps: all,
                        selectedApps: state.selectedApps,
                        onToggle: notifier.toggleAppSelection,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A private widget to render a list of applications with checkboxes.
class _AppList extends StatelessWidget {
  final List<InstalledApp> apps;
  final Set<InstalledApp> selectedApps;
  final ValueChanged<InstalledApp> onToggle;

  const _AppList({
    required this.apps,
    required this.selectedApps,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return const Center(child: Text('No apps found.'));
    }
    // Using ListView.separated adds a visual divider between items for better clarity.
    return ListView.separated(
      itemCount: apps.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final app = apps[index];
        final isSelected = selectedApps.contains(app);
        return ListTile(
          leading: Image.memory(app.icon, width: 40, height: 40),
          title: Text(app.name),
          trailing: Checkbox(
            value: isSelected,
            onChanged: (bool? value) => onToggle(app),
            activeColor: AppColors.buttonStroke,
          ),
          onTap: () => onToggle(app),
        );
      },
    );
  }
}