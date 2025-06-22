import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'providers/weather_provider.dart';
import 'providers/location_provider.dart';
import 'widgets/main_app_container.dart';
import 'theme/app_theme.dart';
import 'config/api_config.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await FMTCObjectBoxBackend().initialise();

  // Register SyncFusion license if available
  if (ApiConfig.hasValidSyncfusionLicense) {
    SyncfusionLicense.registerLicense(ApiConfig.syncfusionLicenseKey);
  }

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

  // Enable skia optimizations
  // PaintingBinding.instance.imageCache.maximumSize = 100; // Control image cache size

  // Uncomment the following during development to debug raster thread issues
  // debugPrintRebuildDirtyWidgets = true;

  // Optimize Flutter rendering engine
  // These can greatly improve scrolling performance
  // Paint.enableDithering = false;

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
      ],
      child: const MyApp(),
    ),
  );
}

/// Main app entry point - optimized for performance
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoDak Weather',
      theme: AppTheme.theme,
      // Enable this line to test the new glass components
      // home: const GlassComponentsTest(),
      home: const MainAppContainer(),
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
