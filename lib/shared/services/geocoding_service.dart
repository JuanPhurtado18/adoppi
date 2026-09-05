import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  static Future<Map<String, double>?> getCoordinates(String address) async {
    try {
      // Intento 1: dirección completa
      final result = await _search(address);
      if (result != null) {
        debugPrint('DEBUG geocoding found with full address: $result');
        return result;
      }

      // Intento 2: solo la ciudad
      final cityOnly = _extractCity(address);
      if (cityOnly != null) {
        debugPrint('DEBUG geocoding trying city only: $cityOnly');
        final cityResult = await _search(cityOnly);
        if (cityResult != null) {
          debugPrint('DEBUG geocoding found with city: $cityResult');
          return cityResult;
        }
      }

      debugPrint('DEBUG geocoding: no results found for $address');
      return null;
    } catch (e) {
      debugPrint('DEBUG geocoding error: $e');
      return null;
    }
  }

  static Future<Map<String, double>?> _search(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=1',
    );

    final response = await http.get(url, headers: {'User-Agent': 'Adoppi/1.0'});

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (data.isNotEmpty) {
        return {
          'latitude': double.parse(data[0]['lat']),
          'longitude': double.parse(data[0]['lon']),
        };
      }
    }
    return null;
  }

  static String? _extractCity(String address) {
    // La dirección viene como "calle, ciudad, Colombia"
    // Extraemos desde la segunda coma en adelante
    final parts = address.split(',');
    if (parts.length >= 2) {
      return parts.sublist(parts.length - 2).join(',').trim();
    }
    return null;
  }
}
