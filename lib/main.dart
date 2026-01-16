import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quote_vault/data/models/quote.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/sign_up_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/favorites_screen.dart';
import 'ui/screens/collections_screen.dart';
import 'ui/screens/collection_detail_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/explore_screen.dart';
import 'ui/screens/quote_detail_screen.dart';
import 'ui/screens/forgot_password_screen.dart';
import 'ui/screens/update_password_screen.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/notification_service.dart';
import 'data/providers/settings_provider.dart';
import 'data/services/background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'ui/screens/home_screen.dart'; // Will create this later
// import 'ui/screens/login_screen.dart'; // Will create this later

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // Note: This will fail if constants are not set.
  // Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Settings
  final prefs = await SharedPreferences.getInstance();

  // Riverpod Container
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Notifications
  final notificationService = container.read(notificationServiceProvider);
  await notificationService.init();

  // Initialize Background Service for Widget
  await BackgroundService.initialize();
  // Schedule daily notification immediately for simplicity (in real app check preferences)
  // We can also let SettingsNotifier handle this on load, but init is safe.
  // We used to call schedule here, but now SettingsNotifier does it on load if enabled.

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const QuoteVaultApp(),
    ),
  );

  // Listen for password recovery
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    if (event == AuthChangeEvent.passwordRecovery) {
      _router.go('/update-password');
    }
  });
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/update-password',
      builder: (context, state) => const UpdatePasswordScreen(),
    ),
    GoRoute(
      path: '/explore',
      builder: (context, state) {
        final category = state.uri.queryParameters['category'];
        final author = state.uri.queryParameters['author'];
        final query = state.uri.queryParameters['query'];
        return ExploreScreen(
          initialCategory: category,
          initialAuthor: author,
          initialQuery: query,
        );
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/collections',
      builder: (context, state) => const CollectionsScreen(),
    ),
    GoRoute(
      path: '/collection/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final name = state.extra as String? ?? 'Collection';
        return CollectionDetailScreen(collectionId: id, collectionName: name);
      },
    ),
    GoRoute(
      path: '/quote/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        final quote = state.extra as Quote?;
        return QuoteDetailScreen(quoteId: id, quote: quote);
      },
    ),
  ],
  redirect: (context, state) {
    // We need to read the provider to check auth status.
    // Ideally we listen to a redirect notifier, but for simple MVP:
    final container = ProviderScope.containerOf(context);
    final user = container.read(authRepositoryProvider).currentUser;

    final loggingIn =
        state.uri.path == '/login' ||
        state.uri.path == '/signup' ||
        state.uri.path == '/forgot-password' ||
        state.uri.path == '/update-password';

    if (user == null && !loggingIn) return '/login';
    if (user != null && loggingIn && state.uri.path != '/update-password')
      return '/';

    return null;
  },
);

class QuoteVaultApp extends ConsumerWidget {
  const QuoteVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      routerConfig: _router,
    );
  }
}
