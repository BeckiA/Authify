import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  var isLoading = false.obs;

  // Store email for cases where session might not be immediately available
  String? _storedEmail;

  /// Checks if the current user's email is verified
  bool get isEmailVerified {
    final user = supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  /// Gets the current user's email
  /// Tries multiple sources: current user, stored email, or fetches from server
  String? get currentUserEmail {
    // First try to get from current user
    final user = supabase.auth.currentUser;
    if (user?.email != null) {
      return user!.email;
    }

    // Fallback to stored email
    if (_storedEmail != null) {
      return _storedEmail;
    }

    // Last resort: try to get from response user if available
    return null;
  }

  /// Handles navigation based on email verification status
  void _handleEmailVerificationNavigation(User? user) {
    if (user != null && !isEmailVerified) {
      Get.offAllNamed('/verify-email');
      Get.snackbar(
        'Email Verification Required',
        'Please verify your email to continue.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else if (user != null && isEmailVerified) {
      Get.offAllNamed('/home');
      Get.snackbar(
        'Success',
        'Logged in successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      // Store email for later use
      _storedEmail = email;

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'first_name': firstName, 'last_name': lastName},
        emailRedirectTo: 'authify://auth',
      );

      if (response.user != null) {
        // Update stored email from response if available
        if (response.user!.email != null) {
          _storedEmail = response.user!.email;
        }
        Get.offAllNamed('/verify-email');
        Get.snackbar(
          'Registration Successful',
          'Please check your email to verify your account.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on AuthException catch (e) {
      Get.snackbar('Registration Error', e.message);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      // Store email for later use
      _storedEmail = email;

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Update stored email from response if available
      if (response.user?.email != null) {
        _storedEmail = response.user!.email;
      }

      _handleEmailVerificationNavigation(response.user);
    } on AuthApiException catch (e) {
      // Handle email verification errors
      final errorMessage = e.message.toLowerCase();
      if (errorMessage.contains('email') &&
          (errorMessage.contains('verify') ||
              errorMessage.contains('confirm') ||
              errorMessage.contains('not verified'))) {
        // Check if user exists but email is not verified
        final user = supabase.auth.currentUser;
        if (user != null && !isEmailVerified) {
          Get.offAllNamed('/verify-email');
          Get.snackbar(
            'Email Not Verified',
            'Please verify your email to continue.',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.snackbar('Login Error', e.message);
        }
      } else {
        Get.snackbar('Login Error', e.message);
      }
    } on AuthException catch (e) {
      Get.snackbar('Login Error', e.message);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Resends the email verification link
  Future<void> resendVerificationEmail() async {
    try {
      isLoading.value = true;

      // Try to get email from multiple sources
      String? email = currentUserEmail;

      // If not available, try to fetch it
      if (email == null || email.isEmpty) {
        email = await fetchUserEmail();
      }

      if (email == null || email.isEmpty) {
        Get.snackbar(
          'Error',
          'No user email found. Please try logging in again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Use OtpType.signup for signup email verification
      // Note: redirectTo for resend is configured in Supabase dashboard
      await supabase.auth.resend(type: OtpType.signup, email: email);

      Get.snackbar(
        'Email Sent',
        'Verification email has been resent. Please check your inbox.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } on AuthException catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      debugPrint('Error resending verification email: $e');
      Get.snackbar(
        'Error',
        'Failed to resend email. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetches the user email from the server if not available locally
  Future<String?> fetchUserEmail() async {
    try {
      // Try to get from current user first
      final currentUser = supabase.auth.currentUser;
      if (currentUser?.email != null) {
        _storedEmail = currentUser!.email;
        return currentUser.email;
      }

      // Try to fetch from server
      final response = await supabase.auth.getUser();
      if (response.user?.email != null) {
        _storedEmail = response.user!.email;
        return response.user!.email;
      }

      // Return stored email as fallback
      return _storedEmail;
    } catch (e) {
      debugPrint('Error fetching user email: $e');
      return _storedEmail;
    }
  }

  /// Checks if the email has been verified by fetching the latest user data
  Future<bool> checkEmailVerificationStatus() async {
    try {
      // First, try to refresh the session to ensure we have the latest data
      try {
        await supabase.auth.refreshSession();
        debugPrint('Session refreshed in checkEmailVerificationStatus');
      } catch (e) {
        debugPrint('Session refresh error (may be expected): $e');
        // Continue - we'll check current user as fallback
      }

      // First check: try to get user from server (requires session)
      try {
        final response = await supabase.auth.getUser();
        final user = response.user;

        // Update stored email if we got it from the server
        if (user?.email != null) {
          _storedEmail = user!.email;
        }

        // Check if email is verified
        final isVerified = user?.emailConfirmedAt != null;

        debugPrint('Email verification check - Verified: $isVerified');
        debugPrint('User email: ${user?.email}');
        debugPrint('Email confirmed at: ${user?.emailConfirmedAt}');

        if (isVerified) {
          return true;
        }
      } catch (e) {
        debugPrint('Error getting user from server: $e');
        // Fall through to check current user
      }

      // Fallback: check current user (might have session from verification link)
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        final fallbackVerified = currentUser.emailConfirmedAt != null;
        debugPrint('Fallback check - Current user verified: $fallbackVerified');
        if (currentUser.email != null) {
          _storedEmail = currentUser.email;
        }
        return fallbackVerified;
      }

      debugPrint('No user found - cannot verify email status');
      return false;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      // Last resort: check current user
      final currentUser = supabase.auth.currentUser;
      final fallbackVerified = currentUser?.emailConfirmedAt != null;
      debugPrint('Final fallback check - Verified: $fallbackVerified');
      return fallbackVerified;
    }
  }

  /// Handles the email verification check and navigation
  Future<void> verifyEmailAndNavigate() async {
    try {
      isLoading.value = true;

      // First, try to refresh the session in case it was created after email verification
      try {
        await supabase.auth.refreshSession();
        debugPrint('Session refreshed successfully');
      } catch (e) {
        debugPrint('Session refresh attempt (may be expected): $e');
        // Continue even if refresh fails - we'll check verification status anyway
      }

      // Check if we have a current user/session after refresh
      var currentUser = supabase.auth.currentUser;

      // If no current user, try to get user from server
      if (currentUser == null) {
        try {
          final response = await supabase.auth.getUser();
          currentUser = response.user;
          debugPrint('Fetched user from server: ${currentUser?.email}');
        } catch (e) {
          debugPrint('Could not fetch user from server: $e');
        }
      }

      // Check verification status
      final isVerified = await checkEmailVerificationStatus();

      if (isVerified) {
        // If verified, check if we have a valid session
        final finalUser = supabase.auth.currentUser ?? currentUser;

        if (finalUser != null && finalUser.emailConfirmedAt != null) {
          // User is verified and we have a session - go to home
          Get.offAllNamed('/home');
          Get.snackbar(
            'Email Verified',
            'Your email has been verified successfully!',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
          return;
        }

        // Email is verified but no active session
        // Try one more time to get the user after a brief delay
        // (sometimes session takes a moment to be available after verification)
        await Future.delayed(const Duration(milliseconds: 500));

        try {
          await supabase.auth.refreshSession();
          final refreshedUser = supabase.auth.currentUser;

          if (refreshedUser != null && refreshedUser.emailConfirmedAt != null) {
            // Session is now available - go to home
            Get.offAllNamed('/home');
            Get.snackbar(
              'Email Verified',
              'Your email has been verified successfully!',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
            return;
          }
        } catch (e) {
          debugPrint('Final session refresh attempt failed: $e');
        }

        // If we still don't have a session, the user needs to sign in
        // But since verification is confirmed, redirect to login with helpful message
        Get.offAllNamed('/login');
        Get.snackbar(
          'Email Verified',
          'Your email has been verified! Please sign in to continue.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Not Verified',
          'Your email is not verified yet. Please check your inbox and click the verification link.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } on AuthException catch (e) {
      debugPrint('Auth error in verifyEmailAndNavigate: ${e.message}');

      // Try one more time to check verification status even if there's an auth error
      try {
        // Try refreshing session one more time
        try {
          await supabase.auth.refreshSession();
        } catch (refreshError) {
          debugPrint('Session refresh in error handler failed: $refreshError');
        }

        final isVerified = await checkEmailVerificationStatus();
        if (isVerified) {
          // If verified, try to go to home - user might have a session now
          final user = supabase.auth.currentUser;
          if (user != null && user.emailConfirmedAt != null) {
            Get.offAllNamed('/home');
            Get.snackbar(
              'Email Verified',
              'Your email has been verified successfully!',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
            return;
          }

          // If verified but no session, try one more refresh after delay
          await Future.delayed(const Duration(milliseconds: 500));
          try {
            await supabase.auth.refreshSession();
            final refreshedUser = supabase.auth.currentUser;
            if (refreshedUser != null &&
                refreshedUser.emailConfirmedAt != null) {
              Get.offAllNamed('/home');
              Get.snackbar(
                'Email Verified',
                'Your email has been verified successfully!',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
              return;
            }
          } catch (finalRefreshError) {
            debugPrint(
              'Final refresh in error handler failed: $finalRefreshError',
            );
          }
        }
      } catch (checkError) {
        debugPrint('Error in verification check retry: $checkError');
      }

      // If we still can't verify or don't have a session, redirect to login
      Get.snackbar(
        'Verification Check',
        'Please sign in to verify your email status.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      Get.offAllNamed('/login');
    } catch (e) {
      debugPrint('Error in verifyEmailAndNavigate: $e');
      Get.snackbar(
        'Error',
        'Failed to check verification status. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Sends a password reset email to the user
  Future<void> resetPassword({required String email}) async {
    try {
      isLoading.value = true;
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'authify://auth',
      );
      Get.snackbar(
        'Password Reset Email Sent',
        'Please check your email for password reset instructions.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } on AuthException catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Updates the user's password (used after password reset)
  Future<void> updatePassword({required String newPassword}) async {
    try {
      isLoading.value = true;
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      Get.snackbar(
        'Password Updated',
        'Your password has been successfully updated.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      // Navigate to login after successful password update
      Get.offAllNamed('/login');
    } on AuthException catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Signs out the current user from Supabase and navigates to the login screen.
  Future<void> logout() async {
    try {
      isLoading.value = true;
      await supabase.auth.signOut();
      Get.snackbar('Success', 'Logged out successfully');
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Logout Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
