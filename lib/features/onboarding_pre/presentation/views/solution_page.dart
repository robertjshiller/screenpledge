import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/config/theme/app_theme.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/views/how_it_works_sequence.dart';

class SolutionPage extends StatelessWidget {
  const SolutionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24.0),
                      Text(
                        'The ScreenPledge Solution',
                        style: textTheme.displayLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Money Backed Motivation',
                        style: textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24.0),
                      Image.asset(
                        'assets/mascot/mascot_piggy.png',
                        width: 300,
                      ),
                      const SizedBox(height: 24.0),
                      Text(
                        'Studies show that when you put money on the line, you are',
                        style: textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              AppColors.gradientGreenStart,
                              AppColors.gradientGreenEnd
                            ],
                          ).createShader(bounds),
                          child: Text(
                            '500%',
                            style: AppTheme.displayExtraLarge.copyWith(
                              color: Colors.white,
                              fontSize: 48.0,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'more likely to achieve your goals.',
                        style: textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            // Sticky bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: "See How It Works",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HowItWorksSequence(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}