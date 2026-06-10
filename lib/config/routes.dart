import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';
import 'package:uniswap/views/main_shell_screen.dart';
import 'package:uniswap/views/forgot_password_screen.dart';
import 'package:uniswap/views/placeholder_screens.dart';
import 'package:uniswap/views/inbox_screen.dart';
import 'package:uniswap/views/chat_screen.dart';
import 'package:uniswap/views/home_screen.dart';
import 'package:uniswap/views/explore_screen.dart';
import 'package:uniswap/views/create_listing_screen.dart';
import 'package:uniswap/views/listing_detail_screen.dart';
import 'package:uniswap/views/profile_screen.dart';
import 'package:uniswap/views/swap_detail_screen.dart';
import 'package:uniswap/views/swap_hub_screen.dart';
import 'package:uniswap/views/sign_in_screen.dart';
import 'package:uniswap/views/sign_up_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterRefreshProvider = Provider<GoRouterRefreshNotifier>((ref) {
  final notifier = GoRouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: ref.watch(goRouterRefreshProvider),
    redirect: (context, state) {
      // Show splash while auth is loading
      if (authAsync.isLoading) return null;

      final location = state.uri.path;
      final userData = authAsync.valueOrNull;
      final isLoggedIn = userData != null;
      final isSigningIn = location == '/sign-in' || location == '/sign-up';

      if (location == '/') {
        return isLoggedIn ? '/home' : '/sign-in';
      }

      if (isLoggedIn && isSigningIn) return '/home';
      if (!isLoggedIn && _requiresAuth(location)) return '/sign-in';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        name: 'signIn',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        name: 'signUp',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/explore',
            name: 'explore',
            builder: (context, state) => const ExploreScreen(),
          ),
          GoRoute(
            path: '/swap-hub',
            name: 'swapHub',
            builder: (context, state) => const SwapHubScreen(),
          ),
          GoRoute(
            path: '/inbox',
            name: 'inbox',
            builder: (context, state) => const InboxScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/swap-hub/:swapId',
        name: 'swapDetail',
        builder: (context, state) => SwapDetailScreen(
          swapId: state.pathParameters['swapId']!,
        ),
      ),
      GoRoute(
        path: '/chat/:swapId',
        name: 'chat',
        builder: (context, state) => ChatScreen(
          swapId: state.pathParameters['swapId']!,
        ),
      ),
      GoRoute(
        path: '/create-listing',
        name: 'createListing',
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/listing/:listingId',
        name: 'listingDetail',
        builder: (context, state) => ListingDetailScreen(
          listingId: state.pathParameters['listingId']!,
        ),
      ),
      GoRoute(
        path: '/saved',
        name: 'saved',
        builder: (context, state) => const SavedListingsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        name: 'publicProfile',
        builder: (context, state) => PublicProfileScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: '/report/:targetType/:targetId',
        name: 'report',
        builder: (context, state) => ReportScreen(
          targetType: state.pathParameters['targetType']!,
          targetId: state.pathParameters['targetId']!,
        ),
      ),
    ],
  );
});

bool _requiresAuth(String location) {
  const protectedPaths = [
    '/home',
    '/explore',
    '/swap-hub',
    '/inbox',
    '/profile',
    '/create-listing',
    '/chat',
    '/listing',
    '/saved',
    '/settings',
    '/report',
  ];
  return protectedPaths.any((path) => location.startsWith(path));
}

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this.ref) {
    _subscription = ref.listen<AsyncValue<Map<String, dynamic>?>>(
      authStateProvider,
      (_, __) {
        notifyListeners();
      },
    );
  }

  final Ref ref;
  late final ProviderSubscription<AsyncValue<Map<String, dynamic>?>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
