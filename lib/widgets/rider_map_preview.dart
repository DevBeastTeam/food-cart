import 'package:flutter/material.dart';

class RiderMapPreview extends StatefulWidget {
  final String pickupAddress;
  final String deliveryAddress;
  final String customerName;
  final VoidCallback? onOpenGoogleMaps;
  final bool isFullScreen;

  const RiderMapPreview({
    super.key,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.customerName,
    this.onOpenGoogleMaps,
    this.isFullScreen = false,
  });

  @override
  State<RiderMapPreview> createState() => _RiderMapPreviewState();
}

class _RiderMapPreviewState extends State<RiderMapPreview> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E9EC),
        borderRadius: BorderRadius.circular(widget.isFullScreen ? 0 : 16),
        border: widget.isFullScreen ? null : Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: widget.isFullScreen
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        children: [
          // Custom Painted Street Map
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _DemoMapPainter(progress: _animController.value),
                );
              },
            ),
          ),

          // Top Instruction Turn-by-Turn Card
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2A4A),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.turn_right_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'In 250m turn right',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Onto Main Boulevard Gulberg III',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '3.4 km',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar: Google Maps Launcher & ETA
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick info chips
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(30),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          const Text(
                            'ETA: 12 mins',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Fast Route',
                            style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(30),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.speed_rounded, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '38 km/h',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.blue.shade900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Open in Google Maps Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onOpenGoogleMaps ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.navigation_rounded, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Launching Google Maps navigation to: ${widget.deliveryAddress}',
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF1B2A4A),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text(
                      'Open in Google Maps',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8), // Google Blue
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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

class _DemoMapPainter extends CustomPainter {
  final double progress;

  _DemoMapPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background Fill
    final bgPaint = Paint()..color = const Color(0xFFE8ECEF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. City Blocks / Parks
    final blockPaint = Paint()..color = const Color(0xFFDCE2E6);
    final parkPaint = Paint()..color = const Color(0xFFD4E7DC);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(15, 60, size.width * 0.4, 70), const Radius.circular(8)),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.52, 60, size.width * 0.42, 65), const Radius.circular(8)),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(20, 150, size.width * 0.35, 90), const Radius.circular(8)),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.5, 145, size.width * 0.44, 90), const Radius.circular(8)),
      parkPaint,
    );

    // 3. Secondary Streets
    final streetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final streetBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Horizontal street
    canvas.drawLine(Offset(0, size.height * 0.45), Offset(size.width, size.height * 0.45), streetBorderPaint);
    canvas.drawLine(Offset(0, size.height * 0.45), Offset(size.width, size.height * 0.45), streetPaint);

    // Vertical street
    canvas.drawLine(Offset(size.width * 0.46, 0), Offset(size.width * 0.46, size.height), streetBorderPaint);
    canvas.drawLine(Offset(size.width * 0.46, 0), Offset(size.width * 0.46, size.height), streetPaint);

    // Diagonal street
    canvas.drawLine(Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.3), streetBorderPaint);
    canvas.drawLine(Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.3), streetPaint);

    // 4. Active GPS Route Path
    final routePath = Path();
    final startPt = Offset(size.width * 0.2, size.height * 0.72);
    final p1 = Offset(size.width * 0.46, size.height * 0.72);
    final p2 = Offset(size.width * 0.46, size.height * 0.45);
    final p3 = Offset(size.width * 0.78, size.height * 0.45);
    final endPt = Offset(size.width * 0.78, size.height * 0.28);

    routePath.moveTo(startPt.dx, startPt.dy);
    routePath.lineTo(p1.dx, p1.dy);
    routePath.lineTo(p2.dx, p2.dy);
    routePath.lineTo(p3.dx, p3.dy);
    routePath.lineTo(endPt.dx, endPt.dy);

    // Route Outer Glow / Border
    final routeBorderPaint = Paint()
      ..color = const Color(0xFF1E40AF).withAlpha(160)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, routeBorderPaint);

    // Route Core Line
    final routePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, routePaint);

    // 5. Pickup Marker (Store)
    final storePaint = Paint()..color = Colors.amber.shade700;
    canvas.drawCircle(startPt, 11, storePaint);
    canvas.drawCircle(startPt, 5, Paint()..color = Colors.white);

    // 6. Destination Marker (Customer)
    final destPaint = Paint()..color = Colors.red.shade600;
    canvas.drawCircle(endPt, 11, destPaint);
    canvas.drawCircle(endPt, 5, Paint()..color = Colors.white);

    // 7. Rider Bike Marker (Animated between start and end)
    // Interpolate rider location along the path segments
    Offset riderPos;
    if (progress < 0.3) {
      final t = progress / 0.3;
      riderPos = Offset.lerp(startPt, p1, t)!;
    } else if (progress < 0.55) {
      final t = (progress - 0.3) / 0.25;
      riderPos = Offset.lerp(p1, p2, t)!;
    } else if (progress < 0.85) {
      final t = (progress - 0.55) / 0.3;
      riderPos = Offset.lerp(p2, p3, t)!;
    } else {
      final t = (progress - 0.85) / 0.15;
      riderPos = Offset.lerp(p3, endPt, t)!;
    }

    // Pulse wave around rider
    final pulsePaint = Paint()
      ..color = const Color(0xFF2563EB).withAlpha((60 * (1 - (progress % 0.5) * 2)).toInt().clamp(0, 255))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(riderPos, 14 + 10 * ((progress * 2) % 1), pulsePaint);

    // Rider Circle
    final riderBgPaint = Paint()..color = const Color(0xFF1B2A4A);
    canvas.drawCircle(riderPos, 10, riderBgPaint);
    canvas.drawCircle(riderPos, 8, Paint()..color = const Color(0xFF38BDF8));
  }

  @override
  bool shouldRepaint(covariant _DemoMapPainter oldDelegate) => oldDelegate.progress != progress;
}
