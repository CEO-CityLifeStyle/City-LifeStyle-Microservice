// Flutter imports
import 'package:flutter/material.dart';

// Third-party package imports
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Local imports - config and utils
import 'config/api_config.dart';
import 'firebase_options.dart';
import 'utils/logger.dart';

// Local imports - providers
import 'providers/auth_provider.dart';
import 'providers/place_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';

// Local imports - services
import 'services/analytics_service.dart';
import 'services/place_service.dart';

// Local imports - screens
import 'screens/auth/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

// Local imports - theme
import 'theme/app_theme.dart';

final _logger = getLogger('main');

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static FirebaseAnalytics? analytics;
  static FirebaseAnalyticsObserver? analyticsObserver;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(),
          ),
          ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
            create: (_) => ProfileProvider(null, null),
            update: (_, auth, previousProfile) => ProfileProvider(
              auth.token,
              previousProfile?.profile,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => PlaceProvider(PlaceService()),
          ),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => MaterialApp(
            title: 'City Lifestyle',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/login': (context) => const AuthScreen(),
            },
            navigatorObservers: [
              if (analyticsObserver != null) analyticsObserver!,
            ],
          ),
        ),
      );
}

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    MyApp.analytics = FirebaseAnalytics.instance;
    MyApp.analyticsObserver = FirebaseAnalyticsObserver(
      analytics: MyApp.analytics!,
      nameExtractor: (settings) => settings.name ?? '<unnamed>',
    );
    _logger.info('Firebase initialized successfully');
  } catch (e, stackTrace) {
    _logger.warning('Failed to initialize Firebase', e, stackTrace);
    // Firebase is optional, continue without it
  }
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase (optional)
    await initializeFirebase();
    
    // Load environment variables
    await dotenv.load(fileName: '.env');
    
    // Initialize services
    await SharedPreferences.getInstance();
    await ApiConfig.initialize();
    await AnalyticsService().initialize();
    
    _logger.info('Application initialized successfully');
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    _logger.severe('Failed to initialize application', e, stackTrace);
    rethrow;
  }
}
