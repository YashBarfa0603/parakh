import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'ashoka_emblem.dart';

class ParakhLogo extends StatelessWidget {
  final double size;
  final bool isVertical;
  final bool showSubtitle;
  final bool isDark;

  const ParakhLogo({
    super.key,
    this.size = 48,
    this.isVertical = false,
    this.showSubtitle = true,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : ParakhColors.accent;
    final subColor = isDark ? Colors.white70 : ParakhColors.textSecondary;

    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AshokaEmblem(
            size: size,
            color: isDark ? ParakhColors.accentGold : ParakhColors.accent,
          ),
          SizedBox(height: size * 0.2),
          Text(
            'PARAKH',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: size * 0.48,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: titleColor,
            ),
          ),
          if (showSubtitle) ...[
            const SizedBox(height: 4),
            Text(
              'Digital Inspection for a Fairer Marketplace',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: size * 0.22,
                fontWeight: FontWeight.w500,
                color: subColor,
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AshokaEmblem(
          size: size,
          color: isDark ? ParakhColors.accentGold : ParakhColors.accent,
        ),
        SizedBox(width: size * 0.3),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PARAKH',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: size * 0.44,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: titleColor,
              ),
            ),
            if (showSubtitle) ...[
              const SizedBox(height: 2),
              Text(
                'Digital Inspection for a Fairer Marketplace',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: size * 0.20,
                  fontWeight: FontWeight.w500,
                  color: subColor,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
