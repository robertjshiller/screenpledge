import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/views/free_trial_explained_page.dart';

class SubscriptionOfferPage extends StatefulWidget {
  const SubscriptionOfferPage({super.key});

  @override
  State<SubscriptionOfferPage> createState() => _SubscriptionOfferPageState();
}

class _SubscriptionOfferPageState extends State<SubscriptionOfferPage> {
  int? _selectedBox = 1; // Annual is index 1

  // ----- COLOR CONSTANTS -----
  static const Color outlineGreen     = AppColors.buttonStroke;
  static const Color lightGreen       = Color(0xFFD4FFE9); // pale highlight
  static const Color freeTrialGreen   = AppColors.buttonFill; // green badge
  static const Color popularOrange    = Color.fromARGB(255, 255, 176, 85);   // orange badge
  static const Color badgeText        = Colors.black;

  // ----- PLAN DEFINITIONS -----
  final List<Map<String, dynamic>> plans = [
    {
      'label'       : 'Monthly',
      'price'       : '\$2.99/month',
      'freeTrial'   : true,
      'mostPopular' : false,
      'subtext'     : '',
      'savings'     : '',
    },
    {
      'label'       : 'Annual',
      'price'       : '\$19.99/year',
      'freeTrial'   : true,
      'mostPopular' : true,
      'subtext'     : 'Just \$1.67/month',
      'savings'     : '(Save 61%)',
    },
  ];

  // ===========================
  // BUILD
  // ===========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- HEADLINE ----
                Center(
                  child: Text(
                    'Commit to\nA Better You',
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 8),

                // ---- CHECKLIST ----
                const _CheckListRow(label: 'Build life-changing habits',   boldWord: 'Build'),
                const _CheckListRow(label: 'Reclaim hours of your free time', boldWord: 'Reclaim'),
                const _CheckListRow(label: 'Focus to earn real rewards',   boldWord: 'Focus'),

                const SizedBox(height: 16),

                // ---- SUBSCRIPTION CARDS ----
                ...List.generate(plans.length, (i) {
                  final plan         = plans[i];
                  final isSelected   = _selectedBox == i;
                  final isFreeTrial  = plan['freeTrial']   == true;
                  final isMostPop    = plan['mostPopular'] == true;
                  final subtext      = plan['subtext'] as String? ?? '';
                  final savings      = plan['savings'] as String? ?? '';

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? lightGreen : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: outlineGreen, width: 2),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: outlineGreen.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => setState(() => _selectedBox = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // ---- RADIO ----
                              CustomRadio(
                                selected: isSelected,
                                onTap: () => setState(() => _selectedBox = i),
                                outlineColor: outlineGreen,
                                fillColor: Colors.white,
                                selectedFillColor: AppColors.buttonFill,
                                checkmarkColor: AppColors.buttonText,
                                size: 22,
                              ),

                              const SizedBox(width: 18),

                              // ---- LABEL + PRICE ----
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan['label'] as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge!
                                          .copyWith(fontSize: 24, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      plan['price'] as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),

                              // ---- BADGES + SUBTEXT ----
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Badges row
                                  if (isFreeTrial || isMostPop)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isFreeTrial)
                                          _Badge(
                                            label: 'Free Trial',
                                            background: freeTrialGreen,
                                          ),
                                        if (isFreeTrial && isMostPop)
                                          const SizedBox(width: 6),
                                        if (isMostPop)
                                          _Badge(
                                            label: 'Most Popular',
                                            background: popularOrange,
                                          ),
                                      ],
                                    ),

                                  // Subtext / savings
                                  if (subtext.isNotEmpty || savings.isNotEmpty) ...[
                                    if (subtext.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          subtext,
                                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                                color: AppColors.secondaryText,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    if (savings.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 0),
                                        child: Text(
                                          savings,
                                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                                color: outlineGreen,
                                                fontStyle: FontStyle.italic,
                                              ),
                                        ),
                                      ),
                                  ] else
                                    const SizedBox(height: 24), // aligns Monthly badge
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 18),

                // ---- DISCLAIMER ----
                Center(
                  child: Text(
                    "You won't be charged today.\nFree trial details on the next screen.",
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: AppColors.secondaryText,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 18),

                // ---- PRIMARY BUTTON ----
                Center(
                  child: SizedBox(
                    width: 320,
                    child: PrimaryButton(
                      text: 'Continue',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const FreeTrialExplainedPage()));
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ===========================================================================
   SMALL WIDGETS
   =========================================================================== */

/// Badge with customizable background and matching stroke.
class _Badge extends StatelessWidget {
  final String label;
  final Color  background;
  const _Badge({
    required this.label,
    required this.background,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: _SubscriptionOfferPageState.outlineGreen,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: _SubscriptionOfferPageState.badgeText,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
}

/// Checklist row: bolds one keyword.
class _CheckListRow extends StatelessWidget {
  final String label, boldWord;
  const _CheckListRow({required this.label, required this.boldWord});

  @override
  Widget build(BuildContext context) {
    final parts   = label.split(' ');
    final boldIdx = parts.indexWhere((w) => w.toLowerCase() == boldWord.toLowerCase());

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 22, color: AppColors.buttonStroke),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              children: [
                for (int i = 0; i < parts.length; i++) ...[
                  TextSpan(
                    text: parts[i],
                    style: i == boldIdx
                        ? Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(fontWeight: FontWeight.bold)
                        : Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (i < parts.length - 1) const TextSpan(text: ' '),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ---- CustomRadio (unchanged) ---- */
class CustomRadio extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final double size;
  final Color outlineColor, fillColor, selectedFillColor, checkmarkColor;

  const CustomRadio({
    super.key,
    required this.selected,
    required this.onTap,
    required this.outlineColor,
    required this.fillColor,
    required this.selectedFillColor,
    required this.checkmarkColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: selected ? selectedFillColor : fillColor,
            shape: BoxShape.circle,
            border: Border.all(color: outlineColor, width: 2.5),
          ),
          child: Center(
            child: selected
                ? Icon(Icons.check, size: size * 0.65, color: checkmarkColor)
                : null,
          ),
        ),
      );
}
