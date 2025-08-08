import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/views/subscription_offer_page.dart';

class SubscriptionPrimerPage extends StatelessWidget {
  const SubscriptionPrimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // No title here
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "You're One Step Away\nfrom\nReclaiming Your Time.",
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Text(
                "People always say\n“time is more valuable than money.”\n\nBut while most wouldn’t casually waste money, we do the equivalent every day with our time, lost in endless scrolling.",
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Text(
                "With ScreenPledge, you can...",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                "Save 2+ hours a day, equivalent to 9 years of your life.",
                style: TextStyle(color: AppColors.primaryText),
              ),
              value: true,
              onChanged: null,
            ),
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                "Regain your lost attention span.",
                style: TextStyle(color: AppColors.primaryText),
              ),
              value: true,
              onChanged: null,
            ),
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                "Have the time to live your best life and accomplish your dreams.",
                style: TextStyle(color: AppColors.primaryText),
              ),
              value: true,
              onChanged: null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Text(
                "Are you ready to reclaim what matters most—your time?",
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: PrimaryButton(
                text: "Reclaim My Time",
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionOfferPage()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
