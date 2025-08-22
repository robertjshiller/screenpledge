// lib/features/onboarding_post/presentation/widgets/confirmation_dialog.dart

import 'package:flutter/material.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';

/// A custom modal dialog that displays the final confirmation checkboxes
/// before the user activates their pledge.
class ConfirmationDialog extends StatefulWidget {
  /// The pledge amount, passed in to be displayed in the confirmation text.
  final double pledgeValue;
  /// The callback function that is executed when the user taps the final confirm button.
  final VoidCallback onConfirm;
  /// A flag to indicate if the parent view is currently in a loading state.
  final bool isLoading;

  const ConfirmationDialog({
    super.key,
    required this.pledgeValue,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  // Local state for the three checkboxes.
  bool _understandPledgeCharged = false;
  bool _understandOngoingCommitment = false;
  bool _authorizePaymentSave = false;

  // A helper getter to determine if the confirm button should be enabled.
  bool get _canConfirm =>
      _understandPledgeCharged &&
      _understandOngoingCommitment &&
      _authorizePaymentSave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // We use AlertDialog for a standard, platform-adaptive dialog shape.
    return AlertDialog(
      // A rounded shape to match our app's aesthetic.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      // Remove default padding so our content can go to the edges.
      contentPadding: const EdgeInsets.all(24.0),
      // The content of our dialog.
      content: Column(
        // `mainAxisSize: MainAxisSize.min` makes the dialog only as tall as its content.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Confirm Your Understanding',
            style: textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // The column of checkboxes.
          Column(
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero, // Remove extra padding
                title: Text(
                  'I understand my \$${widget.pledgeValue.toStringAsFixed(0)} pledge will be charged each day I exceed my screen time limit.',
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
                contentPadding: EdgeInsets.zero,
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
                contentPadding: EdgeInsets.zero,
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
          const SizedBox(height: 24),

          // The final confirmation button.
          PrimaryButton(
            text: widget.isLoading ? 'Finalizing...' : 'Confirm & Activate',
            // The button is disabled if not all boxes are checked or if loading.
            onPressed: _canConfirm && !widget.isLoading ? widget.onConfirm : null,
          ),
          const SizedBox(height: 8),

          // A "Cancel" button to allow the user to back out.
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Closes the dialog
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}