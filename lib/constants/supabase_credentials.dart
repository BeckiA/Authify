import 'package:flutter_dotenv/flutter_dotenv.dart';

String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

/// Gets the Supabase OAuth callback URL
/// This is the redirect URI that should be registered in OAuth providers
String get supabaseCallbackUrl {
  final url = supabaseUrl;
  if (url.isEmpty) return '';
  // Remove trailing slash if present
  final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  return '$cleanUrl/auth/v1/callback';
}

/// Gets the deep link redirect URL for the app
String get appDeepLink => 'authify://auth';
