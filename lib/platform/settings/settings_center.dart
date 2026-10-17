import 'package:flutter/material.dart';
import '../platform_shell.dart';

class SettingsCenter extends StatelessWidget {
  const SettingsCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlatformShell(
      title: 'Settings',
      subtitle: '999 Signal Intelligence Pro configuration',
      icon: Icons.settings,
      children: [
        PlatformToolTile(
          title: 'Account',
          description: 'User and subscription settings.',
          icon: Icons.person,
        ),
        PlatformToolTile(
          title: 'Security',
          description: 'Face ID, login and device security.',
          icon: Icons.security,
        ),
        PlatformToolTile(
          title: 'Scanner Preferences',
          description: 'Configure scanner behavior and defaults.',
          icon: Icons.tune,
        ),
        PlatformToolTile(
          title: 'Market Feed',
          description: 'Market data and feed configuration.',
          icon: Icons.stream,
        ),
        PlatformToolTile(
          title: 'Bridge',
          description: 'View bridge status and connection information.',
          icon: Icons.hub,
        ),
        PlatformToolTile(
          title: 'Notifications',
          description: 'Configure alert behavior.',
          icon: Icons.notifications,
        ),
        PlatformToolTile(
          title: 'Appearance',
          description: 'Interface preferences.',
          icon: Icons.palette,
        ),
      ],
    );
  }
}
