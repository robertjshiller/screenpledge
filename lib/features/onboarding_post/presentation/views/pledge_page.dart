import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/features/dashboard/presentation/views/dashboard_page.dart';

class PledgePage extends StatefulWidget { // Changed to StatefulWidget
  const PledgePage({super.key});

  @override
  State<PledgePage> createState() => _PledgePageState();
}

class _PledgePageState extends State<PledgePage> {
  double _currentPledgeValue = 25.0; // Initial value for the slider changed to 25.0
  bool _understandPledgeCharged = false;
  bool _understandOngoingCommitment = false;
  bool _authorizePaymentSave = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Make Your Pledge',
          style: textTheme.displayLarge, // Apply displayLarge text style
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0), // Reduced top padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'This is the single most effective step to guarantee your success.',
              style: textTheme.bodyLarge, // Apply bodyLarge text style
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16), // Reduced spacing above image
            Image.asset(
              'assets/mascot/mascot_pledge_coin.png',
              height: 100, // Set height to 100
            ),
            const SizedBox(height: 16), // Reduced spacing below image
            _PledgeOptionBox(
              child: Text(
                'Users who set a meaningful pledge are 5 times more likely to meet their goals.',
                style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic), // Apply bodySmall and italicize
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16), // Spacing between the pledge option boxes
            _PledgeOptionBox(
              child: Text(
                'Earn rewards 10x faster by setting a pledge!',
                style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic), // Apply bodySmall and italicize
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24), // Spacing before the slider
            Text(
              'Choose An Amount',
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16), // Spacing between text and slider
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Slider(
                    value: _currentPledgeValue,
                    min: 5.0,
                    max: 100.0,
                    activeColor: AppColors.buttonFill, // Green color
                    inactiveColor: AppColors.inactive, // Grey color for inactive track
                    onChanged: (newValue) {
                      setState(() {
                        _currentPledgeValue = newValue; // Update the slider value
                      });
                    },
                  ),
                ),
                Text(
                  '\$${_currentPledgeValue.toStringAsFixed(0)}',
                  style: textTheme.headlineSmall, // Display value
                ),
              ],
            ),
            const SizedBox(height: 16), // Spacing between slider and new text
            Text(
              'Confirm Your Understanding',
              style: textTheme.headlineSmall, // Apply headlineSmall text style
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16), // Spacing between new text and checkboxes
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
                  controlAffinity: ListTileControlAffinity.leading, // Checkbox on the left
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
            const SizedBox(height: 32), // Spacing between checkboxes and buttons
            PrimaryButton(
              text: 'Activate My Pledge',
              onPressed: () {
                // TODO: Implement activation logic
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DashboardPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16), // Spacing between buttons
            TextButton(
              onPressed: () {
                // TODO: Implement Not Now logic
              },
              child: Text(
                'Not Now',
                style: TextStyle(color: AppColors.inactive), // Greyed out text
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// New widget for the pledge option box
class _PledgeOptionBox extends StatelessWidget {
  final Widget child;

  const _PledgeOptionBox({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Take full available width
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(20.0), // Curved corners from PrimaryButton
        border: Border.all(
          color: AppColors.buttonStroke, // Green stroke from PrimaryButton
          width: 2.0,
        ),
      ),
      child: Center(child: child), // Center the content
    );
  }
}