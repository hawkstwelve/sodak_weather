import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/weather_provider.dart';
import 'providers/location_provider.dart';
import 'providers/notification_preferences_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/drought_monitor_provider.dart';
import 'providers/soil_moisture_provider.dart';
import 'providers/weather_chat_provider.dart';
import 'widgets/main_app_container.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/backend_service.dart';
// Firebase options are intentionally not hard-coded to avoid exposing secrets in CI

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase if default platform configuration is available
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Skip Firebase initialization when configuration is not present (e.g., CI)
  }
  
  await FMTCObjectBoxBackend().initialise();

  // Set status bar to transparent so gradient shows through
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Lock orientation for better performance
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProxyProvider<LocationProvider, WeatherProvider>(
          create: (_) => WeatherProvider(),
          update: (_, locationProvider, weatherProvider) {
            weatherProvider?.setLocationProvider(locationProvider);
            return weatherProvider ?? WeatherProvider();
          },
        ),
        ChangeNotifierProvider<NotificationPreferencesProvider>(
          create: (_) {
            final provider = NotificationPreferencesProvider();
            // Load preferences (will create defaults if none exist)
            provider.loadPreferences();
            return provider;
          },
        ),
        ChangeNotifierProvider<NotificationService>(
          create: (_) {
            final service = NotificationService();
            // Initialize the service after creation
            service.initialize();
            return service;
          },
        ),
        Provider<BackendService>(
          create: (_) => BackendService(),
        ),
        ChangeNotifierProvider<OnboardingProvider>(
          create: (_) => OnboardingProvider(),
        ),
        ChangeNotifierProvider<DroughtMonitorProvider>(
          create: (_) => DroughtMonitorProvider(),
        ),
        ChangeNotifierProvider<SoilMoistureProvider>(
          create: (_) => SoilMoistureProvider(),
        ),
        ChangeNotifierProvider<WeatherChatProvider>(
          create: (_) => WeatherChatProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// Main app entry point - optimized for performance
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Set up provider connections after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupProviderConnections();
    });
  }

  void _setupProviderConnections() {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final preferencesProvider = Provider.of<NotificationPreferencesProvider>(context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);

    // Initialize onboarding provider
    onboardingProvider.initialize();

    // Set up notification service with providers
    notificationService.setProviders(
      preferencesProvider: preferencesProvider,
      weatherProvider: weatherProvider,
      locationProvider: locationProvider,
    );

    // Initialize notification service
    notificationService.initialize();

    // Sync current location with backend for notifications
    notificationService.syncLocationWithBackend();

    // Listen for location changes
    weatherProvider.addListener(() {
      notificationService.onLocationChanged();
    });

    locationProvider.addListener(() {
      // Sync location with backend when location provider changes
      notificationService.onLocationChanged();
    });

    // Initial location sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notificationService.onLocationChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sodak Weather',
      theme: AppTheme.theme,
      home: Consumer<OnboardingProvider>(
        builder: (context, onboardingProvider, child) {
          if (onboardingProvider.isLoading) {
            // Show loading screen while checking onboarding status
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.textLight,
                ),
              ),
            );
          }
          
          // Show onboarding if not complete, otherwise show main app
          return onboardingProvider.isComplete 
              ? const MainAppContainer() 
              : const OnboardingScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
      // Routes for different screens
      routes: const {},

      // Performance settings
      themeMode: ThemeMode
          .dark, // Using dark theme helps with performance on OLED screens
      // Uncomment during development to debug rendering issues
      // showPerformanceOverlay: true,
      // checkerboardRasterCacheImages: true, // Shows which images are cached
      // checkerboardOffscreenLayers: true, // Shows saveLayer() usage

      // Use minimal platform integration for better performance
      builder: (context, child) {
        // Apply text scaling for accessibility but limit for performance
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(
              1.0,
            ), // Fixed text scale factor prevents relayout
          ),
          child: child!,
        );
      },
    );
  }
}
