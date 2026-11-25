import 'dart:math' as math;

import 'package:flutter/material.dart';

enum Sky {
  clear('Cerah', Icons.wb_sunny_rounded, Color(0xffffe9a7), Color(0xffffd29c)),
  fair(
    'Cerah berawan',
    Icons.wb_twilight_rounded,
    Color(0xffccedef),
    Color(0xffffe4ad),
  ),
  cloud('Berawan', Icons.cloud_outlined, Color(0xffd0e8f3), Color(0xffe1ebdd)),
  fog('Berkabut', Icons.foggy, Color(0xffd8e5de), Color(0xffebe4d1)),
  rain(
    'Hujan',
    Icons.water_drop_outlined,
    Color(0xffc3dce8),
    Color(0xffc9dfda),
  ),
  snow('Salju', Icons.ac_unit, Color(0xffdcecfb), Color(0xffe8e3fc)),
  storm(
    'Badai petir',
    Icons.thunderstorm_outlined,
    Color(0xffc8cdea),
    Color(0xffdcddeb),
  ),
  unknown(
    'Kondisi belum diketahui',
    Icons.cloud_queue,
    Color(0xffdeebe8),
    Color(0xffe9efde),
  );

  const Sky(this.label, this.icon, this.top, this.bottom);
  final String label;
  final IconData icon;
  final Color top, bottom;

  static Sky from(int? code) => switch (code) {
    0 => clear,
    1 || 2 => fair,
    3 => cloud,
    45 || 48 => fog,
    51 ||
    53 ||
    55 ||
    56 ||
    57 ||
    61 ||
    63 ||
    65 ||
    66 ||
    67 ||
    80 ||
    81 ||
    82 => rain,
    71 || 73 || 75 || 77 || 85 || 86 => snow,
    95 || 96 || 99 => storm,
    _ => unknown,
  };
}

// A layered landscape drawn at the actual card size; the sky follows the API.
class Landscape extends CustomPainter {
  const Landscape(this.sky, this.day);
  final Sky sky;
  final bool day;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final bounds = Offset.zero & size;
    final top = day
        ? sky.top
        : Color.lerp(sky.top, const Color(0xffb7bbdf), .7)!;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [top, sky.bottom],
        ).createShader(bounds),
    );
    final center = Offset(w * .82, h * .32);
    final radius = math.min(w * .11, 52.0);
    final paint = Paint()..color = Colors.white.withValues(alpha: .27);
    canvas.drawCircle(center, radius * 1.27, paint);
    paint.color = day ? const Color(0xffffd06c) : const Color(0xfffcf2d7);
    canvas.drawCircle(center, radius, paint);
    if (!day) {
      canvas.drawCircle(
        center.translate(radius * .4, -radius * .28),
        radius * .84,
        Paint()..color = top,
      );
    }
    if (sky != Sky.clear) {
      for (final offset in [
        Offset(w * .82, h * .36),
        Offset(w * .94, h * .24),
      ]) {
        final cloud = Paint()..color = const Color(0xfff4faf5);
        canvas.drawOval(
          Rect.fromCenter(
            center: offset,
            width: radius * 1.8,
            height: radius * .36,
          ),
          cloud,
        );
        canvas.drawCircle(
          offset.translate(-radius * .18, -radius * .12),
          radius * .28,
          cloud,
        );
        canvas.drawCircle(
          offset.translate(radius * .19, -radius * .13),
          radius * .37,
          cloud,
        );
      }
    }
    if (sky == Sky.rain || sky == Sky.storm || sky == Sky.snow) {
      final drops = Paint()
        ..color = const Color(0xff7995a8)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 6; i++) {
        final p = Offset(w * .75 + i * radius * .22, h * .44 + (i % 2) * 5);
        canvas.drawLine(p, p.translate(-2, 5), drops);
      }
    }
    final ridge = Path()
      ..moveTo(0, h * .96)
      ..cubicTo(w * .25, h * .88, w * .44, h * 1.02, w * .58, h * .82)
      ..lineTo(w * .72, h * .59)
      ..quadraticBezierTo(w * .74, h * .56, w * .77, h * .61)
      ..lineTo(w * .90, h * .76)
      ..lineTo(w, h * .62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ridge, Paint()..color = const Color(0xff8cb5a8));
    final hill = Path()
      ..moveTo(0, h * .95)
      ..cubicTo(w * .20, h * .85, w * .38, h * 1.07, w * .66, h * .87)
      ..quadraticBezierTo(w * .82, h * .71, w, h * .78)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xff558779));
    final front = Path()
      ..moveTo(0, h * .93)
      ..cubicTo(w * .25, h * 1.02, w * .47, h * .87, w * .68, h * .96)
      ..quadraticBezierTo(w * .82, h * .99, w, h * .87)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, Paint()..color = const Color(0xff37665c));
  }

  @override
  bool shouldRepaint(Landscape old) => old.sky != sky || old.day != day;
}
