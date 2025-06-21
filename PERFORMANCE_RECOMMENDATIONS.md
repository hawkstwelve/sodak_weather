# Flutter Performance Improvement Recommendations

Based on a comprehensive review of the SoDak Weather application codebase, here are detailed performance recommendations based on Flutter best practices.

## **Critical Performance Issues & Recommendations**

### **1. Excessive setState() Calls**
**Issue**: The `WeatherPage` makes multiple separate API calls (`_fetchWeatherData`, `_fetchHourlyForecast`, `_fetchNwsAlerts`, `_fetch24HourRainTotal`) that each trigger `setState()`, causing at least four separate widget tree rebuilds when one would suffice. This leads to jank and unnecessary CPU usage.

**Recommendations**:
COMPLETE- **Combine API calls**: Use `Future.wait()` to execute all weather-related API calls in parallel. Once all futures complete, call `setState()` a single time with all the new data. This is the highest impact change for the weather screen.
- **Implement proper state management**: For more complex scenarios, consider using a state management library like Provider, Riverpod, or BLoC. This centralizes state and provides more granular control over widget rebuilds.
COMPLETE- **Use `mounted` checks**: You're already doing this in some places, which is great. Ensure all asynchronous operations check if the widget is still in the tree (`mounted`) before calling `setState()` to prevent errors.

### **2. Radar Screen Performance Issues**
**Issue**: The `RadarPage` creates a new `TileLayer` widget for every single radar frame and adds them all to the `FlutterMap`. It then toggles visibility with `Opacity` or `SizedBox.shrink()`. This is extremely inefficient as `flutter_map` still has to manage a large number of layers, even if they are not visible. This is likely causing significant performance degradation and high memory usage during radar animation.

**Recommendations**:
- **Single `TileLayer` approach**: The most critical optimization is to use only *one* `TileLayer` for the radar overlay. Instead of creating a list of layers, have a single radar `TileLayer` in your widget tree. During animation, update the `urlTemplate` of this single layer within `setState()`. You can force a refresh by changing the `key` of the `TileLayer` (e.g., `key: ValueKey(_currentFrame.path)`).
- **Consolidate `setState` calls**: In the animation timer, you only need to update the `_currentFrameIndex`. The `TileLayer` in the `build` method will then use this index to construct the correct URL.
- **Reduce animation frequency**: The current animation speed is 700ms. For a weather radar, an interval of 1000ms (1 second) is often acceptable and will reduce the rebuild frequency by about 30%.

### **3. Glass Effect Performance (`BackdropFilter`)**
**Issue**: The `BackdropFilter` widget, used for the blur effect in `GlassCard`, is computationally expensive. Each `BackdropFilter` requires saving and restoring a layer of the screen, which can significantly impact frame rates, especially if multiple are on screen or used within scrolling lists.

**Recommendations**:
COMPLETE- **Strict `RepaintBoundary` usage**: You are correctly using `RepaintBoundary` around the blurred `GlassCard`. This is essential to isolate the expensive filter operation from the rest of the UI.
COMPLETE- **Limit `useBlur: true`**: Continue to be disciplined about only using `useBlur: true` for high-value, static UI elements (like the main conditions card). It appears you have already created a simulated glass effect for better performance, which is an excellent strategy.
- **Reduce shadow complexity**: The `boxShadow` on blurred cards adds to the rendering cost. For blurred cards, you might consider a less complex or even no shadow, as the blur itself provides a sense of depth.

### **4. ListView Performance**
**Issue**: Some `ListView`s in the app can be further optimized for smoother scrolling, especially the horizontal hourly forecast.

**Recommendations**:
COMPLETE- **Use `itemExtent`**: You are using this correctly in some places. Always provide a fixed `itemExtent` to `ListView.builder` when items have a constant size along the scroll axis. This allows Flutter to perform significant layout optimizations.
COMPLETE- **Implement `cacheExtent`**: For the hourly forecast `ListView`, setting a `cacheExtent` (e.g., `cacheExtent: 500`) can help pre-render items that are about to come into view, resulting in smoother scrolling.
COMPLETE- **Use `const` constructors**: Ensure that widgets returned by the `itemBuilder` are `const` if possible. This prevents them from being rebuilt unnecessarily.
COMPLETE- **Pre-build City List**: In `main_app_container.dart`, you pre-build the `cityItems` list before showing the modal. This is a great optimization to speed up the modal presentation.

### **5. API Call Optimization**
**Issue**: The app makes multiple, sometimes redundant, API calls without a caching strategy. For example, `fetchAqi` and `fetchAqiCategory` in `WeatherService` hit the same endpoint.

**Recommendations**:
COMPLETE- **Implement Caching**: Use a package like `shared_preferences` or a simple in-memory cache with a `DateTime` timestamp to store API responses for a short duration (e.g., 5-10 minutes). Before making an API call, check if a recent, valid cache entry exists.
COMPLETE- **Consolidate API methods**: The `fetchAqi` and `fetchAqiCategory` methods should be combined into a single method to avoid making two identical network requests.
- **Error Handling**: For network requests, implement a more robust error handling strategy, such as exponential backoff on retries, to avoid spamming the API when there are network issues.

### **6. Memory Management**
**Issue**: Timers and controllers can lead to memory leaks if not disposed of correctly.

**Recommendations**:
- **Timer and Controller Cleanup**: You are correctly cancelling timers (`_refreshTimer`, `_animationTimer`) and disposing of controllers (`_mapController`) in your `dispose()` methods. Continue this practice vigilantly across all stateful widgets.
- **Image Cache Management**: Flutter's default image cache is generally efficient, but for an app with many images (like radar tiles), you might need to manually clear the cache or adjust its size if memory becomes an issue. `PaintingBinding.instance.imageCache.clear()`.
- **Weak References**: For complex callback scenarios, consider using `WeakReference` to prevent strong reference cycles that can lead to memory leaks.

### **7. Widget Tree Optimization**
**Issue**: Some widgets have deep trees and could be rebuilt more often than necessary.

**Recommendations**:
- **Extract `const` Widgets**: Any widget that doesn't change should be a `const` constructor. This is the most effective way to prevent unnecessary rebuilds.
- **Refactor `build` methods**: Keep `build` methods lean. If a part of your widget tree doesn't depend on the changing state, extract it into its own `StatelessWidget` with a `const` constructor. This prevents it from rebuilding when the parent's `setState` is called.
- **Use `Consumer` or `Selector` (with State Management)**: If you adopt a state management library like Provider, use `Consumer` or `Selector` to rebuild only the specific widgets that depend on a piece of state, rather than the entire page.

### **8. Asset and Image Optimization**
**Issue**: The app uses many PNG assets for weather icons.

**Recommendations**:
COMPLETE- **Image Compression**: Run all your PNG assets through a compression tool like `tinypng.com` to reduce their file size without sacrificing quality.
COMPLETE- **Consider SVG or Icon Fonts**: For simple icons, using an icon font or SVG assets (with `flutter_svg`) can be more memory-efficient and scalable than raster images.
- **Precache Critical Images**: For images that are critical to the user experience (like the main weather icons), you can use `precacheImage` to load them into the cache ahead of time, preventing a flicker on the first load.

---

## **Actionable Code Examples**

### **1. Consolidating API calls in `weather_screen.dart`**

```dart
// In _WeatherPageState

Future<void> _fetchAllWeatherData() async {
  if (!mounted) return;
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // Fetch all data in parallel
    final results = await Future.wait([
      _weatherService.getCurrentWeather(city: _selectedCity),
      _weatherService.getHourlyForecast(city: _selectedCity),
      _weatherService.fetchAqiCategory(
        latitude: _selectedCity.latitude,
        longitude: _selectedCity.longitude,
      ),
      _weatherService.fetch24HourPrecipitationTotal(
        latitude: _selectedCity.latitude,
        longitude: _selectedCity.longitude,
      ),
      NwsAlertService.fetchAlertsForCity(_selectedCity),
    ]);

    // Process results and update state once
    if (mounted) {
      final rawWeatherData = results[0] as Map<String, dynamic>;
      final hourlyData = results[1] as List<HourlyForecast>;
      final aqiResult = results[2] as Map<String, String?>?;
      final rainTotals = results[3] as Map<String, double>;
      final alertCollection = results[4] as NwsAlertCollection?;

      final forecastPeriods = _weatherService.extractForecast(rawWeatherData)
          .map((data) => ForecastPeriod.fromJson(data)).toList();
      final currentConditionsData = _weatherService.extractCurrentConditions(rawWeatherData);
      final currentConditions = currentConditionsData != null
          ? CurrentConditions.fromJson({
              ...currentConditionsData,
              'aqiCategory': aqiResult?['category'],
            })
          : null;

      setState(() {
        _weatherData = WeatherData(
          currentConditions: currentConditions,
          forecast: forecastPeriods,
        );
        _hourlyForecast = hourlyData;
        _aqiCategory = aqiResult?['category'];
        _rain24hInches = rainTotals['inches'];
        _nwsAlerts = alertCollection?.features ?? [];
        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
}
```

### **2. Optimizing `radar_screen.dart`**

```dart
// In _RadarPageState

// State variable to hold the current template
String? _currentTileUrlTemplate;

// In _updateCurrentRadarLayer()
void _updateCurrentRadarLayer() {
  if (_rainviewerHost == null || _pastRadarFrames.isEmpty) return;

  final frame = _pastRadarFrames[_currentFrameIndex];
  final tileUrlTemplate = '$_rainviewerHost${frame.path}/256/{z}/{x}/{y}/4/1_1.png';

  // Just update the state variable
  setState(() {
    _currentTileUrlTemplate = tileUrlTemplate;
  });
}

// In build() method
// ...
children: [
  TileLayer(
    urlTemplate: baseMapUrl,
    // ...
  ),
  // Only one TileLayer for the radar
  if (_currentTileUrlTemplate != null)
    TileLayer(
      key: ValueKey(_currentTileUrlTemplate), // Force rebuild on change
      urlTemplate: _currentTileUrlTemplate!,
      tileProvider: FMTCTileProvider.allStores(...),
      tileSize: 256,
      tileBuilder: (context, tileWidget, tile) {
        return Opacity(
          opacity: _radarOpacity,
          child: tileWidget,
        );
      },
    ),
],
// ...
```