import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/sd_city.dart';
import '../services/rainviewer_api.dart';
import '../config/api_config.dart';
// import '../theme/app_theme.dart';
import '../providers/weather_provider.dart';
import '../utils/hour_utils.dart';
import '../constants/ui_constants.dart';
import '../constants/service_constants.dart';

class RadarCard extends StatefulWidget {
  final SDCity city;
  final void Function()? onTap;
  const RadarCard({required this.city, this.onTap, super.key});

  @override
  State<RadarCard> createState() => _RadarCardState();
}

class _RadarCardState extends State<RadarCard> {
  String? _host;
  String? _framePath;
  bool _loading = true;
  bool _capturingScreenshot = false;
  ui.Image? _screenshotImage;
  final GlobalKey _mapKey = GlobalKey();
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _fetchRadarFrame();
  }

  Future<void> _fetchRadarFrame() async {
    final data = await RainViewerApi.fetchRadarData();
    
    // Check if widget is still mounted before calling setState
    if (!mounted) return;
    
    if (data.host != null) {
      final host = data.host!.startsWith('//')
          ? 'https:${data.host}'
          : data.host;
      RadarFrameInfo? frame;
      if (data.past.isNotEmpty) {
        frame = data.past.last;
      } else if (data.nowcast.isNotEmpty) {
        frame = data.nowcast.last;
      }
      setState(() {
        _host = host;
        _framePath = frame?.path;
        _loading = false;
      });
    } else {
      setState(() {
        _host = null;
        _framePath = null;
        _loading = false;
      });
    }
  }

  Future<void> _attemptScreenshot() async {
    if (!mounted || _capturingScreenshot || !_mapReady) {
      return;
    }
    
    setState(() {
      _capturingScreenshot = true;
    });

    try {
      // Wait a bit more for tiles to be fully rendered
      await Future.delayed(UIConstants.delayLong);
      
      final RenderRepaintBoundary? boundary = 
          _mapKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        setState(() {
          _capturingScreenshot = false;
        });
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      
      if (mounted) {
        setState(() {
          _screenshotImage = image;
          _capturingScreenshot = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _capturingScreenshot = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(height: UIConstants.cardHeightLarge, child: Builder(builder: (context) => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)))));
    }

    // If we have a screenshot, display it as a static image
    if (_screenshotImage != null) {
      return SizedBox(
        height: UIConstants.cardHeightLarge,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(UIConstants.spacingXLarge),
          child: Stack(
            children: [
              RawImage(
                image: _screenshotImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: UIConstants.cardHeightLarge,
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (widget.onTap != null) widget.onTap!();
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show the interactive map
    // Get sunrise/sunset times from the weather provider to determine map style
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final sunrise = weatherProvider.weatherData?.sunrise;
    final sunset = weatherProvider.weatherData?.sunset;
    
    // Use sunrise/sunset times to determine if it's currently night
    final isNight = isCurrentlyNight(sunrise, sunset);
    final mapLayer = TileLayer(
      urlTemplate: isNight
          ? ApiConfig.darkTileUrl
          : ApiConfig.lightTileUrl,
      userAgentPackageName: 'com.example.sodak_weather',
      retinaMode: RetinaMode.isHighDensity(context),
    );
    final radarLayer = (_host != null && _framePath != null)
        ? Opacity(
            opacity: ServiceConstants.radarOpacity,
            child: TileLayer(
              urlTemplate: '$_host$_framePath/256/{z}/{x}/{y}/4/1_1.png',
              tileDimension: 256,
              userAgentPackageName: 'com.example.sodak_weather',
              retinaMode: RetinaMode.isHighDensity(context),
            ),
          )
        : const SizedBox.shrink();
    
    return Stack(
      children: [
        SizedBox(
          height: UIConstants.cardHeightLarge,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(UIConstants.spacingXLarge),
            child: RepaintBoundary(
              key: _mapKey,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    widget.city.latitude,
                    widget.city.longitude,
                  ),
                  initialZoom: ServiceConstants.radarInitialZoom,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none, // static
                  ),
                  onMapReady: () {
                    if (mounted) {
                      setState(() {
                        _mapReady = true;
                      });
                      // Attempt screenshot after map is ready
                      Future.delayed(UIConstants.delayMedium, _attemptScreenshot);
                    }
                  },
                ),
                children: [mapLayer, radarLayer],
              ),
            ),
          ),
        ),
        if (_capturingScreenshot)
          Positioned.fill(child: Builder(builder: (context) => Container(color: Colors.black.withValues(alpha: 0.3), child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)))))),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (widget.onTap != null) widget.onTap!();
            },
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _screenshotImage?.dispose();
    super.dispose();
  }
}
