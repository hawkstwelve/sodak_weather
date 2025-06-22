import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/sd_city.dart';
import '../services/rainviewer_api.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

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
    if (data != null && data.host != null) {
      final host = data.host!.startsWith('//')
          ? 'https:${data.host}'
          : data.host;
      RadarFrameInfo? frame;
      if (data.nowcast.isNotEmpty) {
        frame = data.nowcast.last;
      } else if (data.past.isNotEmpty) {
        frame = data.past.last;
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
      await Future.delayed(const Duration(milliseconds: 2000));
      
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
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(color: AppTheme.loadingIndicatorColor)),
      );
    }

    // If we have a screenshot, display it as a static image
    if (_screenshotImage != null) {
      return SizedBox(
        height: 160,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              RawImage(
                image: _screenshotImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 160,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapLayer = TileLayer(
      urlTemplate: isDark
          ? ApiConfig.darkTileUrl
          : ApiConfig.lightTileUrl,
      userAgentPackageName: 'com.example.sodak_weather',
      retinaMode: RetinaMode.isHighDensity(context),
    );
    final radarLayer = (_host != null && _framePath != null)
        ? Opacity(
            opacity: 0.7,
            child: TileLayer(
              urlTemplate: '$_host$_framePath/256/{z}/{x}/{y}/4/1_1.png',
              userAgentPackageName: 'com.example.sodak_weather',
              retinaMode: RetinaMode.isHighDensity(context),
            ),
          )
        : const SizedBox.shrink();
    
    return Stack(
      children: [
        SizedBox(
          height: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: RepaintBoundary(
              key: _mapKey,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    widget.city.latitude,
                    widget.city.longitude,
                  ),
                  initialZoom: 8.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none, // static
                  ),
                  onMapReady: () {
                    if (mounted) {
                      setState(() {
                        _mapReady = true;
                      });
                      // Attempt screenshot after map is ready
                      Future.delayed(const Duration(milliseconds: 1000), _attemptScreenshot);
                    }
                  },
                ),
                children: [mapLayer, radarLayer],
              ),
            ),
          ),
        ),
        if (_capturingScreenshot)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.loadingIndicatorColor),
              ),
            ),
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
    );
  }

  @override
  void dispose() {
    _screenshotImage?.dispose();
    super.dispose();
  }
}
