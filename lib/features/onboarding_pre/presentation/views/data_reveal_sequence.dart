import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/config/theme/app_theme.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/views/solution_page.dart';

class DataRevealSequence extends StatefulWidget {
  const DataRevealSequence({super.key});

  @override
  State<DataRevealSequence> createState() => _DataRevealSequenceState();
}

class _DataRevealSequenceState extends State<DataRevealSequence> {
  int _sequence = 0;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page != null) {
        setState(() {
          _currentPage = _pageController.page!.round();
          print('Current Page: $_currentPage'); // Debug print
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextSequence() {
    setState(() {
      if (_sequence < 3) {
        _sequence++;
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SolutionPage(),
          ),
        );
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
                  top: 16.0, left: 16.0, right: 24.0, bottom: 16.0),
              child: Row(
                children: [
                  // Back Arrow
                  SizedBox(
                    width: 48, // Reserve space to prevent layout shift
                    child: AnimatedOpacity(
                      opacity: _sequence > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.primaryText),
                        onPressed: _sequence > 0 ? _previousSequence : null,
                      ),
                    ),
                  ),
                  // Sequence Indicator
                  Expanded(
                    child: Row(
                      children: List.generate(4, (index) {
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
                      child: Text(
                        "A bit of not-so-great news, but also some fantastic news.",
                        style: textTheme.displayLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Sequence 2
                    SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24.0),
                          Image.asset(
                            'assets/mascot/mascot_calculating.png',
                            width: MediaQuery.of(context).size.width * 0.75,
                          ),
                          const SizedBox(height: 24.0),
                          Text(
                            "The bad news?\nThis year alone, you'll spend around 80 days glued to your phone.\nOver your life you're on track to spend",
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
                                "16 years",
                                style: AppTheme.displayExtraLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            "of your life looking down at a screen.\nYes, you read that correctly.",
                            style: textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Sequence 3
                    // Sequence 3
                    Column(
                      children: [
                        const SizedBox(height: 48.0),
                        Text(
                          "Instead of scrolling, you could...",
                          style: textTheme.displayLarge,
                          textAlign: TextAlign.center,
                        ),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: 3,
                                itemBuilder: (context, index) {
                                  return _buildCarouselCard(index);
                                },
                              ),
                              // Left Arrow
                              Positioned(
                                left: 0,
                                child: AnimatedOpacity(
                                  opacity: _currentPage > 0 ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryText),
                                    onPressed: () {
                                      if (_currentPage > 0) {
                                        _pageController.previousPage(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                              // Right Arrow
                              Positioned(
                                right: 0,
                                child: AnimatedOpacity(
                                  opacity: _currentPage < 2 ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios, color: AppColors.primaryText),
                                    onPressed: () {
                                      if (_currentPage < 2) {
                                        _pageController.nextPage(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return Container(
                              width: 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? AppColors.primaryText
                                    : Colors.grey[300],
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24.0),
                      ],
                    ),

                    // Sequence 4
                    Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't worry.\nWe got good news!\n\nWith ScreenPledge, you can reclaim",
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
                                  "5+ years",
                                  style: AppTheme.displayExtraLarge.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              "of your life from distractions-- and finally have the time to live your best life.",
                              style: textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Disclaimer text (conditionally shown)
            if (_sequence == 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, left: 24.0, right: 24.0),
                child: Text(
                  "Based on your current Screen Time, for 16 hour waking days.",
                  style: textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              )
            else
              const SizedBox(height: 40), // Placeholder for the disclaimer space

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

  Widget _buildCarouselCard(int index) {
    final List<Map<String, String>> cardData = [
      {
        "text": "Read 1,000 books",
        "image": "assets/mascot/mascot_books.png",
      },
      {
        "text": "Have 1,500 family dinners",
        "image": "assets/mascot/mascot_family.png",
      },
      {
        "text": "Take 360 life-changing trips",
        "image": "assets/mascot/mascot_travelling.png",
      },
    ];

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              cardData[index]["image"]!,
              height: 300,
            ),
            const SizedBox(height: 24.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                cardData[index]["text"]!,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}