// lib/features/onboarding_post/presentation/views/user_survey_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // ✅ NEW: A TextEditingController to manage the state of the name field.
  final _nameController = TextEditingController();

  // The list of answers for the dropdowns.
  final List<String?> _answers = List.filled(4, null);

  // The questions and answers data remains the same.
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is your age range?',
      'key': 'age_range',
      'answers': ['Under 18', '18-24', '25-34', '35-44', '45-54', '55-64', '65 or older', 'Prefer not to say'],
    },
    {
      'question': 'Which of these best describes your primary role?',
      'key': 'occupation',
      'answers': ['Student', 'Professional (Office or Remote)', 'Professional (In-person or Field Work)', 'Parent or Guardian', 'Creator or Freelancer', 'Currently Seeking Work', 'Retired', 'Other', 'Prefer not to say'],
    },
    {
      'question': 'What is your primary goal with ScreenPledge?',
      'key': 'primary_purpose',
      'answers': ['Improve my focus and productivity', 'Be more present with friends and family', 'Improve my sleep and mental wellness', 'Reclaim my free time for hobbies', 'Reduce anxiety from social media', 'Other', 'Prefer not to say'],
    },
    {
      'question': 'How did you first discover us?',
      'key': 'attribution_source',
      'answers': ['App Store Search', 'App Store Feature', 'Social Media Ad', 'Online Article or Post', 'Friend or Family', 'Podcast or YouTube', 'Other', 'Prefer not to say'],
    },
  ];

  /// ✅ CHANGED: The validation logic now also checks if the name field is not empty.
  bool get _canSubmit {
    final isNameEntered = _nameController.text.trim().isNotEmpty;
    final areAllQuestionsAnswered = _answers.every((answer) => answer != null);
    return isNameEntered && areAllQuestionsAnswered;
  }

  void _submitSurvey() {
    debugPrint('UserSurveyPage: Submit button pressed. Calling ViewModel.');
    
    final Map<String, String?> answerMap = {
      for (int i = 0; i < _questions.length; i++) _questions[i]['key']: _answers[i],
    };

    // ✅ CHANGED: Pass the display name and the answers to the ViewModel.
    ref.read(userSurveyViewModelProvider.notifier).submitSurvey(
      displayName: _nameController.text.trim(),
      answers: answerMap,
    );
  }

  // ✅ NEW: Dispose the controller when the widget is removed from the tree.
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModelState = ref.watch(userSurveyViewModelProvider);

    // The listener for navigation and error handling remains the same.
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

                    // ✅ NEW: The display name text field.
                    _DisplayNameField(controller: _nameController),

                    // Generate the dropdowns for the other questions.
                    ...List.generate(_questions.length, (index) {
                      return _QuestionDropdown(
                        question: _questions[index]['question'],
                        answers: _questions[index]['answers'].cast<String>(),
                        selectedValue: _answers[index],
                        onChanged: (newValue) {
                          // Using setState here is perfectly fine for simple form state.
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
                // ✅ CHANGED: Use the new validation getter.
                onPressed: _canSubmit && !viewModelState.isLoading
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

/// ✅ NEW: A dedicated widget for the display name text field.
class _DisplayNameField extends StatelessWidget {
  final TextEditingController controller;
  const _DisplayNameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What should we call you?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            // Set the character limit.
            maxLength: 30,
            // Use a text input formatter to enforce the limit.
            inputFormatters: [LengthLimitingTextInputFormatter(30)],
            decoration: InputDecoration(
              hintText: 'e.g., Brian, Bee, or your full name',
              // The helper text is shown below the field.
              helperText: 'This will be used to personalize your experience.',
              filled: true,
              fillColor: Colors.white,
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
          ),
        ],
      ),
    );
  }
}


// The _QuestionDropdown widget remains unchanged.
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
          Text(
            question,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedValue,
            hint: const Text('Select an answer'),
            isExpanded: true,
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
            dropdownColor: Colors.white,
            items: answers.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
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