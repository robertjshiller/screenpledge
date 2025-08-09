import 'package:flutter/material.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/features/onboarding_post/presentation/views/goal_setting_page.dart';

class UserSurveySequence extends StatefulWidget {
  const UserSurveySequence({super.key});

  @override
  State<UserSurveySequence> createState() => _UserSurveySequenceState();
}

class _UserSurveySequenceState extends State<UserSurveySequence> {
  int _sequence = 0;
  final List<String?> _answers = List.filled(4, null);

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is your age range?',
      'answers': ['Under 18', '18-24', '25-34', '35-44', '45+'],
    },
    {
      'question': 'What is your occupation?',
      'answers': ['Student', 'Employed', 'Unemployed', 'Other'],
    },
    {
      'question': 'Why did you join ScreenPledge?',
      'answers': [
        'To be more productive',
        'To spend more time with family',
        'To improve my mental health',
        'Other'
      ],
    },
    {
      'question': 'How did you hear about us?',
      'answers': ['App Store', 'Social Media', 'Friend or Family', 'Other'],
    },
  ];

  void _nextSequence() {
    setState(() {
      if (_sequence < _questions.length - 1) {
        _sequence++;
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GoalSettingPage()),
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
      appBar: AppBar(
        leading: AnimatedOpacity(
          opacity: _sequence > 0 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
            onPressed: _sequence > 0 ? _previousSequence : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
               Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const GoalSettingPage()),
              );
            },
            child: const Text('Skip'),
          ),
        ],
        title: Row(
          children: List.generate(_questions.length, (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                height: 3.0,
                decoration: BoxDecoration(
                  color: _sequence >= index
                      ? AppColors.primaryText
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            );
          }),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24.0),
              Text(
                _questions[_sequence]['question'],
                style: textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48.0),
              Expanded(
                child: ListView.builder(
                  itemCount: _questions[_sequence]['answers'].length,
                  itemBuilder: (context, index) {
                    final answer = _questions[_sequence]['answers'][index];
                    final isSelected = _answers[_sequence] == answer;
                    return _AnswerBox(
                      text: answer,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _answers[_sequence] = answer;
                        });
                      },
                    );
                  },
                ),
              ),
              PrimaryButton(
                text: 'Continue',
                onPressed: _answers[_sequence] != null ? _nextSequence : null,
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerBox extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnswerBox({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.buttonFill : const Color(0xFFFDFDFD),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected ? AppColors.buttonStroke : Colors.grey[300]!,
            width: 2.0,
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isSelected ? AppColors.buttonText : AppColors.primaryText,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}