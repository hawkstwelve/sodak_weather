import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/weather_provider.dart';
import 'providers/location_provider.dart';
import 'providers/theme_provider.dart';
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

// Global variable to track Firebase initialization status
bool _firebaseInitialized = false;

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase if default platform configuration is available
  try {
    await Firebase.initializeApp();
    _firebaseInitialized = true;
    if (kDebugMode) {
      print('Firebase initialized successfully');
    }
  } catch (e) {
    // Skip Firebase initialization when configuration is not present (e.g., CI)
    _firebaseInitialized = false;
    if (kDebugMode) {
      print('Firebase initialization failed: $e');
    }
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
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) {
            final provider = ThemeProvider();
            provider.load();
            return provider;
          },
        ),
        ChangeNotifierProvider<WeatherProvider>(
          create: (_) => WeatherProvider(),
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
            // Initialize the service after creation, but only if Firebase is available
            if (_firebaseInitialized) {
              service.initialize();
            } else if (kDebugMode) {
              print('Skipping notification service initialization - Firebase not available');
            }
            return service;
          },
        ),
        Provider<BackendService>(
          create: (_) => BackendService(),
        ),
        ChangeNotifierProvider<OnboardingProvider>(
          create: (_) {
            final provider = OnboardingProvider();
            // Initialize the provider immediately
            provider.initialize();
            return provider;
          },
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
    // Add a small delay to ensure providers are fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _setupProviderConnections();
      });
    });
  }

  Future<void> _setupProviderConnections() async {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final preferencesProvider = Provider.of<NotificationPreferencesProvider>(context, listen: false);
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);

      // Initialize onboarding provider with timeout protection
      try {
        await onboardingProvider.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            // Continue even if onboarding initialization fails
          },
        );
      } catch (e) {
        // Continue even if onboarding initialization fails
      }

      // Set up weather provider with location provider with timeout protection
      try {
        await weatherProvider.setLocationProvider(locationProvider).timeout(
          const Duration(seconds: 5), // Reduced timeout for faster fallback
          onTimeout: () {
            // Force weather provider to be initialized even if location setup fails
            weatherProvider.forceInitialization();
          },
        );
      } catch (e) {
        // Force weather provider to be initialized even if location setup fails
        weatherProvider.forceInitialization();
      }

      // Ensure weather provider has data by forcing a fetch if needed
      if (!weatherProvider.isLoading && weatherProvider.weatherData == null) {
        try {
          await weatherProvider.fetchAllWeatherData().timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              // Continue even if weather fetch times out
            },
          );
        } catch (e) {
          // Continue even if weather fetch fails
        }
      }

      // Refresh location permissions to ensure we have the latest state
      try {
        await locationProvider.refreshPermissionStatus().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            // Continue without location permissions
          },
        );
      } catch (e) {
        // Continue without location permissions
      }

      // Set up notification service with providers
      try {
        notificationService.setProviders(
          preferencesProvider: preferencesProvider,
          weatherProvider: weatherProvider,
          locationProvider: locationProvider,
        );

        // Initialize notification service with timeout protection, but only if Firebase is available
        if (_firebaseInitialized) {
          await notificationService.initialize().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              // Continue without notification service
              if (kDebugMode) {
                print('Notification service initialization timed out');
              }
            },
          );
        } else if (kDebugMode) {
          print('Skipping notification service setup - Firebase not available');
        }
      } catch (e) {
        // Continue without notification service
        if (kDebugMode) {
          print('Error setting up notification service: $e');
        }
      }

      // Sync current location with backend for notifications (non-blocking)
      try {
        notificationService.syncLocationWithBackend();
      } catch (e) {
        // Continue without backend sync
      }

      // Listen for location changes with error protection
      weatherProvider.addListener(() {
        try {
          notificationService.onLocationChanged();
        } catch (e) {
          // Ignore listener errors
        }
      });

      locationProvider.addListener(() {
        try {
          // Sync location with backend when location provider changes
          notificationService.onLocationChanged();
        } catch (e) {
          // Ignore listener errors
        }
      });

      // Initial location sync (non-blocking)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          notificationService.onLocationChanged();
        } catch (e) {
          // Ignore initial sync errors
        }
      });

      // Auto-sun functionality removed - using single theme now
    } catch (e) {
      // Ensure weather provider is initialized even if everything else fails
      try {
        final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
        if (!weatherProvider.isInitialized) {
          weatherProvider.forceInitialization();
        }
      } catch (e2) {
        // Last resort - continue anyway
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'SoDak Weather',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildTheme(themeProvider.config),
          home: Consumer<OnboardingProvider>(
            builder: (context, onboardingProvider, child) {
              if (onboardingProvider.isLoading) {
                // Show loading screen while checking onboarding status
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                );
              }
              
              // Show onboarding if not complete, otherwise show main app
              return onboardingProvider.isComplete 
                  ? Consumer<WeatherProvider>(
                      builder: (context, weatherProvider, child) {
                        // Show loading until weather provider is properly initialized
                        if (!weatherProvider.isInitialized) {
                          // Add a timeout fallback to prevent infinite loading in release builds
                          return FutureBuilder(
                            future: Future.delayed(const Duration(seconds: 8)), // Reduced from 20 to 8 seconds
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done) {
                                // Force initialization after timeout to prevent infinite loading
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!weatherProvider.isInitialized) {
                                    weatherProvider.forceInitialization();
                                  }
                                });
                              }
                              
                              return Scaffold(
                                body: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Initializing weather data...',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      if (snapshot.connectionState == ConnectionState.done) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          'Taking longer than expected...',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        return const MainAppContainer();
                      },
                    )
                  : const OnboardingScreen();
            },
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
