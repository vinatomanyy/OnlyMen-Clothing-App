import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'state/shared_prefs_provider.dart';
import 'utils/supabase_config.dart';
import 'app.dart';

const _debugLaunchChannel = MethodChannel('com.yourname.onlymen/debug_launch');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();

  if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
    final forceOnboarding =
        await _debugLaunchChannel.invokeMethod<bool>('shouldForceOnboarding') ??
            false;
    if (forceOnboarding) {
      await prefs.setBool('onboarding_complete', false);
    }
  }

  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const OnlyMenApp(),
  ));
}
