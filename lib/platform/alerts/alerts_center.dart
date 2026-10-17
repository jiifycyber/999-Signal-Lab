import 'package:flutter/material.dart';
import '../platform_shell.dart';

class AlertsCenter extends StatelessWidget {
  const AlertsCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlatformShell(
      title: 'Alerts',
      subtitle: 'Trading and system notifications',
      icon: Icons.notifications_active,
      children: [
        PlatformToolTile(
          title: 'Signal Alerts',
          description: 'BUY and SELL opportunity notifications.',
          icon: Icons.campaign,
        ),
        PlatformToolTile(
          title: 'High Confidence Alerts',
          description: 'Prioritize strongest scanner opportunities.',
          icon: Icons.stars,
        ),
        PlatformToolTile(
          title: 'Sound Alerts',
          description: 'Configure scanner audio notifications.',
          icon: Icons.volume_up,
        ),
        PlatformToolTile(
          title: 'Entry Countdown',
          description: 'Countdown alerts before signal entry.',
          icon: Icons.timer,
        ),
        PlatformToolTile(
          title: 'Connection Alerts',
          description: 'Bridge and market feed health warnings.',
          icon: Icons.wifi,
        ),
        PlatformToolTile(
          title: 'Risk Alerts',
          description: 'Loss streak and account protection warnings.',
          icon: Icons.warning_amber,
        ),
      ],
    );
  }
}
