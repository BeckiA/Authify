import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../constants/app_colors.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  String? _displayEmail;
  bool _isLoadingEmail = true;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final AuthController authController = Get.find();

    // Try to get email from controller
    String? email = authController.currentUserEmail;

    // If not available, try to fetch it
    if (email == null || email.isEmpty) {
      email = await authController.fetchUserEmail();
    }

    setState(() {
      _displayEmail = email ?? 'No email found';
      _isLoadingEmail = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Your Email"),
        backgroundColor: AppColors.buttonPrimary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 80, color: AppColors.primary),
            const SizedBox(height: 30),
            Text(
              "A verification link has been sent to:",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            _isLoadingEmail
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(),
                )
                : Text(
                  _displayEmail ?? 'No email found',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            const SizedBox(height: 10),
            const Text(
              "Please check your inbox and click the verification link.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Obx(
              () => ElevatedButton(
                onPressed:
                    authController.isLoading.value
                        ? null
                        : () => authController.verifyEmailAndNavigate(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.buttonDisabled,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child:
                    authController.isLoading.value
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          "I have verified my email",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => TextButton(
                onPressed:
                    authController.isLoading.value
                        ? null
                        : () => authController.resendVerificationEmail(),
                child: const Text("Resend Verification Email"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
