import 'package:flutter/material.dart';
import '../models/nws_alert_model.dart';
import '../constants/ui_constants.dart';
import 'glass/glass_card.dart';

class NwsAlertBanner extends StatefulWidget {
  final List<NwsAlertFeature> alerts;
  const NwsAlertBanner({super.key, required this.alerts});

  @override
  State<NwsAlertBanner> createState() => _NwsAlertBannerState();
}

class _NwsAlertBannerState extends State<NwsAlertBanner> {
  // Track which alerts are expanded
  late List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = List.generate(widget.alerts.length, (_) => false);
  }



  @override
  Widget build(BuildContext context) {
    if (widget.alerts.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        ...List.generate(widget.alerts.length, (i) {
          final alert = widget.alerts[i];
          final props = alert.properties;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: UIConstants.spacingSmall),
            child: GlassCard(
              priority: GlassCardPriority.alert, // High priority for weather alerts
              enablePressEffect: true,
              borderRadius: BorderRadius.circular(UIConstants.borderRadiusStandard),
              contentPadding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusStandard), // Match glass card rounding
                onTap: () {
                  setState(() {
                    _expanded[i] = !_expanded[i];
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacingXLarge,
                    vertical: UIConstants.spacingLarge,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: UIConstants.spacingStandard),
                          Expanded(
                            child: Text(
                              props?.event ?? 'NWS Alert', // Only show main alert name
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Icon(
                            _expanded[i]
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      if (_expanded[i]) ...[
                        const SizedBox(height: UIConstants.spacingStandard),
                        if (props?.headline != null)
                          Text(
                            props!.headline!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        if (props?.description != null) ...[
                          const SizedBox(height: UIConstants.spacingMedium),
                          Text(
                            props!.description!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        if (props?.instruction != null) ...[
                          const SizedBox(height: UIConstants.spacingMedium),
                          Text(
                            props!.instruction!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (props?.expires != null) ...[
                          const SizedBox(height: UIConstants.spacingMedium),
                          Text(
                            'Expires: ${props!.expires}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
            ),
          );
        }),
      ],
    );
  }
}
