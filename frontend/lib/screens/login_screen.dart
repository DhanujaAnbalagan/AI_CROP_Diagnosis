import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/audio_service.dart';

/// Screen for user authentication via Phone Number and OTP.
/// Redesigned with AgriTech Premium Light theme.
class LoginScreen extends StatefulWidget {
  final Function() onLogin;
  final VoidCallback onSkip;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onSkip,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  String _step = 'phone'; // 'phone' or 'otp'
  bool _loading = false;
  String? _verificationId;
  
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    audioService.speakGuidance('welcome');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = 60;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      _showMessage('Please enter a valid 10-digit number');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await authService.sendOtp(
        phoneNumber: phone,
        onCodeSent: (vid, token) {
          setState(() {
            _loading = false;
            _step = 'otp';
            _verificationId = vid;
          });
          _startResendTimer();
          _showMessage('OTP has been sent successfully');
          audioService.speakGuidance('otp');
        },
        onVerificationFailed: (e) {
          setState(() => _loading = false);
          _showMessage('Verification failed: ${e.message}');
          audioService.confirmAction('error', message: 'Verification failed');
        },
        onVerificationCompleted: (credential) async {
          setState(() => _loading = false);
          _showMessage('Phone number verified automatically');
          widget.onLogin();
        },
      );
    } catch (e) {
      setState(() => _loading = false);
      _showMessage('Error: $e');
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      _showMessage('Please enter 6-digit OTP');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await authService.verifyOtp(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );
      
      setState(() => _loading = false);
      _showMessage('Login successful');
      audioService.confirmAction('success', message: 'Welcome to Crop AId');
      widget.onLogin();
    } catch (e) {
      setState(() => _loading = false);
      _showMessage('Invalid OTP. Please try again.');
      audioService.confirmAction('error', message: 'Invalid code');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Branding Side
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
            ),
            padding: const EdgeInsets.all(80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CROP AID',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'A farmer-first AI platform for healthier crops and better yields.',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                _buildValueProp(LucideIcons.scan, 'Advanced AI Diagnostics'),
                const SizedBox(height: 16),
                _buildValueProp(LucideIcons.messageCircle, 'Expert Support Chat'),
                const SizedBox(height: 16),
                _buildValueProp(LucideIcons.history, 'Full Diagnosis History'),
              ],
            ),
          ),
        ),

        // Form Side
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.background,
            child: Center(
              child: _buildLoginCard(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueProp(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 24),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        Container(
          height: 320,
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  const Icon(LucideIcons.leaf, size: 60, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'CROP AID',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildLoginCard(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppColors.mediumShadow,
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your details to continue',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),

          // Phone Number Step
          if (_step == 'phone') ...[
            _buildInputField(
              controller: _phoneController,
              hint: 'Mobile Number',
              icon: LucideIcons.phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            const SizedBox(height: 32),
            _buildPrimaryButton(
              onPressed: _loading ? null : _sendOtp,
              text: _loading ? 'SENDING...' : 'SEND OTP',
            ),
          ],

          // OTP Step
          if (_step == 'otp') ...[
            _buildInputField(
              controller: _otpController,
              hint: 'Enter 6-digit OTP',
              icon: LucideIcons.lock,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: _resendSeconds > 0
                  ? Text(
                      'Resend in ${_resendSeconds}s',
                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    )
                  : TextButton(
                      onPressed: _loading ? null : _sendOtp,
                      child: const Text('RESEND OTP', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
            ),
            const SizedBox(height: 24),
            _buildPrimaryButton(
              onPressed: _loading ? null : _verifyOtp,
              text: _loading ? 'VERIFYING...' : 'LOGIN',
            ),
          ],

          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: widget.onSkip,
              child: const Text(
                'SKIP FOR NOW →',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    List<String>? autofillHints,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        autofillHints: autofillHints,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 1),
        onChanged: (value) {
          if (keyboardType == TextInputType.phone) {
             final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
             if (cleaned != value) {
               controller.text = cleaned;
               controller.selection = TextSelection.fromPosition(TextPosition(offset: cleaned.length));
             }
          }
        },
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          hintStyle: const TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w500, letterSpacing: 0),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({required VoidCallback? onPressed, required String text}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      ),
    );
  }
}

