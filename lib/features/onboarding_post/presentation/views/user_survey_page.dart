// lib/features/onboarding_post/presentation/views/user_survey_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/features/onboarding_post/presentation/views/goal_setting_page.dart';
import 'package:screenpledge/features/onboarding_post/presentation/viewmodels/user_survey_viewmodel.dart';

class UserSurveyPage extends ConsumerStatefulWidget {
  const UserSurveyPage({super.key});

  @override
  ConsumerState<UserSurveyPage> createState() => _UserSurveyPageState();
}

class _UserSurveyPageState extends ConsumerState<UserSurveyPage> {
  // The list of answers, one for each of the 4 questions.
  final List<String?> _answers = List.filled(4, null);

  // The new set of questions and answers designed for actionable marketing insights.
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is your age range?',
      'key': 'age_range', // ✅ ADDED: A key to map the answer to the database column.
      'answers': [
        'Under 18', '18-24', '25-34', '35-44', '45-54', '55-64', '65 or older', 'Prefer not to say'
      ],
    },
    {
      'question': 'Which of these best describes your primary role?',
      'key': 'occupation', // ✅ ADDED
      'answers': [
        'Student', 'Professional (Office or Remote)', 'Professional (In-person or Field Work)', 'Parent or Guardian', 'Creator or Freelancer', 'Currently Seeking Work', 'Retired', 'Other', 'Prefer not to say'
      ],
    },
    {
      'question': 'What is your primary goal with ScreenPledge?',
      'key': 'primary_purpose', // ✅ ADDED
      'answers': [
        'Improve my focus and productivity', 'Be more present with friends and family', 'Improve my sleep and mental wellness', 'Reclaim my free time for hobbies', 'Reduce anxiety from social media', 'Other', 'Prefer not to say'
      ],
    },
    {
      'question': 'How did you first discover us?',
      'key': 'attribution_source', // ✅ ADDED
      'answers': [
        'App Store Search', 'App Store Feature', 'Social Media Ad', 'Online Article or Post', 'Friend or Family', 'Podcast or YouTube', 'Other', 'Prefer not to say'
      ],
    },
  ];

  bool get _areAllQuestionsAnswered {
    return _answers.every((answer) => answer != null);
  }

  void _submitSurvey() {
    debugPrint('UserSurveyPage: Submit button pressed. Calling ViewModel.');
    
    // ✅ CHANGED: Create a Map from the answers list to pass to the ViewModel.
    // This is more robust than relying on the order of a list.
    final Map<String, String?> answerMap = {
      for (int i = 0; i < _questions.length; i++) _questions[i]['key']: _answers[i],
    };

    ref.read(userSurveyViewModelProvider.notifier).submitSurvey(answerMap);
  }

  @override
  Widget build(BuildContext context) {
    final viewModelState = ref.watch(userSurveyViewModelProvider);

    ref.listen<AsyncValue<void>>(userSurveyViewModelProvider, (previous, next) {
      if (previous is AsyncLoading && next is AsyncData) {
        debugPrint('UserSurveyPage Listener: Detected successful save. Navigating to GoalSettingPage.');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GoalSettingPage()),
        );
      }
      if (next is AsyncError) {
        debugPrint('UserSurveyPage Listener: Detected an error - ${next.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString()), backgroundColor: Colors.red),
        );
      }
    });

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('A Few Quick Questions'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('User skipped the survey.');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const GoalSettingPage()),
              );
            },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 24.0),
                    Text(
                      'Help Us Improve',
                      style: textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Your answers will help us build a better experience for you.',
                      style: textTheme.bodyLarge?.copyWith(color: AppColors.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48.0),
                    ...List.generate(_questions.length, (index) {
                      return _QuestionDropdown(
                        question: _questions[index]['question'],
                        answers: _questions[index]['answers'].cast<String>(),
                        selectedValue: _answers[index],
                        onChanged: (newValue) {
                          setState(() {
                            _answers[index] = newValue;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              PrimaryButton(
                text: viewModelState.isLoading ? 'Saving...' : 'Continue',
                onPressed: _areAllQuestionsAnswered && !viewModelState.isLoading
                    ? _submitSurvey
                    : null,
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}


// A reusable widget for a question with a styled dropdown menu.
class _QuestionDropdown extends StatelessWidget {
  final String question;
  final List<String> answers;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  const _QuestionDropdown({
    required this.question,
    required this.answers,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The question text.
          Text(
            question,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          // The dropdown menu for the answers.
          DropdownButtonFormField<String>(
            value: selectedValue,
            hint: const Text('Select an answer'),
            isExpanded: true,
            // Styling for the dropdown.
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: AppColors.buttonStroke, width: 2),
              ),
            ),
            // Sets the background color of the dropdown menu itself.
            dropdownColor: Colors.white,
            // The list of items to display in the dropdown.
            items: answers.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                // We wrap each item in a Container to add padding and a bottom border.
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  // This adds a subtle line below each item for clear visual separation.
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Text(value),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            // Remove the default underline from the selected item text.
            selectedItemBuilder: (BuildContext context) {
              return answers.map<Widget>((String item) {
                return Text(item);
              }).toList();
            },
          ),
        ],
      ),
    );
  }
}