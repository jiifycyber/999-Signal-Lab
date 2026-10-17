import 'package:flutter/material.dart';
import '../platform_shell.dart';

class MarketsCenter extends StatelessWidget {
  const MarketsCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlatformShell(
      title: 'Markets',
      subtitle: 'Live market intelligence',
      icon: Icons.candlestick_chart,
      children: [
        PlatformToolTile(
          title: 'Live Markets',
          description: 'Monitor active instruments and live prices.',
          icon: Icons.monitor_heart,
        ),
        PlatformToolTile(
          title: 'Advanced Charts',
          description: 'Interactive professional chart workspace.',
          icon: Icons.show_chart,
        ),
        PlatformToolTile(
          title: 'Forex',
          description: 'Major and supported currency pairs.',
          icon: Icons.currency_exchange,
        ),
        PlatformToolTile(
          title: 'Crypto',
          description: 'Digital asset market monitoring.',
          icon: Icons.currency_bitcoin,
        ),
        PlatformToolTile(
          title: 'Market Sessions',
          description: 'London, New York and Asian session status.',
          icon: Icons.public,
        ),
        PlatformToolTile(
          title: 'Volatility',
          description: 'Identify active and quiet markets.',
          icon: Icons.bolt,
        ),
        PlatformToolTile(
          title: 'Support & Resistance',
          description: 'Important live market structure levels.',
          icon: Icons.stacked_line_chart,
        ),
      ],
    );
  }
}
