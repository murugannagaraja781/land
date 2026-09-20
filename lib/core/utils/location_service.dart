import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LiveLocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String estimatedArea;
  final String estimatedCity;
  final String postalCode;
  final bool isLiveGps;
  final String? error;

  const LiveLocationResult({
    required this.latitude,
    required this.longitude,
    this.accuracy = 10.0,
    required this.estimatedArea,
    required this.estimatedCity,
    required this.postalCode,
    required this.isLiveGps,
    this.error,
  });

  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(5)}° N, ${longitude.toStringAsFixed(5)}° E';
}

class LocationService {
  /// Known Tenkasi & Tamil Nadu reference points for reverse matching and distance sorting
  static final List<Map<String, dynamic>> _tnKnownCenters = [
    {
      'city': 'Tenkasi',
      'area': 'பாவூர்சத்திரம் (Pavoorchatram)',
      'shortName': 'Pavoorchatram',
      'lat': 8.9056,
      'lng': 77.3828,
      'pincode': '627808',
    },
    {
      'city': 'Tenkasi',
      'area': 'தென்காசி (Tenkasi)',
      'shortName': 'Tenkasi',
      'lat': 8.9594,
      'lng': 77.3160,
      'pincode': '627811',
    },
    {
      'city': 'Tenkasi',
      'area': 'குற்றாலம் (Courtallam)',
      'shortName': 'Courtallam',
      'lat': 8.9324,
      'lng': 77.2690,
      'pincode': '627802',
    },
    {
      'city': 'Tenkasi',
      'area': 'சுரண்டை (Surandai)',
      'shortName': 'Surandai',
      'lat': 8.9772,
      'lng': 77.4244,
      'pincode': '627859',
    },
    {
      'city': 'Tenkasi',
      'area': 'ஆலங்குளம் (Alangulam)',
      'shortName': 'Alangulam',
      'lat': 8.8711,
      'lng': 77.4983,
      'pincode': '627851',
    },
    {
      'city': 'Tenkasi',
      'area': 'கடையநல்லூர் (Kadayanallur)',
      'shortName': 'Kadayanallur',
      'lat': 9.0754,
      'lng': 77.3482,
      'pincode': '627751',
    },
    {
      'city': 'Tenkasi',
      'area': 'செங்கோட்டை (Shenkottai)',
      'shortName': 'Shenkottai',
      'lat': 8.9857,
      'lng': 77.2472,
      'pincode': '627809',
    },
    {
      'city': 'Tenkasi',
      'area': 'சங்கரன்கோவில் (Sankarankovil)',
      'shortName': 'Sankarankovil',
      'lat': 9.1722,
      'lng': 77.5325,
      'pincode': '627756',
    },
    {
      'city': 'Tenkasi',
      'area': 'புளியங்குடி (Puliyangudi)',
      'shortName': 'Puliyangudi',
      'lat': 9.1672,
      'lng': 77.3995,
      'pincode': '627855',
    },
    {
      'city': 'Tirunelveli',
      'area': 'திருநெல்வேலி (Tirunelveli)',
      'shortName': 'Tirunelveli',
      'lat': 8.7139,
      'lng': 77.7567,
      'pincode': '627002',
    },
    {
      'city': 'Tirunelveli',
      'area': 'அம்பாசமுத்திரம் (Ambasamudram)',
      'shortName': 'Ambasamudram',
      'lat': 8.7058,
      'lng': 77.4526,
      'pincode': '627401',
    },
    {
      'city': 'Madurai',
      'area': 'மதுரை (Madurai)',
      'shortName': 'Madurai',
      'lat': 9.9252,
      'lng': 78.1198,
      'pincode': '625020',
    },
    {
      'city': 'Chennai',
      'area': 'சென்னை (Chennai)',
      'shortName': 'Chennai',
      'lat': 13.0827,
      'lng': 80.2707,
      'pincode': '600001',
    },
  ];

  /// Calculate distance between two coordinates in Kilometers
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    try {
      final meters = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
      return meters / 1000.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Get coordinates for a town name (e.g. 'Pavoorchatram', 'Tenkasi')
  static Map<String, double>? getCoordinatesForTown(String townName) {
    final query = townName.toLowerCase();
    for (final center in _tnKnownCenters) {
      final shortName = (center['shortName'] as String).toLowerCase();
      final area = (center['area'] as String).toLowerCase();
      final city = (center['city'] as String).toLowerCase();
      if (query.contains(shortName) || query.contains(area) || query.contains(city)) {
        return {
          'lat': center['lat'] as double,
          'lng': center['lng'] as double,
        };
      }
    }
    // Default to Tenkasi Central
    return {'lat': 8.9594, 'lng': 77.3160};
  }

  /// Request live device location using Geolocator
  static Future<LiveLocationResult> getCurrentLiveLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallbackLocation(
          error: 'Location services are disabled on this device. Using default coordinates.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallbackLocation(
            error: 'Location permission was denied. Using fallback coordinates.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _fallbackLocation(
          error: 'Location permissions are permanently denied. Using fallback coordinates.',
        );
      }

      // Live position acquired
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final matched = _findClosestTNLocality(position.latitude, position.longitude);

      return LiveLocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        estimatedArea: matched['area']!,
        estimatedCity: matched['city']!,
        postalCode: matched['pincode']!,
        isLiveGps: true,
      );
    } catch (e) {
      debugPrint('Live location error: $e');
      return _fallbackLocation(error: 'Could not fetch live GPS: $e');
    }
  }

  static Map<String, String> _findClosestTNLocality(double lat, double lng) {
    double minDistance = double.infinity;
    Map<String, dynamic> closest = _tnKnownCenters.first;

    for (final center in _tnKnownCenters) {
      final dLat = (center['lat'] as double) - lat;
      final dLng = (center['lng'] as double) - lng;
      final distSq = dLat * dLat + dLng * dLng;
      if (distSq < minDistance) {
        minDistance = distSq;
        closest = center;
      }
    }

    return {
      'area': closest['shortName'] as String,
      'fullName': closest['area'] as String,
      'city': closest['city'] as String,
      'pincode': closest['pincode'] as String,
    };
  }

  static LiveLocationResult _fallbackLocation({String? error}) {
    return LiveLocationResult(
      latitude: 8.9594,
      longitude: 77.3160,
      accuracy: 25.0,
      estimatedArea: 'Tenkasi',
      estimatedCity: 'Tenkasi',
      postalCode: '627811',
      isLiveGps: false,
      error: error,
    );
  }

  /// Generates a Google Maps URL for opening in browser / native Maps app
  static String getGoogleMapsUrl(double lat, double lng, {String? label}) {
    final query = label != null ? Uri.encodeComponent(label) : '$lat,$lng';
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$query';
  }
}
