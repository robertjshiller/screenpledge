// lib/features/onboarding_post/presentation/views/verify_email_page.dart

import 'dart:async'; // ✅ FIXED: Corrected the import from 'dart-async' to 'dart:async'.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/features/onboarding_post/presentation/viewmodels/verify_email_viewmodel.dart';
import 'package:screenpledge/features/onboarding_post/presentation/views/congratulations_page.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  final String email;
  const VerifyEmailPage({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String get _otp => _controllers.map((c) => c.text).join();

  // --- Resend and Rate-Limiting Logic ---
  Timer? _cooldownTimer;
  int _cooldownSeconds = 60;
  
  // ✅ ADDED: A counter to track resend attempts for rate-limiting.
  int _resendAttempts = 0;
  static const int _maxResendAttempts = 10; // A reasonable, secure limit.

  @override
  void initState() {
    super.initState();
    _startCooldown();
    debugPrint('[VerifyEmailPage] initState: Page loaded, resend cooldown started.');
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    debugPrint('[VerifyEmailPage] Cooldown: Timer started for $_cooldownSeconds seconds.');
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds == 0) {
        timer.cancel();
        debugPrint('[VerifyEmailPage] Cooldown: Timer finished.');
      }
      if (mounted) {
        setState(() {
          if (_cooldownSeconds > 0) _cooldownSeconds--;
        });
      }
    });
  }

  Future<void> _handleResend() async {
    // ✅ ADDED: The rate-limiting check.
    if (_resendAttempts >= _maxResendAttempts) {
      debugPrint('[VerifyEmailPage] Rate Limit: Maximum resend attempts reached.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Max resend attempts reached. Please contact support if you need help.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return; // Stop the function here.
    }

    if (_cooldownSeconds == 0) {
      debugPrint('[VerifyEmailPage] Resend: Button pressed. Attempt #${_resendAttempts + 1}');
      
      // Increment the attempt counter BEFORE making the network call.
      setState(() {
        _resendAttempts++;
      });

      await ref.read(verifyEmailViewModelProvider.notifier).resendCode(email: widget.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A new verification code has been sent.'),
            backgroundColor: AppColors.buttonStroke,
          ),
        );
      }
      
      setState(() {
        _cooldownSeconds = 60; // Reset cooldown
      });
      _startCooldown();
    }
  }

  Future<void> _handleVerify() async {
    if (_otp.length == 6) {
      debugPrint('[VerifyEmailPage] Verify: Attempting to verify OTP: $_otp');
      final success = await ref
          .read(verifyEmailViewModelProvider.notifier)
          .verifyCode(email: widget.email, token: _otp);

      if (success && mounted) {
        debugPrint('[VerifyEmailPage] Verify: SUCCESS. Navigating to CongratulationsPage.');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CongratulationsPage()),
        );
      } else {
        debugPrint('[VerifyEmailPage] Verify: FAILED. Error was shown by the listener.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(verifyEmailViewModelProvider, (_, state) {
      if (state is AsyncError) {
        debugPrint('[VerifyEmailPage] Listener: Caught an error - ${state.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error.toString()), backgroundColor: Colors.red),
        );
      }
    });

    final isLoading = ref.watch(verifyEmailViewModelProvider).isLoading;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.password_rounded, size: 80, color: AppColors.buttonStroke),
              const SizedBox(height: 32),
              Text('Enter Your Code', style: textTheme.displayLarge, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                "We've sent a 6-digit code to\n${widget.email}",
                style: textTheme.bodyLarge?.copyWith(color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return _OtpInputBox(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      setState(() {});
                    },
                  );
                }),
              ),
              const Spacer(),

              PrimaryButton(
                text: isLoading ? 'Verifying...' : 'Verify & Continue',
                onPressed: _otp.length == 6 && !isLoading ? _handleVerify : null,
              ),
              const SizedBox(height: 24),

              TextButton(
                // ✅ CHANGED: The button is now disabled if the rate limit is reached.
                onPressed: _cooldownSeconds == 0 && _resendAttempts < _maxResendAttempts
                    ? _handleResend
                    : null,
                child: Text(
                  _resendAttempts >= _maxResendAttempts
                      ? 'Max attempts reached'
                      : _cooldownSeconds == 0
                          ? 'Resend Code'
                          : 'Resend in $_cooldownSeconds seconds',
                  style: TextStyle(
                    color: _cooldownSeconds == 0 && _resendAttempts < _maxResendAttempts
                        ? AppColors.buttonStroke
                        : AppColors.secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpInputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpInputBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 60,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.headlineMedium,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.inactive),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.buttonStroke, width: 2),
          ),
        ),
      ),
    );
  }
}