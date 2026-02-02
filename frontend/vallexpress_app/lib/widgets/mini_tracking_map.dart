import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MiniTrackingMap extends StatefulWidget {
  final LatLng initialCenter;

  // Ubicaciones
  final LatLng driverLocation;
  final LatLng vendorLocation;
  final LatLng clientLocation;

  // Si true, mueve el marcador del repartidor con animación mock (para demos)
  final bool animateMock;

  const MiniTrackingMap({
    super.key,
    required this.initialCenter,
    required this.driverLocation,
    required this.vendorLocation,
    required this.clientLocation,
    this.animateMock = false,
  });

  @override
  State<MiniTrackingMap> createState() => _MiniTrackingMapState();
}

class _MiniTrackingMapState extends State<MiniTrackingMap> {
  late final MapController _mapController;
  Timer? _smoothTimer;
  LatLng? _animatedDriver;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _animatedDriver = widget.driverLocation;

    // Animación suave mock (solo si se habilita)
    if (widget.animateMock) {
      _smoothTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
        final d = _animatedDriver!;
        final next = LatLng(d.latitude + 0.00005, d.longitude + 0.00005);
        setState(() => _animatedDriver = next);
      });
    }
  }

  @override
  void dispose() {
    _smoothTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MiniTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si recibimos una nueva ubicación del repartidor desde el padre (socket),
    // actualizamos el marcador inmediatamente cuando no hay animación mock.
    if (!widget.animateMock &&
        (oldWidget.driverLocation.latitude != widget.driverLocation.latitude ||
            oldWidget.driverLocation.longitude !=
                widget.driverLocation.longitude)) {
      setState(() {
        _animatedDriver = widget.driverLocation;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = _animatedDriver ?? widget.driverLocation;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags:
                    InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom,
              ),
              onMapEvent: (event) {
                // Mantener cámara actualizada (v7 lo hace internamente)
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vallexpress.app',
              ),

              // Ruta simple (línea) cliente->vendedor->cliente (mock)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      widget.clientLocation,
                      widget.vendorLocation,
                      widget.clientLocation,
                    ],
                    strokeWidth: 4,
                  ),
                ],
              ),

              MarkerLayer(
                markers: [
                  _pin(
                    point: widget.clientLocation,
                    label: "C",
                    icon: Icons.home_rounded,
                  ),
                  _pin(
                    point: widget.vendorLocation,
                    label: "V",
                    icon: Icons.storefront_rounded,
                  ),
                  _pin(
                    point: driver,
                    label: "R",
                    icon: Icons.delivery_dining_rounded,
                    isPrimary: true,
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Column(
              children: [
                _zoomButton(Icons.add, () {
                  final c = _mapController.camera.center;
                  final z = _mapController.camera.zoom;
                  _mapController.move(c, z + 1);
                }),
                const SizedBox(height: 8),
                _zoomButton(Icons.remove, () {
                  final c = _mapController.camera.center;
                  final z = _mapController.camera.zoom;
                  _mapController.move(c, z - 1);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
      ),
    );
  }

  Marker _pin({
    required LatLng point,
    required String label,
    required IconData icon,
    bool isPrimary = false,
  }) {
    return Marker(
      point: point,
      width: 54,
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFFFFC107)
              : Colors.black.withOpacity(0.85),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.25),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 28,
            color: isPrimary ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
