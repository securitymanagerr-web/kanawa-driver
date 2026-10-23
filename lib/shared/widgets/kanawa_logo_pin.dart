// KANAWA - Logotipo (pin 3D com carro)
// Design: MBSoft · Benvindo Mersh

import 'package:flutter/material.dart';

class KanawaLogoPin extends StatelessWidget {
  final double size;
  final bool showShadow;

  const KanawaLogoPin({
    super.key,
    this.size = 100,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.15,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sombra
          if (showShadow)
            Positioned(
              bottom: 0,
              child: Container(
                width: size * 0.7,
                height: size * 0.12,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(size),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: size * 0.1,
                      spreadRadius: size * 0.05,
                    ),
                  ],
                ),
              ),
            ),
          // Pin
          Positioned(
            top: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE01818), Color(0xFFB91C1C)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE01818).withOpacity(0.35),
                    blurRadius: size * 0.25,
                    spreadRadius: size * 0.05,
                    offset: Offset(0, size * 0.08),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: size * 0.72,
                  height: size * 0.72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1F),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: size * 0.025,
                    ),
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: size * 0.4,
                  ),
                ),
              ),
            ),
          ),
          // Ponta do pin
          Positioned(
            top: size * 0.85,
            child: CustomPaint(
              size: Size(size * 0.35, size * 0.3),
              painter: _PinPointPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinPointPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}