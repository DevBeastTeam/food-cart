import 'package:flutter/material.dart';
import '../services/map_launcher_service.dart';
import '../state/user_state.dart';
import '../theme/app_theme.dart';

enum MapStyleMode { standard, satellite, terrain }

class RiderGoogleMapView extends StatefulWidget {
  final UserOrder? order;
  final bool isFullScreen;
  final VoidCallback? onClose;

  const RiderGoogleMapView({
    super.key,
    this.order,
    this.isFullScreen = false,
    this.onClose,
  });

  @override
  State<RiderGoogleMapView> createState() => _RiderGoogleMapViewState();
}

class _RiderGoogleMapViewState extends State<RiderGoogleMapView>
    with SingleTickerProviderStateMixin {
  MapStyleMode _mapStyle = MapStyleMode.standard;
  double _zoomLevel = 1.0;
  bool _showTraffic = true;
  bool _isNavigating = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final destination = order?.address ?? 'Main Boulevard, Gulberg III, Lahore';
    final customer = order?.customerName ?? 'Valued Customer';


    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E3DF), // Classic Google Maps background
        borderRadius: widget.isFullScreen ? BorderRadius.zero : BorderRadius.circular(16),
        boxShadow: widget.isFullScreen
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: widget.isFullScreen ? BorderRadius.zero : BorderRadius.circular(16),
        child: Stack(
          children: [
            // 1. Google Maps Vector Canvas Painter
            Positioned.fill(
              child: GestureDetector(
                onDoubleTap: () {
                  setState(() {
                    _zoomLevel = (_zoomLevel >= 1.4) ? 1.0 : _zoomLevel + 0.2;
                  });
                },
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _GoogleMapCanvasPainter(
                        zoom: _zoomLevel,
                        mapStyle: _mapStyle,
                        showTraffic: _showTraffic,
                        pulseValue: _pulseController.value,
                        isNavigating: _isNavigating,
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. Google Logo Watermark (bottom-left)
            Positioned(
              bottom: widget.isFullScreen ? 100 : 12,
              left: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(220),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Google_Maps_icon_%282020%29.svg/100px-Google_Maps_icon_%282020%29.svg.png',
                          width: 14,
                          height: 14,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.map,
                            size: 14,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Google Maps',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3C4043),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(210),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'GPS: 31.5204° N, 74.3587° E',
                      style: TextStyle(fontSize: 9.5, color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Top Turn-by-Turn Guidance Banner (When order is active)
            Positioned(
              top: widget.isFullScreen ? 48 : 12,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2A4A),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
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
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.turn_right_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _isNavigating ? 'In 180m • Turn Right' : 'Route to Customer',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade400,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'LIVE GPS',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                destination,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (widget.onClose != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: widget.onClose,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Distance & ETA quick pills
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_bike_rounded, size: 14, color: Colors.blue.shade700),
                            const SizedBox(width: 5),
                            const Text(
                              '11 mins (3.2 km)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Fast Route • Low Traffic',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 4. Floating Google Map Controls (Right side)
            Positioned(
              right: 12,
              top: widget.isFullScreen ? 150 : 100,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Map Style switch (Standard / Satellite)
                  _buildMapIconButton(
                    icon: _mapStyle == MapStyleMode.satellite
                        ? Icons.satellite_alt_rounded
                        : Icons.layers_outlined,
                    tooltip: 'Change Map Layer',
                    onTap: () {
                      setState(() {
                        if (_mapStyle == MapStyleMode.standard) {
                          _mapStyle = MapStyleMode.satellite;
                        } else if (_mapStyle == MapStyleMode.satellite) {
                          _mapStyle = MapStyleMode.terrain;
                        } else {
                          _mapStyle = MapStyleMode.standard;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Traffic Toggle
                  _buildMapIconButton(
                    icon: Icons.traffic_rounded,
                    color: _showTraffic ? Colors.green.shade700 : Colors.grey,
                    tooltip: 'Toggle Traffic',
                    onTap: () {
                      setState(() => _showTraffic = !_showTraffic);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_showTraffic ? 'Google Traffic: ON' : 'Google Traffic: OFF'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Zoom In
                  _buildMapIconButton(
                    icon: Icons.add,
                    tooltip: 'Zoom In',
                    onTap: () {
                      setState(() {
                        if (_zoomLevel < 1.6) _zoomLevel += 0.2;
                      });
                    },
                  ),
                  const SizedBox(height: 6),

                  // Zoom Out
                  _buildMapIconButton(
                    icon: Icons.remove,
                    tooltip: 'Zoom Out',
                    onTap: () {
                      setState(() {
                        if (_zoomLevel > 0.8) _zoomLevel -= 0.2;
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Re-center on Rider (My Location)
                  _buildMapIconButton(
                    icon: Icons.my_location_rounded,
                    color: Colors.blue.shade700,
                    tooltip: 'Center on Rider',
                    onTap: () {
                      setState(() => _zoomLevel = 1.0);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Centered on Rider Location (Gulberg III, Lahore)'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 5. Bottom Navigation Control Bar (When full screen or bottom card)
            if (widget.isFullScreen)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_pin_circle_rounded, color: Colors.green.shade800, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  destination,
                                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Calling $customer: ${order?.customerPhone ?? "+92 300 1234567"}')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                setState(() => _isNavigating = true);
                                final lat = order?.latitude ?? 31.5204;
                                final lng = order?.longitude ?? 74.3587;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Starting Google Maps Turn-by-Turn GPS for $customer...'),
                                    backgroundColor: const Color(0xFF1A73E8),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                await MapLauncherService.launchRiderNavigation(
                                  lat: lat,
                                  lng: lng,
                                  fallbackAddress: destination,
                                );
                              },
                              icon: const Icon(Icons.navigation_rounded),
                              label: const Text('Start Official GPS'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A73E8), // Official Google Blue
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final lat = order?.latitude ?? 31.5204;
                              final lng = order?.longitude ?? 74.3587;
                              await MapLauncherService.launchRiderNavigation(
                                lat: lat,
                                lng: lng,
                                fallbackAddress: destination,
                              );
                            },
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Google Maps'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1A73E8),
                              side: const BorderSide(color: Color(0xFF1A73E8)),
                              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(7.5),
            child: Icon(icon, size: 19, color: color ?? const Color(0xFF5F6368)),
          ),
        ),
      ),
    );
  }
}

/// Custom Canvas Painter rendering vector roads, water, parks, route polyline and pins
class _GoogleMapCanvasPainter extends CustomPainter {
  final double zoom;
  final MapStyleMode mapStyle;
  final bool showTraffic;
  final double pulseValue;
  final bool isNavigating;

  _GoogleMapCanvasPainter({
    required this.zoom,
    required this.mapStyle,
    required this.showTraffic,
    required this.pulseValue,
    required this.isNavigating,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Background Fill
    final bgPaint = Paint();
    if (mapStyle == MapStyleMode.satellite) {
      bgPaint.color = const Color(0xFF1D2C24);
    } else if (mapStyle == MapStyleMode.terrain) {
      bgPaint.color = const Color(0xFFE8ECE1);
    } else {
      bgPaint.color = const Color(0xFFF2EFE9); // Google Maps Light Beige
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Parks / Greenery
    final parkPaint = Paint()
      ..color = mapStyle == MapStyleMode.satellite
          ? const Color(0xFF15221B)
          : const Color(0xFFC8E6C9).withAlpha(160)
      ..style = PaintingStyle.fill;

    // Park 1 (Top Left - e.g. Race Course Park)
    final park1 = Path()
      ..moveTo(w * 0.05, h * 0.15)
      ..lineTo(w * 0.28, h * 0.18)
      ..lineTo(w * 0.25, h * 0.38)
      ..lineTo(w * 0.02, h * 0.32)
      ..close();
    canvas.drawPath(park1, parkPaint);

    // Park 2 (Bottom Right - e.g. Model Town Park)
    final park2 = Path()
      ..moveTo(w * 0.65, h * 0.62)
      ..lineTo(w * 0.92, h * 0.60)
      ..lineTo(w * 0.88, h * 0.82)
      ..lineTo(w * 0.62, h * 0.78)
      ..close();
    canvas.drawPath(park2, parkPaint);

    // 3. Water Canal (Lahore Canal style)
    final waterPaint = Paint()
      ..color = mapStyle == MapStyleMode.satellite
          ? const Color(0xFF14243B)
          : const Color(0xFFA5D6A7).withAlpha(0) // replace with water blue
      ..color = const Color(0xFFAAD3DF) // Google Maps Water Blue
      ..strokeWidth = 14 * zoom
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final canalPath = Path()
      ..moveTo(-20, h * 0.75)
      ..cubicTo(w * 0.3, h * 0.70, w * 0.6, h * 0.35, w + 20, h * 0.25);
    canvas.drawPath(canalPath, waterPaint);

    // 4. Secondary Road Network (Grid lines)
    final minorRoadPaint = Paint()
      ..color = mapStyle == MapStyleMode.satellite
          ? const Color(0xFF37474F)
          : Colors.white
      ..strokeWidth = 3.5 * zoom
      ..style = PaintingStyle.stroke;

    for (double y = 40; y < h; y += 45 * zoom) {
      canvas.drawLine(Offset(0, y), Offset(w, y + 10), minorRoadPaint);
    }
    for (double x = 30; x < w; x += 55 * zoom) {
      canvas.drawLine(Offset(x, 0), Offset(x + 15, h), minorRoadPaint);
    }

    // 5. Major Arterial Avenues (Main Boulevard Gulberg & Ferozepur Rd)
    final majorRoadBorder = Paint()
      ..color = mapStyle == MapStyleMode.satellite
          ? Colors.black26
          : const Color(0xFFE0C29F)
      ..strokeWidth = 10 * zoom
      ..style = PaintingStyle.stroke;

    final majorRoadInner = Paint()
      ..color = mapStyle == MapStyleMode.satellite
          ? const Color(0xFF546E7A)
          : const Color(0xFFFFF7B2) // Classic Google Maps Yellow Road
      ..strokeWidth = 7.5 * zoom
      ..style = PaintingStyle.stroke;

    // Avenue 1: Diagonal Main Blvd
    final avenue1 = Path()
      ..moveTo(-10, h * 0.3)
      ..lineTo(w * 0.45, h * 0.45)
      ..lineTo(w + 20, h * 0.85);
    canvas.drawPath(avenue1, majorRoadBorder);
    canvas.drawPath(avenue1, majorRoadInner);

    // Avenue 2: Cross Street
    final avenue2 = Path()
      ..moveTo(w * 0.2, -10)
      ..lineTo(w * 0.45, h * 0.45)
      ..lineTo(w * 0.7, h + 10);
    canvas.drawPath(avenue2, majorRoadBorder);
    canvas.drawPath(avenue2, majorRoadInner);

    // 6. Traffic Overlay
    if (showTraffic) {
      final trafficGreen = Paint()
        ..color = const Color(0xFF34A853).withAlpha(190)
        ..strokeWidth = 3 * zoom
        ..style = PaintingStyle.stroke;
      final trafficOrange = Paint()
        ..color = const Color(0xFFFBBC05).withAlpha(220)
        ..strokeWidth = 3 * zoom
        ..style = PaintingStyle.stroke;

      // Draw green flow along canal
      canvas.drawPath(canalPath, trafficGreen);

      // Draw orange along cross avenue
      final trafficPath = Path()
        ..moveTo(w * 0.3, h * 0.15)
        ..lineTo(w * 0.45, h * 0.45);
      canvas.drawPath(trafficPath, trafficOrange);
    }

    // Coordinates of 3 Key Waypoints:
    // P1: Pickup (Central Kitchen / Restaurant)
    final pickupPos = Offset(w * 0.22, h * 0.38);
    // P2: Live Rider Location (Moving with pulse)
    final riderOffsetProgress = isNavigating ? (pulseValue * 0.12) : 0.0;
    final riderPos = Offset(w * (0.48 + riderOffsetProgress), h * (0.47 + riderOffsetProgress));
    // P3: Destination (Customer House)
    final dropoffPos = Offset(w * 0.78, h * 0.72);

    // 7. Active GPS Navigation Route Polyline (Google Blue)
    final routeOutline = Paint()
      ..color = const Color(0xFF1967D2) // Dark Blue Outline
      ..strokeWidth = 9.5 * zoom
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routePaint = Paint()
      ..color = const Color(0xFF4285F4) // Google Navigation Blue
      ..strokeWidth = 6.5 * zoom
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routePath = Path()
      ..moveTo(pickupPos.dx, pickupPos.dy)
      ..lineTo(w * 0.35, h * 0.42)
      ..lineTo(riderPos.dx, riderPos.dy)
      ..lineTo(w * 0.62, h * 0.58)
      ..lineTo(dropoffPos.dx, dropoffPos.dy);

    canvas.drawPath(routePath, routeOutline);
    canvas.drawPath(routePath, routePaint);

    // 8. Draw Pickup Marker (Store Pin)
    _drawLocationPin(
      canvas: canvas,
      center: pickupPos,
      label: 'PICKUP',
      bgColor: const Color(0xFFEA4335), // Google Red
      iconData: Icons.storefront_rounded,
    );

    // 9. Draw Dropoff Marker (Customer Pin)
    _drawLocationPin(
      canvas: canvas,
      center: dropoffPos,
      label: 'DROP',
      bgColor: const Color(0xFF34A853), // Google Green
      iconData: Icons.location_on_rounded,
    );

    // 10. Draw Animated Rider Beacon & Bike Marker
    _drawRiderMarker(canvas, riderPos);
  }

  void _drawLocationPin({
    required Canvas canvas,
    required Offset center,
    required String label,
    required Color bgColor,
    required IconData iconData,
  }) {
    // Shadow
    canvas.drawCircle(
      Offset(center.dx, center.dy + 3),
      12,
      Paint()..color = Colors.black26,
    );

    // Outer circle
    final pinPaint = Paint()..color = bgColor;
    canvas.drawCircle(center, 12, pinPaint);

    // Inner White dot
    canvas.drawCircle(center, 4.5, Paint()..color = Colors.white);

    // Text Badge label below
    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 18),
        width: textPainter.width + 10,
        height: textPainter.height + 4,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(badgeRect, Paint()..color = bgColor);
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 18 - textPainter.height / 2),
    );
  }

  void _drawRiderMarker(Canvas canvas, Offset center) {
    // Pulsing GPS radar circle
    final pulseRadius = 14.0 + (pulseValue * 18.0);
    final pulseAlpha = ((1.0 - pulseValue) * 90).clamp(0, 255).toInt();
    final pulsePaint = Paint()
      ..color = const Color(0xFF1A73E8).withAlpha(pulseAlpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pulseRadius, pulsePaint);

    // White border ring
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2),
    );

    // Blue Center Circle
    canvas.drawCircle(
      center,
      11,
      Paint()..color = const Color(0xFF1A73E8),
    );

    // Heading Arrow / Direction Cone
    final arrowPaint = Paint()
      ..color = const Color(0xFF1A73E8)
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(center.dx + 11, center.dy - 3)
      ..lineTo(center.dx + 20, center.dy)
      ..lineTo(center.dx + 11, center.dy + 3)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    // Rider Label
    const riderSpan = TextSpan(
      text: '🛵 YOU (RIDER)',
      style: TextStyle(
        color: Color(0xFF1A73E8),
        fontSize: 8.5,
        fontWeight: FontWeight.w900,
      ),
    );
    final riderPainter = TextPainter(
      text: riderSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final rRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 18),
        width: riderPainter.width + 8,
        height: riderPainter.height + 3,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(rRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = const Color(0xFF1A73E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    riderPainter.paint(
      canvas,
      Offset(center.dx - riderPainter.width / 2, center.dy - 18 - riderPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleMapCanvasPainter oldDelegate) {
    return oldDelegate.zoom != zoom ||
        oldDelegate.mapStyle != mapStyle ||
        oldDelegate.showTraffic != showTraffic ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isNavigating != isNavigating;
  }
}
