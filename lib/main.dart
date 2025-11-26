import 'package:authify/bindings/auth_binding.dart';
import 'package:authify/constants/supabase_credentials.dart';
import 'package:authify/screens/signup_screen.dart';
import 'package:authify/screens/login_screen.dart';
import 'package:authify/screens/home_screen.dart';
import 'package:authify/screens/verify_email_screen.dart';
import 'package:authify/screens/forgot_password_screen.dart';
import 'package:authify/screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
  }

  runApp(const MyApp());

  // Handle deep links for auth callbacks
  _handleDeepLinks();
}

Future<void> _handleDeepLinks() async {
  final appLinks = AppLinks();

  // Handle initial link if app was opened via deep link
  appLinks.getInitialLink().then((uri) {
    if (uri != null) {
      _processAuthLink(uri.toString());
    }
  });

  // Listen for deep links while app is running
  appLinks.uriLinkStream.listen((uri) {
    _processAuthLink(uri.toString());
  });
}

Future<void> _processAuthLink(String link) async {
  final uri = Uri.parse(link);
  final code = uri.queryParameters['code'];
  final type = uri.queryParameters['type'];

  if (code == null) {
    // No code in the link, nothing to process
    return;
  }

  print('📧 Received auth code: $code (type: $type)');

  try {
    final supabase = Supabase.instance.client;

    // Handle password reset links (recovery type or null type)
    // Password reset doesn't use PKCE, so we use exchangeCodeForSession
    if (type == 'recovery' || type == 'reset') {
      try {
        // For password reset, use exchangeCodeForSession which doesn't require PKCE
        // This processes the code and creates a session
        await supabase.auth.exchangeCodeForSession(code);

        // Password reset link processed successfully
        Get.offAllNamed('/reset-password');
        return;
      } catch (e) {
        // If exchangeCodeForSession fails, it might be a stale link
        // Check if there's already a session (link might have been processed)
        final currentUser = supabase.auth.currentUser;
        if (currentUser != null) {
          // Session exists, navigate to reset password screen
          Get.offAllNamed('/reset-password');
          return;
        }

        // If it's a stale link with no session, silently ignore it
        // Don't show error to user as this is likely from a previous session
        print('⚠️ Stale password reset link detected, ignoring: $e');
        return;
      }
    } else {
      // Handle OAuth callbacks and email verification links (both use PKCE)
      // OAuth callbacks: type will be null or not 'recovery'/'reset'
      // Email verification: type will be 'signup' or similar
      try {
        final sessionResponse = await supabase.auth.getSessionFromUrl(
          Uri.parse(link),
        );

        final user = sessionResponse.session.user;

        // For OAuth sign-ins, users are automatically verified
        // For email verification, check if verified
        if (user.emailConfirmedAt != null || type == null) {
          // OAuth sign-in or verified email - navigate to home
          Get.offAllNamed('/home');
          Get.snackbar(
            'Success',
            'Signed in successfully!',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        } else {
          // Email not verified yet
          Get.offAllNamed('/verify-email');
        }
      } catch (e) {
        // If getSessionFromUrl fails, it's likely a stale link
        // Check if user is already signed in
        final currentUser = supabase.auth.currentUser;
        if (currentUser != null) {
          // User is already signed in, navigate to home
          Get.offAllNamed('/home');
          return;
        }

        // Stale link, silently ignore
        print('⚠️ Stale auth link detected, ignoring: $e');
        return;
      }
    }
  } catch (e) {
    // Catch any other unexpected errors
    print('❌ Unexpected error processing auth link: $e');
    // Silently ignore to avoid showing errors for stale links
  }
}

String decideInitialRoute() {
  final user = Supabase.instance.client.auth.currentUser;

  if (user != null) {
    if (user.emailConfirmedAt == null) {
      return '/verify-email';
    }
    return '/home';
  }
  return '/login';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Authify',
      initialBinding: AuthBinding(),
      debugShowCheckedModeBanner: false,
      initialRoute: decideInitialRoute(),
      getPages: [
        GetPage(name: '/signup', page: () => const SignupScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(
          name: '/forgot-password',
          page: () => const ForgotPasswordScreen(),
        ),
        GetPage(
          name: '/reset-password',
          page: () => const ResetPasswordScreen(),
        ),
        GetPage(name: '/verify-email', page: () => const VerifyEmailScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
      ],
    );
  }
}
