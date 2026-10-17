import 'package:flutter/material.dart';

import '../ui/intelligence_theme.dart';

class PlatformShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const PlatformShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IntelligenceTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding =
                      constraints.maxWidth >= 1100 ? 18.0 : 12.0;

                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      18,
                    ),
                    children: [
                      for (final child in children)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: child,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      height: 58,
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: IntelligenceTheme.hudPanel(
        accent: IntelligenceTheme.cyan,
        strongGlow: true,
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .025),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .08),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white60,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: IntelligenceTheme.cyan.withValues(alpha: .08),
              border: Border.all(
                color: IntelligenceTheme.cyan.withValues(alpha: .62),
              ),
              boxShadow: [
                BoxShadow(
                  color: IntelligenceTheme.cyan.withValues(alpha: .22),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: IntelligenceTheme.cyan,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: IntelligenceTheme.pageTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: IntelligenceTheme.pageSubtitle,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: IntelligenceTheme.green.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: IntelligenceTheme.green.withValues(alpha: .28),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 6,
                  color: IntelligenceTheme.green,
                ),
                SizedBox(width: 5),
                Text(
                  '999 SYSTEM',
                  style: TextStyle(
                    color: IntelligenceTheme.green,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlatformToolTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? accent;

  const PlatformToolTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? IntelligenceTheme.cyan;
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: color.withValues(alpha: .05),
        splashColor: color.withValues(alpha: .10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          decoration: IntelligenceTheme.hudPanel(
            accent: color,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: color.withValues(alpha: .36),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: .10),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: IntelligenceTheme.cardTitle,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: IntelligenceTheme.cardDescription,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    enabled ? Icons.arrow_forward_ios : Icons.circle_outlined,
                    size: enabled ? 12 : 8,
                    color:
                        enabled ? color.withValues(alpha: .78) : Colors.white24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    enabled ? 'OPEN' : 'VIEW',
                    style: TextStyle(
                      color: enabled
                          ? color.withValues(alpha: .76)
                          : Colors.white24,
                      fontSize: 6.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
