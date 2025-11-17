import 'dart:io';

/// Test network connectivity
Future<bool> checkInternetConnectivity() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('✅ Internet is connected');
      return true;
    }
  } on SocketException catch (_) {
    print('❌ No internet connection');
    return false;
  }
  return false;
}

/// Test Supabase URL connectivity
Future<bool> checkSupabaseConnectivity() async {
  try {
    final result = await InternetAddress.lookup(
      'vjcecrngkucgqydomqnz.supabase.co',
    );
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('✅ Supabase URL is reachable');
      return true;
    }
  } on SocketException catch (e) {
    print('❌ Cannot reach Supabase: $e');
    return false;
  }
  return false;
}
