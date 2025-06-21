import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/sd_city.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../services/rainviewer_api.dart';
import '../widgets/app_drawer.dart';
import '../config/api_config.dart';

class RadarPage extends StatefulWidget {
  final String? weatherCondition;
  final Widget? citySelector;
  final Function(int)? onNavigate;

  const RadarPage({
    this.weatherCondition,
    this.citySelector,
    this.onNavigate,
    super.key,
  });

  @override
  State<RadarPage> createState() => _RadarPageState();
}

class _RadarPageState extends State<RadarPage> with WidgetsBindingObserver {
  static const double _initialZoom = 8.5;
  static const double _minZoomLevel = 3.0;
  static const double _maxZoomLevel = 14.0;

  final MapController _mapController = MapController();
  late SDCity _currentCity; // Local state to hold the city from the provider
  String? _rainviewerHost;
  List<RadarFrameInfo> _pastRadarFrames = [];
  int _currentFrameIndex = 0;
  bool _isPlaying = false;
  Timer? _animationTimer;
  final Duration _animationSpeed = const Duration(milliseconds: 700);
  bool _isLoadingFrames = true;
  String? _framesErrorMessage;
  double _radarOpacity = 0.7;
  final DateFormat _frameTimeFormatter = DateFormat('MMM d, h:mm a');
  Timer? _refreshDataTimer;
  final Duration _refreshInterval = const Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize with a default city from the provider, but don't listen here.
    _currentCity = Provider.of<WeatherProvider>(context, listen: false).selectedCity;
    _initializeRadarStore();
    _loadRadarData();
    _refreshDataTimer = Timer.periodic(
      _refreshInterval,
      (_) => _loadRadarData(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final SDCity newCity = Provider.of<WeatherProvider>(context).selectedCity;
    
    // This is the core logic from the old didUpdateWidget.
    // It runs only when the city from the provider has changed.
    if (_currentCity.name != newCity.name) {
      _currentCity = newCity;
      _resetAnimationState();
      // Update map center to new city
      final newCenter = LatLng(_currentCity.latitude, _currentCity.longitude);
      _mapController.move(newCenter, _initialZoom);
      _loadRadarData();
    }
  }

  Future<void> _initializeRadarStore() async {
    try {
      await const FMTCStore('radarStore').manage.create();
    } catch (_) {
      // already exists
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRadarData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationTimer?.cancel();
    _refreshDataTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  String _formatUnixToLocal(int unixTime) => _frameTimeFormatter.format(
    DateTime.fromMillisecondsSinceEpoch(unixTime * 1000, isUtc: true).toLocal(),
  );

  void _resetAnimationState() {
    _animationTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentFrameIndex = 0;
      _isLoadingFrames = true;
      _framesErrorMessage = null;
      _pastRadarFrames = [];
    });
  }

  Future<void> _loadRadarData() async {
    setState(() {
      _isLoadingFrames = true;
      _framesErrorMessage = null;
    });

    try {
      final radarData = await RainViewerApi.fetchRadarData();
      
      if (radarData != null && radarData.host != null && radarData.past.isNotEmpty) {
        if (mounted) {
          setState(() {
            _pastRadarFrames = radarData.past;
            _rainviewerHost = radarData.host!.startsWith('//') 
                ? 'https:${radarData.host}' 
                : radarData.host;
            _isLoadingFrames = false;
            _currentFrameIndex = _pastRadarFrames.length - 1;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _framesErrorMessage = 'No radar data available';
            _isLoadingFrames = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _framesErrorMessage = 'Failed to load radar data: $e';
          _isLoadingFrames = false;
        });
      }
    }
  }

  void _playAnimation() {
    if (_isPlaying || _pastRadarFrames.isEmpty || _isLoadingFrames) return;
    
    setState(() {
      _isPlaying = true;
      if (_currentFrameIndex >= _pastRadarFrames.length - 1) {
        _currentFrameIndex = 0;
      }
    });
    
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(_animationSpeed, (timer) {
      if (!_isPlaying || !mounted || _pastRadarFrames.isEmpty) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _currentFrameIndex = (_currentFrameIndex + 1) % _pastRadarFrames.length;
      });
    });
  }

  void _pauseAnimation() {
    _animationTimer?.cancel();
    if (mounted) setState(() => _isPlaying = false);
  }

  void _onSliderChanged(double value) {
    if (_pastRadarFrames.isEmpty) return;
    
    _animationTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentFrameIndex = value.toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> gradientColors = AppTheme.getGradientForCondition(
      widget.weatherCondition,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String baseMapUrl = isDark
        ? ApiConfig.darkTileUrl
        : ApiConfig.lightTileUrl;
    final LatLng center = LatLng(_currentCity.latitude, _currentCity.longitude);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${_currentCity.name} Radar'),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.citySelector != null) widget.citySelector!,
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(
        gradientColors: gradientColors,
        selectedCity: _currentCity,
        currentScreen: 'radar',
        onWeatherTap: () {
          Navigator.pop(context);
          if (widget.onNavigate != null) {
            widget.onNavigate!(0);
          } else {
            Navigator.of(context).pop();
          }
        },
        onAfdTap: () {
          Navigator.pop(context);
          if (widget.onNavigate != null) {
            widget.onNavigate!(1);
          } else {
            Navigator.of(context).pop();
          }
        },
        onSpcOutlooksTap: () {
          Navigator.pop(context);
          if (widget.onNavigate != null) {
            widget.onNavigate!(2);
          } else {
            Navigator.of(context).pop();
          }
        },
        onRadarTap: () {
          Navigator.pop(context);
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (_isLoadingFrames)
                const Center(
                  key: ValueKey('radar_loading'),
                  child: CircularProgressIndicator(),
                )
              else if (_framesErrorMessage != null)
                Center(
                  key: const ValueKey('radar_error'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _framesErrorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: _initialZoom,
                    minZoom: _minZoomLevel,
                    maxZoom: _maxZoomLevel,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: baseMapUrl,
                      userAgentPackageName: 'com.example.sodak_weather',
                      retinaMode: RetinaMode.isHighDensity(context),
                    ),
                    if (_pastRadarFrames.isNotEmpty && _rainviewerHost != null)
                      ..._pastRadarFrames.asMap().entries.map((entry) {
                        final index = entry.key;
                        final frame = entry.value;
                        final tileUrlTemplate =
                            '$_rainviewerHost${frame.path}/256/{z}/{x}/{y}/4/1_1.png';
                        return TileLayer(
                          key: ValueKey(frame.path),
                          urlTemplate: tileUrlTemplate,
                          tileDimension: 256,
                          tileProvider: FMTCTileProvider.allStores(
                            allStoresStrategy: BrowseStoreStrategy.readUpdateCreate,
                            loadingStrategy: BrowseLoadingStrategy.cacheFirst,
                          ),
                          tileBuilder: (context, tileWidget, tile) {
                            if (index == _currentFrameIndex) {
                              return Opacity(
                                opacity: _radarOpacity,
                                child: tileWidget,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          userAgentPackageName: 'com.example.sodak_weather',
                        );
                      }).toList()
                  ],
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildControls(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    if (_isLoadingFrames || _pastRadarFrames.isEmpty) {
      return const SizedBox.shrink();
    }

    final frame = _pastRadarFrames[_currentFrameIndex];
    final timeStr = _formatUnixToLocal(frame.time);

    return Card(
      color: Colors.black.withValues(alpha: 0.7),
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: _isPlaying ? _pauseAnimation : _playAnimation,
                ),
                Expanded(
                  child: Slider(
                    value: _currentFrameIndex.toDouble(),
                    min: 0,
                    max: (_pastRadarFrames.length - 1).toDouble(),
                    divisions: _pastRadarFrames.length > 1
                        ? _pastRadarFrames.length - 1
                        : null,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white30,
                    onChanged: _onSliderChanged,
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.opacity, color: Colors.white),
                Expanded(
                  child: Slider(
                    value: _radarOpacity,
                    min: 0.1,
                    max: 1.0,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white30,
                    onChanged: (v) => setState(() => _radarOpacity = v),
                  ),
                ),
                Text(
                  '${(_radarOpacity * 100).round()}%',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
