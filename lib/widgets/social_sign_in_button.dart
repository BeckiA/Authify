import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../constants/app_colors.dart';

enum SocialProvider {
  google,
  facebook,
}

class SocialSignInButton extends StatelessWidget {
  final SocialProvider provider;
  final AuthController? authController;

  const SocialSignInButton({
    super.key,
    required this.provider,
    this.authController,
  });

  String get _providerName {
    switch (provider) {
      case SocialProvider.google:
        return 'Google';
      case SocialProvider.facebook:
        return 'Facebook';
    }
  }

  String get _logoPath {
    switch (provider) {
      case SocialProvider.google:
        return 'assets/logos/google_logo.png';
      case SocialProvider.facebook:
        return 'assets/logos/facebook_logo.png';
    }
  }

  Color get _buttonColor {
    switch (provider) {
      case SocialProvider.google:
        return Colors.white;
      case SocialProvider.facebook:
        return const Color(0xFF1877F2); // Facebook blue
    }
  }

  Color get _textColor {
    switch (provider) {
      case SocialProvider.google:
        return AppColors.textPrimary;
      case SocialProvider.facebook:
        return Colors.white;
    }
  }

  Future<void> _handleSignIn() async {
    final controller = authController ?? Get.find<AuthController>();
    
    switch (provider) {
      case SocialProvider.google:
        await controller.signInWithGoogle();
        break;
      case SocialProvider.facebook:
        await controller.signInWithFacebook();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = authController ?? Get.find<AuthController>();
      final isLoading = controller.isLoading.value;

      return OutlinedButton(
        onPressed: isLoading ? null : _handleSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: _buttonColor,
          foregroundColor: _textColor,
          disabledBackgroundColor: AppColors.buttonDisabled,
          side: BorderSide(
            color: provider == SocialProvider.google
                ? AppColors.border
                : Colors.transparent,
            width: 1,
          ),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    _logoPath,
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image fails to load
                      return Icon(
                        provider == SocialProvider.google
                            ? Icons.g_mobiledata
                            : Icons.facebook,
                        size: 24,
                        color: _textColor,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with $_providerName',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
      );
    });
  }
}

