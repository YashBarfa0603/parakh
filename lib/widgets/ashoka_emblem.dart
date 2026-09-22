import 'package:flutter/material.dart';
import '../core/theme.dart';

class AshokaEmblem extends StatelessWidget {
  final double size;
  final Color? color;

  const AshokaEmblem({
    super.key,
    this.size = 64,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/ashoka_stambh_transparent.png',
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/ashoka_stambh.jpg',
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            final emblemColor = color ?? ParakhColors.accent;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: Size(size, size * 1.1),
                  painter: _AshokaEmblemPainter(color: emblemColor),
                ),
                const SizedBox(height: 2),
                Text(
                  'सत्यमेव जयते',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: size * 0.16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: emblemColor,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AshokaEmblemPainter extends CustomPainter {
  final Color color;

  _AshokaEmblemPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // 1. Center Lion Head
    final centerLionHead = Path()
      ..moveTo(w * 0.38, h * 0.22)
      ..cubicTo(w * 0.38, h * 0.08, w * 0.62, h * 0.08, w * 0.62, h * 0.22)
      ..lineTo(w * 0.60, h * 0.40)
      ..lineTo(w * 0.40, h * 0.40)
      ..close();
    canvas.drawPath(centerLionHead, fillPaint);
    canvas.drawPath(centerLionHead, paint);

    // Ears
    canvas.drawCircle(Offset(w * 0.38, h * 0.14), w * 0.04, paint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.14), w * 0.04, paint);

    // Mane arcs
    final manePath = Path()
      ..moveTo(w * 0.35, h * 0.25)
      ..quadraticBezierTo(w * 0.30, h * 0.35, w * 0.38, h * 0.45)
      ..moveTo(w * 0.65, h * 0.25)
      ..quadraticBezierTo(w * 0.70, h * 0.35, w * 0.62, h * 0.45);
    canvas.drawPath(manePath, paint);

    // 2. Left Lion Profile
    final leftLion = Path()
      ..moveTo(w * 0.36, h * 0.22)
      ..cubicTo(w * 0.20, h * 0.14, w * 0.15, h * 0.28, w * 0.22, h * 0.38)
      ..lineTo(w * 0.35, h * 0.42);
    canvas.drawPath(leftLion, paint);

    // 3. Right Lion Profile
    final rightLion = Path()
      ..moveTo(w * 0.64, h * 0.22)
      ..cubicTo(w * 0.80, h * 0.14, w * 0.85, h * 0.28, w * 0.78, h * 0.38)
      ..lineTo(w * 0.65, h * 0.42);
    canvas.drawPath(rightLion, paint);

    // 4. Lion Pedestal / Abacus Upper Tier
    final abacusTop = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.46, w * 0.60, h * 0.07),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(abacusTop, fillPaint);
    canvas.drawRRect(abacusTop, paint);

    // 5. Ashoka Chakra in Center of Abacus
    final chakraCenter = Offset(w * 0.5, h * 0.63);
    final chakraRadius = w * 0.12;
    canvas.drawCircle(chakraCenter, chakraRadius, paint);
    canvas.drawCircle(chakraCenter, chakraRadius * 0.25, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;

    // 24 Spokes (simplified for clean vector scaling)
    for (int i = 0; i < 12; i++) {
      canvas.drawLine(
        chakraCenter,
        Offset(
          chakraCenter.dx + chakraRadius * 0.9 * (i.isEven ? 1 : -1) * (i < 6 ? 1 : -1),
          chakraCenter.dy + chakraRadius * 0.9 * (i < 6 ? 1 : -1),
        ),
        paint..strokeWidth = size.width * 0.015,
      );
    }
    paint.strokeWidth = size.width * 0.03;

    // Bull (left side of Chakra)
    final bullPath = Path()
      ..moveTo(w * 0.28, h * 0.66)
      ..quadraticBezierTo(w * 0.22, h * 0.58, w * 0.24, h * 0.68)
      ..lineTo(w * 0.34, h * 0.68);
    canvas.drawPath(bullPath, paint);

    // Horse (right side of Chakra)
    final horsePath = Path()
      ..moveTo(w * 0.72, h * 0.66)
      ..quadraticBezierTo(w * 0.78, h * 0.58, w * 0.76, h * 0.68)
      ..lineTo(w * 0.66, h * 0.68);
    canvas.drawPath(horsePath, paint);

    // 6. Base / Bell-shaped Lotus Platform
    final baseTop = Rect.fromLTWH(w * 0.14, h * 0.74, w * 0.72, h * 0.06);
    canvas.drawRect(baseTop, fillPaint);
    canvas.drawRect(baseTop, paint);

    final baseBottom = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.81, w * 0.80, h * 0.08),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(baseBottom, fillPaint);
    canvas.drawRRect(baseBottom, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
