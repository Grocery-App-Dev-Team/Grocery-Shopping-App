import 'package:geocoding/geocoding.dart' as geo;
import 'package:latlong2/latlong.dart';

/// Service để geocode địa chỉ text → lat/lng
/// Sử dụng native geocoding (Google Maps Android/Apple Maps iOS)
class GeocodingService {
  /// Chuyển địa chỉ text thành coordinates
  /// Dùng native APIs (mạnh, nhanh, không cần key)
  static Future<LatLng?> geocodeAddress(String address) async {
    if (address.isEmpty) {
      throw Exception('Address cannot be empty');
    }

    try {
      final placemarks = await geo.locationFromAddress(address);

      if (placemarks.isEmpty) {
        throw Exception('Address not found: $address');
      }

      final place = placemarks.first;
      return LatLng(place.latitude, place.longitude);
    } catch (e) {
      throw Exception('Geocoding error: $e');
    }
  }

  /// Chuyển coordinate thành địa chỉ text (reverse geocoding)
  static Future<String?> reverseGeocode(LatLng location) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) {
        return null;
      }

      final place = placemarks.first;
      final parts = <String>[
        if (place.street?.isNotEmpty == true) place.street!,
        if (place.postalCode?.isNotEmpty == true) place.postalCode!,
        if (place.locality?.isNotEmpty == true) place.locality!,
        if (place.administrativeArea?.isNotEmpty == true)
          place.administrativeArea!,
      ];

      return parts.join(', ');
    } catch (e) {
      throw Exception('Reverse geocoding error: $e');
    }
  }

  /// Geocode multiple addresses
  static Future<Map<String, LatLng?>> geocodeMultiple(
    List<String> addresses,
  ) async {
    final results = <String, LatLng?>{};

    for (final address in addresses) {
      try {
        results[address] = await geocodeAddress(address);
      } catch (e) {
        results[address] = null;
      }
    }

    return results;
  }
}
