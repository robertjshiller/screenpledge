// lib/features/onboarding_post/presentation/views/user_survey_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ ADDED
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/features/onboarding_post/presentation/views/goal_setting_page.dart';
import 'package:screenpledge/features/onboarding_post/presentation/viewmodels/user_survey_viewmodel.dart'; // ✅ ADDED

// ✅ CHANGED: Converted to a ConsumerStatefulWidget to manage local state (the answers)
// while also being able to interact with Riverpod providers.
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
      'answers': [
        'Under 18',
        '18-24',
        '25-34',
        '35-44',
        '45-54',
        '55-64',
        '65 or older',
        'Prefer not to say'
      ],
    },
    {
      'question': 'Which of these best describes your primary role?',
      'answers': [
        'Student',
        'Professional (Office or Remote)',
        'Professional (In-person or Field Work)',
        'Parent or Guardian',
        'Creator or Freelancer',
        'Currently Seeking Work',
        'Retired',
        'Other',
        'Prefer not to say'
      ],
    },
    {
      'question': 'What is your primary goal with ScreenPledge?',
      'answers': [
        'Improve my focus and productivity',
        'Be more present with friends and family',
        'Improve my sleep and mental wellness',
        'Reclaim my free time for hobbies',
        'Reduce anxiety from social media',
        'Other',
        'Prefer not to say'
      ],
    },
    {
      'question': 'How did you first discover us?',
      'answers': [
        'App Store Search',
        'App Store Feature',
        'Social Media Ad',
        'Online Article or Post',
        'Friend or Family',
        'Podcast or YouTube',
        'Other',
        'Prefer not to say'
      ],
    },
  ];

  // A helper function to check if all questions have been answered.
  bool get _areAllQuestionsAnswered {
    return _answers.every((answer) => answer != null);
  }

  // ✅ CHANGED: This method now calls the ViewModel to handle the business logic.
  void _submitSurvey() {
    debugPrint('UserSurveyPage: Submit button pressed. Calling ViewModel.');
    // We call the ViewModel's method. We don't need to `await` it here because
    // the `ref.listen` block below will handle the result of the operation.
    ref.read(userSurveyViewModelProvider.notifier).submitSurvey(_answers);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ADDED: Watch the ViewModel's state to react to loading/error states.
    final viewModelState = ref.watch(userSurveyViewModelProvider);

    // ✅ ADDED: A listener to handle side-effects like navigation and showing SnackBars.
    ref.listen<AsyncValue<void>>(userSurveyViewModelProvider, (previous, next) {
      // On successful submission (when state changes from loading to data), navigate.
      if (previous is AsyncLoading && next is AsyncData) {
        debugPrint('UserSurveyPage Listener: Detected successful save. Navigating to GoalSettingPage.');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GoalSettingPage()),
        );
      }
      // On error, show a SnackBar with the error message.
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
        // The skip button allows users to bypass the survey if they choose.
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
              // Use an Expanded widget with a ListView to make the content scrollable.
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

                    // We now generate all question widgets in a single list.
                    ...List.generate(_questions.length, (index) {
                      return _QuestionDropdown(
                        question: _questions[index]['question'],
                        answers: _questions[index]['answers'].cast<String>(),
                        selectedValue: _answers[index],
                        onChanged: (newValue) {
                          // We use setState to update the local UI when an answer is selected.
                          setState(() {
                            _answers[index] = newValue;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              // The primary action button to submit the survey.
              PrimaryButton(
                // ✅ CHANGED: Button text and enabled/disabled state are now driven by the ViewModel.
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