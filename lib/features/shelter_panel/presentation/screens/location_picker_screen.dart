import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import 'dart:math' as math;

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLon;
  final String? cityName;

  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLon,
    this.cityName,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _selectedPosition;
  late MapController _mapController;

  // Centros aproximados de ciudades colombianas
  static const _cityCenters = <String, LatLng>{
    'Cali': LatLng(3.4516, -76.5320),
    'Bogotá': LatLng(4.7110, -74.0721),
    'Medellín': LatLng(6.2442, -75.5812),
    'Barranquilla': LatLng(10.9685, -74.7813),
    'Cartagena': LatLng(10.3910, -75.4794),
    'Bucaramanga': LatLng(7.1193, -73.1227),
    'Pereira': LatLng(4.8087, -75.6906),
    'Cúcuta': LatLng(7.8939, -72.5078),
    'Santa Marta': LatLng(11.2408, -74.2110),
    'Ibagué': LatLng(4.4389, -75.2322),
    'Pasto': LatLng(1.2136, -77.2811),
    'Manizales': LatLng(5.0703, -75.5138),
    'Neiva': LatLng(2.9273, -75.2819),
    'Villavicencio': LatLng(4.1420, -73.6266),
    'Armenia': LatLng(4.5339, -75.6811),
    'Palmira': LatLng(3.5395, -76.3036),
    'Buenaventura': LatLng(3.8801, -77.0311),
    'Floridablanca': LatLng(7.0648, -73.0877),
    'Bello': LatLng(6.3397, -75.5578),
    'Itagüí': LatLng(6.1847, -75.5990),
    'Envigado': LatLng(6.1703, -75.5741),
    'Soacha': LatLng(4.5792, -74.2132),
    'Dosquebradas': LatLng(4.8370, -75.6636),
    'Tuluá': LatLng(4.0843, -76.1961),
    'Popayán': LatLng(2.4419, -76.6071),
    'Valledupar': LatLng(10.4631, -73.2532),
    'Montería': LatLng(8.7575, -75.8877),
    'Sincelejo': LatLng(9.3047, -75.3978),
    'Tunja': LatLng(5.5353, -73.3678),
    'Barrancabermeja': LatLng(7.0653, -73.8547),
    'Soledad': LatLng(10.9176, -74.7688),
    'Girón': LatLng(7.0678, -73.1682),
    'Piedecuesta': LatLng(6.9872, -73.0503),
    'Buga': LatLng(3.9003, -76.2980),
    'Cartago': LatLng(4.7455, -75.9122),
    'Sogamoso': LatLng(5.7172, -72.9356),
    'Duitama': LatLng(5.8281, -73.0297),
    'Zipaquirá': LatLng(5.0230, -74.0055),
    'Facatativá': LatLng(4.8133, -74.3552),
    'Chía': LatLng(4.8597, -74.0558),
    'Fusagasugá': LatLng(4.3372, -74.3647),
    'Riohacha': LatLng(11.5444, -72.9072),
    'Florencia': LatLng(1.6144, -75.6062),
    'Quibdó': LatLng(5.6919, -76.6583),
    'Yopal': LatLng(5.3378, -72.3959),
    'Arauca': LatLng(7.0900, -70.7619),
    'Leticia': LatLng(-4.2153, -69.9406),
    'San Andrés': LatLng(12.5567, -81.7185),
  };

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Usar coordenadas existentes o el centro de la ciudad
    if (widget.initialLat != null && widget.initialLon != null) {
      _selectedPosition = LatLng(widget.initialLat!, widget.initialLon!);
    } else if (widget.cityName != null) {
      _selectedPosition =
          _getCityCenter(widget.cityName!) ??
          const LatLng(4.7110, -74.0721); // Bogotá por defecto
    } else {
      _selectedPosition = const LatLng(4.7110, -74.0721);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng? _getCityCenter(String city) {
    final cityLower = city.toLowerCase();
    for (final entry in _cityCenters.entries) {
      if (entry.key.toLowerCase() == cityLower ||
          cityLower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Selecciona tu ubicación',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedPosition),
            child: const Text(
              'Confirmar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 15,
              onTap: (tapPosition, point) {
                setState(() => _selectedPosition = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.adoppi',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        // Calcular nueva posición basada en el desplazamiento
                        final renderBox =
                            context.findRenderObject() as RenderBox?;
                        if (renderBox == null) return;

                        final localPos = renderBox.globalToLocal(
                          details.globalPosition,
                        );
                        final point = _mapController.camera.pointToLatLng(
                          math.Point(localPos.dx, localPos.dy),
                        );
                        setState(() => _selectedPosition = point);
                      },
                      child: const Column(
                        children: [
                          Icon(
                            Icons.location_pin,
                            color: AppColors.primary,
                            size: 48,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Instrucciones
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Toca el mapa para mover el pin a tu ubicación exacta',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Coordenadas actuales
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lat: ${_selectedPosition.latitude.toStringAsFixed(6)}, '
                      'Lon: ${_selectedPosition.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
