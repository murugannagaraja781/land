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
  /// Known Tamil Nadu reference points for reverse matching
  static final List<Map<String, dynamic>> _tnKnownCenters = [
    {
      'city': 'Chennai',
      'area': 'Anna Nagar',
      'lat': 13.0850,
      'lng': 80.2101,
      'pincode': '600040',
    },
    {
      'city': 'Chennai',
      'area': 'Porur',
      'lat': 13.0382,
      'lng': 80.1565,
      'pincode': '600116',
    },
    {
      'city': 'Chennai',
      'area': 'Tambaram',
      'lat': 12.9249,
      'lng': 80.1000,
      'pincode': '600045',
    },
    {
      'city': 'Chennai',
      'area': 'Velachery',
      'lat': 12.9815,
      'lng': 80.2180,
      'pincode': '600042',
    },
    {
      'city': 'Chennai',
      'area': 'OMR - Sholinganallur',
      'lat': 12.9010,
      'lng': 80.2279,
      'pincode': '600119',
    },
    {
      'city': 'Coimbatore',
      'area': 'RS Puram',
      'lat': 11.0089,
      'lng': 76.9535,
      'pincode': '641002',
    },
    {
      'city': 'Madurai',
      'area': 'KK Nagar',
      'lat': 9.9252,
      'lng': 78.1198,
      'pincode': '625020',
    },
    {
      'city': 'Tirunelveli',
      'area': 'Palayamkottai',
      'lat': 8.7139,
      'lng': 77.7567,
      'pincode': '627002',
    },
    {
      'city': 'Tenkasi',
      'area': 'Courtallam Road',
      'lat': 8.9594,
      'lng': 77.3160,
      'pincode': '627811',
    },
    {
      'city': 'Trichy',
      'area': 'Thillai Nagar',
      'lat': 10.8286,
      'lng': 78.6854,
      'pincode': '620018',
    },
    {
      'city': 'Salem',
      'area': 'Fairlands',
      'lat': 11.6643,
      'lng': 78.1460,
      'pincode': '636016',
    },
  ];

  /// Request live device location using Geolocator
  static Future<LiveLocationResult> getCurrentLiveLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Fallback default coordinates (Chennai / Porur)
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
      'area': closest['area'] as String,
      'city': closest['city'] as String,
      'pincode': closest['pincode'] as String,
    };
  }

  static LiveLocationResult _fallbackLocation({String? error}) {
    return LiveLocationResult(
      latitude: 13.0382,
      longitude: 80.1565,
      accuracy: 25.0,
      estimatedArea: 'Porur',
      estimatedCity: 'Chennai',
      postalCode: '600116',
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
