// lib/features/onboarding_post/presentation/views/account_creation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/features/onboarding_post/presentation/viewmodels/account_creation_viewmodel.dart';
// ✅ ADDED: Import the new pages we'll be navigating to.
import 'package:screenpledge/features/onboarding_post/presentation/views/congratulations_page.dart';
import 'package:screenpledge/features/onboarding_post/presentation/views/verify_email_page.dart';

class AccountCreationPage extends ConsumerWidget {
  const AccountCreationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final viewModelState = ref.watch(accountCreationViewModelProvider);

    ref.listen<AsyncValue<void>>(accountCreationViewModelProvider, (_, state) {
      if (state is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error.toString())),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        // This pattern allows the use of Spacers for proportional layout
        // while ensuring the content can scroll if it overflows, for example
        // when the keyboard is displayed on a small screen.
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 2),
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
                        const Spacer(flex: 2),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          controller: passwordController,
                          decoration:
                              const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                        ),
                        const SizedBox(height: 32.0),
                        PrimaryButton(
                          text: viewModelState.isLoading
                              ? 'Creating...'
                              : 'Create Account',
                          onPressed: viewModelState.isLoading
                              ? null
                              : () async {
                                  final email = emailController.text.trim();
                                  // ✅ CHANGED: Capture the result from the ViewModel call.
                                  final result = await ref
                                      .read(accountCreationViewModelProvider
                                          .notifier)
                                      .signUpUser(
                                        email: email,
                                        password:
                                            passwordController.text.trim(),
                                      );

                                  // ✅ CHANGED: Implement conditional navigation based on the result.
                                  if (context.mounted) {
                                    switch (result) {
                                      case SignUpResult
                                            .successNeedsVerification:
                                        // For email/password, go to the verification page.
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                VerifyEmailPage(email: email),
                                          ),
                                        );
                                        break;
                                      case SignUpResult.successVerified:
                                        // For OAuth, go directly to the congratulations page.
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const CongratulationsPage(),
                                          ),
                                        );
                                        break;
                                      case SignUpResult.failure:
                                        // Do nothing, the listener has already shown an error SnackBar.
                                        break;
                                    }
                                  }
                                },
                        ),
                        const SizedBox(height: 24.0),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('OR'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                        ElevatedButton.icon(
                          icon: const Icon(Icons
                              .g_mobiledata), // TODO: Replace with Google icon
                          label: const Text('Continue with Google'),
                          onPressed: () {
                            // TODO: Call a new `signUpWithGoogle` method on the ViewModel.
                          },
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
                          onPressed: () {
                            // TODO: Call a new `signUpWithApple` method on the ViewModel.
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.black,
                          ),
                        ),
                        const Spacer(flex: 2),
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
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}