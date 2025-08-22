// lib/features/onboarding_post/presentation/views/pledge_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ ADDED
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/features/dashboard/presentation/views/dashboard_page.dart';
// ✅ ADDED: Import for the new ViewModel.
import 'package:screenpledge/features/onboarding_post/presentation/viewmodels/pledge_viewmodel.dart';

// ✅ CHANGED: Converted to a ConsumerStatefulWidget.
class PledgePage extends ConsumerStatefulWidget {
  const PledgePage({super.key});

  @override
  ConsumerState<PledgePage> createState() => _PledgePageState();
}

class _PledgePageState extends ConsumerState<PledgePage> {
  // These remain as local UI state for the widgets on this page.
  double _currentPledgeValue = 25.0;
  bool _understandPledgeCharged = false;
  bool _understandOngoingCommitment = false;
  bool _authorizePaymentSave = false;

  // A helper getter to determine if the main button should be enabled.
  bool get _canActivatePledge =>
      _understandPledgeCharged &&
      _understandOngoingCommitment &&
      _authorizePaymentSave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // ✅ ADDED: Watch the ViewModel's state for loading/error status.
    final viewModelState = ref.watch(pledgeViewModelProvider);

    // ✅ ADDED: A listener to handle navigation and errors.
    ref.listen<AsyncValue<void>>(pledgeViewModelProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        data: (_) {
          // On success, navigate to the dashboard.
          if (previous?.isLoading == true) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DashboardPage()),
              (route) => false, // This removes all previous routes.
            );
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Make Your Pledge',
          style: textTheme.displayLarge,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(flex: 1),
                        Text(
                          'This is the single most effective step to guarantee your success.',
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Image.asset(
                          'assets/mascot/mascot_pledge_coin.png',
                          height: 100,
                        ),
                        const SizedBox(height: 16),
                        _PledgeOptionBox(
                          child: Text(
                            'Users who set a meaningful pledge are 5 times more likely to meet their goals.',
                            style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _PledgeOptionBox(
                          child: Text(
                            'Earn rewards 10x faster by setting a pledge!',
                            style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Spacer(flex: 2),
                        Text(
                          'Choose An Amount',
                          style: textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Slider(
                                value: _currentPledgeValue,
                                min: 5.0,
                                max: 100.0,
                                activeColor: AppColors.buttonFill,
                                inactiveColor: AppColors.inactive,
                                onChanged: (newValue) {
                                  setState(() {
                                    _currentPledgeValue = newValue;
                                  });
                                },
                              ),
                            ),
                            Text(
                              '\$${_currentPledgeValue.toStringAsFixed(0)}',
                              style: textTheme.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Confirm Your Understanding',
                          style: textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            CheckboxListTile(
                              title: Text(
                                'I understand my \$${_currentPledgeValue.toStringAsFixed(0)} pledge will be charged each day I exceed my screen time limit.',
                                style: textTheme.bodySmall,
                              ),
                              value: _understandPledgeCharged,
                              onChanged: (bool? newValue) {
                                setState(() {
                                  _understandPledgeCharged = newValue!;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              title: Text(
                                'I understand that this is an ongoing commitment that I can pause, edit, or cancel in settings anytime (effective the next day).',
                                style: textTheme.bodySmall,
                              ),
                              value: _understandOngoingCommitment,
                              onChanged: (bool? newValue) {
                                setState(() {
                                  _understandOngoingCommitment = newValue!;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              title: Text(
                                'I authorize ScreenPledge to save my payment method via Stripe.',
                                style: textTheme.bodySmall,
                              ),
                              value: _authorizePaymentSave,
                              onChanged: (bool? newValue) {
                                setState(() {
                                  _authorizePaymentSave = newValue!;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ],
                        ),
                        const Spacer(flex: 2),
                        PrimaryButton(
                          // ✅ CHANGED: Logic is now driven by the ViewModel.
                          text: viewModelState.isLoading ? 'Finalizing...' : 'Activate My Pledge',
                          onPressed: _canActivatePledge && !viewModelState.isLoading
                              ? () {
                                  // TODO: Implement Stripe payment method setup here.
                                  // For now, we'll just call the ViewModel.
                                  final amountInCents = (_currentPledgeValue * 100).toInt();
                                  ref.read(pledgeViewModelProvider.notifier).activatePledge(amountCents: amountInCents);
                                }
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: viewModelState.isLoading
                              ? null
                              : () {
                                  // ✅ CHANGED: Call the skip method on the ViewModel.
                                  ref.read(pledgeViewModelProvider.notifier).skipPledge();
                                },
                          child: Text(
                            'Not Now',
                            style: TextStyle(color: AppColors.inactive),
                          ),
                        ),
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// This private helper widget remains unchanged.
class _PledgeOptionBox extends StatelessWidget {
  final Widget child;

  const _PledgeOptionBox({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.buttonStroke,
          width: 2.0,
        ),
      ),
      child: Center(child: child),
    );
  }
}