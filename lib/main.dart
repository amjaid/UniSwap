import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/config/routes.dart';
import 'package:uniswap/config/theme.dart';
import 'package:uniswap/services/django_notification_service.dart';
import 'package:uniswap/services/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: UniSwapApp()));
}

final notificationServiceProvider = Provider<DjangoNotificationService>((ref) {
  return ref.read(djangoNotificationServiceProvider);
});

class UniSwapApp extends ConsumerStatefulWidget {
  const UniSwapApp({super.key});

  @override
  ConsumerState<UniSwapApp> createState() => _UniSwapAppState();
}

class _UniSwapAppState extends ConsumerState<UniSwapApp> {
  @override
  void initState() {
    super.initState();
    // Start polling for notifications when app launches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).startPolling();
    });
  }

  @override
  void dispose() {
    ref.read(notificationServiceProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'UniSwap',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
