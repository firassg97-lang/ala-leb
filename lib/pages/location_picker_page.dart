import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
const Color primaryBlue = Color(0xFF6BB8E8);
const Color primaryPink = Color(0xFFF28BA8);
const Color backgroundLight = Color(0xFFFFFFFF);
const Color backgroundDark = Color(0xFF121212);
const Color surfaceLight = Color(0xFFF8F9FA);
const Color surfaceDark = Color(0xFF1E1E1E);
const Color cardDark = Color(0xFF2A2A2A);
const Color textPrimary = Color(0xFF1A1A2E);
const Color textSecondary = Color(0xFF6B7280);
const Color dividerColor = Color(0xFFF0F0F0);
const Color errorColor = Color(0xFFE53935);
const Color successColor = Color(0xFF43A047);
const Color warningColor = Color(0xFFFFA726);
const LinearGradient brandGradient = LinearGradient(
  colors: [primaryBlue, primaryPink],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
const LinearGradient brandGradientVertical = LinearGradient(
  colors: [primaryBlue, primaryPink],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();
  late LatLng _center;
  bool _isLoadingLocation = false;

  // Default center: Tunis
  static const _defaultCenter = LatLng(36.8065, 10.1815);

  @override
  void initState() {
    super.initState();
    _center = widget.initialLat != null && widget.initialLng != null
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : _defaultCenter;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez activer la localisation')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Permission refusée. Activez la localisation dans les paramètres.')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(latLng, 15.0);
      setState(() => _center = latLng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de localisation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir la localisation'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(_center),
            icon: const Icon(Icons.check, color: primaryBlue),
            label: const Text(
              'Confirmer',
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  setState(() => _center = camera.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.lebesty.lebesty',
              ),
            ],
          ),

          // Fixed center pin
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: primaryBlue.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2)
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child:
                        const Icon(Icons.store, color: primaryBlue, size: 28),
                  ),
                  const SizedBox(
                    width: 2,
                    height: 12,
                    child: DecoratedBox(
                        decoration: BoxDecoration(color: primaryBlue)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // "Ma position" FAB
          Positioned(
            right: 16,
            bottom: 120,
            child: FloatingActionButton.small(
              heroTag: 'my_location_fab',
              onPressed: _isLoadingLocation ? null : _goToMyLocation,
              backgroundColor: Colors.white,
              elevation: 4,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: primaryBlue),
                    )
                  : const Icon(Icons.my_location, color: primaryBlue),
            ),
          ),

          // Coordinates display bar at bottom
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_pin,
                            color: primaryBlue, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${_center.latitude.toStringAsFixed(5)}, '
                          '${_center.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Glissez la carte pour déplacer le marqueur',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
