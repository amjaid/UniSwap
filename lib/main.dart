import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uniswap/config/routes.dart';
import 'package:uniswap/config/theme.dart';
import 'package:uniswap/firebase_options.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';
import 'package:uniswap/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: UniSwapApp()));
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    FirebaseMessaging.instance,
    FlutterLocalNotificationsPlugin(),
    FirebaseAuth.instance,
    ref.read(firestoreServiceProvider),
  );
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
    ref.read(notificationServiceProvider).initialize();
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
