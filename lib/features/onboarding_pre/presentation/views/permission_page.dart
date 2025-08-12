import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'; // Required for the WidgetsBindingObserver
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
// Import the new use case for checking the permission status
import 'package:screenpledge/core/domain/usecases/is_screen_time_permission_granted.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/views/data_reveal_sequence.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/viewmodels/permission_viewmodel.dart';

/// A page that requests the user's permission to access screen time statistics.
///
/// ✅ CHANGED: This is now a ConsumerStatefulWidget that uses WidgetsBindingObserver
/// to detect when the user returns to the app from the settings screen. This allows
/// for a seamless "re-check" of the permission status.
class PermissionPage extends ConsumerStatefulWidget {
  const PermissionPage({super.key});

  @override
  ConsumerState<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends ConsumerState<PermissionPage> with WidgetsBindingObserver {
  // A flag to ensure our permission check only runs when we are actively
  // waiting for the user to return from settings.
  bool _isAwaitingPermissionResult = false;

  @override
  void initState() {
    super.initState();
    // Register this widget as an observer of app lifecycle events.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // It's crucial to remove the observer when the widget is disposed to prevent memory leaks.
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// ✅ NEW: This method is called by the system whenever the app's lifecycle state changes.
  /// This is the heart of our "re-check" strategy.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // We only care about when the app RESUMES.
    if (state != AppLifecycleState.resumed) return;

    // If the app has resumed AND we were waiting for a permission result,
    // it's time to perform our check.
    if (_isAwaitingPermissionResult) {
      // Reset the flag so this doesn't run again unintentionally.
      _isAwaitingPermissionResult = false;
      _checkPermissionAndNavigate();
    }
  }

  /// ✅ NEW: A dedicated method to perform the permission check and handle navigation.
  Future<void> _checkPermissionAndNavigate() async {
    // We read the IsScreenTimePermissionGranted use case directly to perform the check.
    final isGranted = await ref.read(isPermissionGrantedUseCaseProvider)();

    // Ensure the widget is still in the tree before interacting with its context.
    if (!mounted) return;

    if (isGranted) {
      // SUCCESS: If permission was granted, navigate to the next step.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DataRevealSequence()),
      );
    } else {
      // FAILURE: If the user returned without granting permission, show a helpful message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission is required to continue. Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the ViewModel's state to update the UI (e.g., show a loading indicator).
    final viewModelState = ref.watch(permissionViewModelProvider);

    // Listen for any errors that might occur when trying to open settings.
    ref.listen<AsyncValue<void>>(permissionViewModelProvider, (_, state) {
      if (state is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error.toString()), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40), // Added for top padding
                      Text(
                        'Let\'s Keep You \nFocused',
                        style: Theme.of(context).textTheme.displayLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Image.asset(
                        'assets/mascot/mascot_thumbs_up.png',
                        width: MediaQuery.of(context).size.width * 0.75,
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22.0),
                        child: Text(
                          'To help you build better habits, ScreenPledge needs permission to view your screen time stats. Your data is always kept private and secure.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20), // Added for bottom padding
                    ],
                  ),
                ),
              ),
            ),
            // This is the "sticky" bottom part
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32), // Adjusted padding
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: viewModelState.isLoading ? 'Opening Settings...' : 'Allow Screen Time Access',
                      onPressed: viewModelState.isLoading
                          ? null
                          : () async {
                              // ✅ REWORKED: This is the "Fire" step.
                              // 1. Set our flag so the lifecycle observer knows to run the check.
                              _isAwaitingPermissionResult = true;

                              // 2. Call the ViewModel to open the settings screen.
                              await ref.read(permissionViewModelProvider.notifier).openSettings();

                              // 3. That's it. We do not await a result. The "Re-Check" logic
                              // is now handled entirely by didChangeAppLifecycleState.
                            },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We only see app usage time -- never your content',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}