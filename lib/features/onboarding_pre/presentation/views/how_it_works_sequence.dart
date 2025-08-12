import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/views/subscription_primer_page.dart';

class HowItWorksSequence extends StatefulWidget {
  const HowItWorksSequence({super.key});

  @override
  State<HowItWorksSequence> createState() => _HowItWorksSequenceState();
}

class _HowItWorksSequenceState extends State<HowItWorksSequence> {
  int _sequence = 0;

  final List<Map<String, String>> cardData = [
    {
      "title": "1. Make a Pledge",
      "description": "Set a daily screen time limit and make a financial pledge. This is your commitment to yourself.",
      "image": "assets/mascot/mascot_pledge.png",
      "smallText": "You set your exact terms.\nTotal screen time or just a few problematic apps?\nYour choice.",
    },
    {
      "title": "2. Face Accountability",
      "description": "If you exceed your time limit, your pledge is charged. No more dodging accountability.",
      "image": "assets/mascot/mascot_accountability.png", // Placeholder
      "smallText": "Cancel, pause, or edit your pledge if circumstances change.\nApplies from the next day,",
    },
    {
      "title": "3. Earn Rewards",
      "description": "For every successful day, you earn Pledge Points (PP) which can be redeemed for real-world rewards, such as subscriptions, gift cards, and more.",
      "image": "assets/mascot/mascot_reward.png", // Placeholder
      "smallText": "Be extra consistent to earn bonus rewards!\nTurn your discipline into dollars.",
    },
  ];

  void _nextSequence() {
    setState(() {
      if (_sequence < cardData.length - 1) {
        _sequence++;
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionPrimerPage()));
      }
    });
  }

  void _previousSequence() {
    setState(() {
      if (_sequence > 0) {
        _sequence--;

      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
              
            // Top navigation row with back arrow and sequence indicator
            Padding(
              padding: const EdgeInsets.only(
                  top: 8.0, left: 16.0, right: 24.0, bottom: 12.0),
              child: Row(
                children: [
                  // Back Arrow
                  SizedBox(
                    width: 48, // Reserve space to prevent layout shift
                    child: AnimatedOpacity(
                      opacity: _sequence > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
                        onPressed: _sequence > 0 ? _previousSequence : null,
                      ),
                    ),
                  ),
                  // Sequence Indicator
                  Expanded(
                    child: Row(
                      children: List.generate(cardData.length, (index) {
                        return Expanded(
                          child: Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 2.0),
                            height: 3.0, // Made bars thinner
                            decoration: BoxDecoration(
                              color: _sequence >= index
                                  ? AppColors.primaryText // Changed to black
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: IndexedStack(
                  index: _sequence,
                  children: [
                    // Sequence 1
                    Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            
                            Image.asset(
                              cardData[0]["image"]!,
                              height: 200,
                            ),
                            const SizedBox(height: 24.0),
                            Text(
                              cardData[0]["title"]!,
                              style: textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                cardData[0]["description"]!,
                                style: textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 48.0),
                          ],
                        ),
                      ),
                    ),

                    // Sequence 2
                    Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              cardData[1]["image"]!,
                              height: 200,
                            ),
                            const SizedBox(height: 24.0),
                            Text(
                              cardData[1]["title"]!,
                              style: textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                cardData[1]["description"]!,
                                style: textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 48.0),
                          ],
                        ),
                      ),
                    ),

                    // Sequence 3
                    Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              cardData[2]["image"]!,
                              height: 200,
                            ),
                            const SizedBox(height: 24.0),
                            Text(
                              cardData[2]["title"]!,
                              style: textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                cardData[2]["description"]!,
                                style: textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 48.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
              child: Text(
                cardData[_sequence]["smallText"]!,
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            // Continue Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: "Continue",
                  onPressed: _nextSequence,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}