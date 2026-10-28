import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncherService {
  MapLauncherService._();

  /// Free Official Google Maps Turn-by-Turn Navigation for Rider.
  /// Launches native Google Maps app with route calculated directly
  /// from the rider's current physical GPS location to the customer's coordinates or address.
  /// Zero Google Directions API charges required.
  static Future<bool> launchRiderNavigation({
    required double lat,
    required double lng,
    String? fallbackAddress,
  }) async {
    final bool hasValidCoords = (lat.abs() > 0.001 && lng.abs() > 0.001 && lat.abs() <= 90 && lng.abs() <= 180);

    if (hasValidCoords) {
      // 1. Android/iOS Google Maps Turn-by-Turn GPS navigation scheme
      final Uri nativeNavUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');

      // 2. Universal Web / iOS directions link (opens Google Maps App or browser fallback)
      final Uri universalWebUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
      );

      try {
        if (await canLaunchUrl(nativeNavUri)) {
          return await launchUrl(nativeNavUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('[MapLauncher] Native navigation uri check: $e');
      }

      try {
        if (await canLaunchUrl(universalWebUri)) {
          return await launchUrl(universalWebUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('[MapLauncher] Universal directions uri check: $e');
      }
    }

    // 3. Fallback with address if coordinates missing or invalid
    if (fallbackAddress != null && fallbackAddress.trim().isNotEmpty) {
      final cleanAddr = fallbackAddress.trim();
      final Uri nativeAddressNav = Uri.parse(
        'google.navigation:q=${Uri.encodeComponent(cleanAddr)}&mode=d',
      );
      try {
        if (await canLaunchUrl(nativeAddressNav)) {
          return await launchUrl(nativeAddressNav, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('[MapLauncher] Native address navigation check: $e');
      }

      final Uri addressUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(cleanAddr)}&travelmode=driving',
      );
      try {
        return await launchUrl(addressUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('[MapLauncher] Address directions uri check: $e');
      }
    }

    return false;
  }

  /// Free Location Pin View for Customer or Admin.
  /// Opens Google Maps with a marker dropped at the delivery coordinates.
  static Future<bool> launchLocationPin({
    required double lat,
    required double lng,
    String? fallbackAddress,
  }) async {
    final Uri mapPinUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      if (await canLaunchUrl(mapPinUri)) {
        return await launchUrl(mapPinUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[MapLauncher] Map pin uri check: $e');
    }

    if (fallbackAddress != null && fallbackAddress.trim().isNotEmpty) {
      final Uri addressPinUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(fallbackAddress)}',
      );
      try {
        return await launchUrl(addressPinUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('[MapLauncher] Address pin uri check: $e');
      }
    }

    return false;
  }
}
