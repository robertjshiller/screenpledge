
import 'package:screenpledge/features/onboarding_post/presentation/views/user_survey_sequence.dart';
import 'package:flutter/material.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';

class AccountCreationPage extends StatelessWidget {
  const AccountCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48.0),
                Text(
                  'Create Your Account',
                  style: textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Secure your progress and start your journey.',
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48.0),

                // Email Field
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16.0),

                // Password Field
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32.0),

                // Create Account Button
                PrimaryButton(
                  text: 'Create Account',
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const UserSurveySequence(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24.0),

                // Divider
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24.0),

                // OAuth Buttons
                ElevatedButton.icon(
                  icon: const Icon(Icons.g_mobiledata), // Placeholder for Google
                  label: const Text('Continue with Google'),
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.primaryText, 
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppColors.inactive),
                  ),
                ),
                const SizedBox(height: 12.0),
                ElevatedButton.icon(
                  icon: const Icon(Icons.apple),
                  label: const Text('Continue with Apple'),
                  onPressed: () {},
                   style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, 
                    backgroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 48.0),

                // Login Link
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to login page
                  },
                  child: Text(
                    'Already have an account? Log In',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
