import 'package:flutter/material.dart';

class IntelligenceTheme {
  static const Color bg = Color(0xFF01050D);
  static const Color panel = Color(0xFF04101C);
  static const Color panel2 = Color(0xFF071B2C);

  static const Color cyan = Color(0xFF00E5FF);
  static const Color green = Color(0xFF27FF88);
  static const Color red = Color(0xFFFF4057);
  static const Color amber = Color(0xFFFFD23F);
  static const Color purple = Color(0xFF9A5CFF);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white60;
  static const Color textMuted = Colors.white38;

  static BoxDecoration hudPanel({
    Color? accent,
    double radius = 8,
    bool strongGlow = false,
  }) {
    final color = accent ?? cyan;

    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF071828),
          Color(0xFF03101C),
          Color(0xFF020A13),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: color.withValues(alpha: .55),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(
            alpha: strongGlow ? .22 : .10,
          ),
          blurRadius: strongGlow ? 18 : 10,
          spreadRadius: strongGlow ? 1 : 0,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: .42),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration softPanel({
    Color? accent,
    double radius = 7,
  }) {
    final color = accent ?? cyan;

    return BoxDecoration(
      color: panel2,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: color.withValues(alpha: .22),
      ),
    );
  }

  static TextStyle get pageTitle => const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w900,
        letterSpacing: .7,
      );

  static TextStyle get pageSubtitle => const TextStyle(
        color: cyan,
        fontSize: 7,
        fontWeight: FontWeight.w800,
        letterSpacing: .8,
      );

  static TextStyle get sectionTitle => const TextStyle(
        color: cyan,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      );

  static TextStyle get cardTitle => const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      );

  static TextStyle get cardDescription => const TextStyle(
        color: Colors.white54,
        fontSize: 8.5,
        height: 1.35,
      );
}

class IntelligenceSectionTitle extends StatelessWidget {
  final String title;
  final Color? color;

  const IntelligenceSectionTitle(
    this.title, {
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? IntelligenceTheme.cyan;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .45),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            title,
            style: IntelligenceTheme.sectionTitle.copyWith(
              color: accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: accent.withValues(alpha: .14),
            ),
          ),
        ],
      ),
    );
  }
}
