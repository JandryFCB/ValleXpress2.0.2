import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../providers/auth_provider.dart';
import 'socket_tracking_service.dart';

/// Servicio singleton para emitir la ubicación del repartidor en tiempo real
/// al backend vía Socket.IO mientras un pedido está "en_camino".
class RepartidorTrackingService {
  RepartidorTrackingService._();
  static final RepartidorTrackingService instance =
      RepartidorTrackingService._();

  final TrackingSocketService _socket = TrackingSocketService();
  StreamSubscription<Position>? _sub;
  String? _pedidoIdActual;

  bool get running => _sub != null;

  Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // No forzamos abrir ajustes aquí, solo informativo vía logs
      if (kDebugMode) print('Geolocator: servicio de ubicación desactivado');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Inicia el tracking del pedido indicado.
  /// - Obtiene token de [AuthProvider]
  /// - Conecta socket y hace join al room del pedido
  /// - Envía una posición inicial (si disponible)
  /// - Se suscribe al stream del GPS y emite cada actualización
  Future<void> start(BuildContext context, String pedidoId) async {
    // Si ya estamos trackeando ese pedido, no duplicar
    if (_pedidoIdActual == pedidoId && _sub != null) return;
    _pedidoIdActual = pedidoId;

    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      if (kDebugMode) print('Tracking: token null, abortando');
      return;
    }

    final granted = await _ensurePermission();
    if (!granted) {
      if (kDebugMode) print('Tracking: permisos de ubicación no concedidos');
      return;
    }

    // Conectar socket y unirse al pedido
    _socket.connect(baseUrl: AppConstants.socketUrl, token: token);
    await Future.delayed(const Duration(milliseconds: 500));
    await _socket.joinPedido(pedidoId);

    // Enviar una posición inicial si es posible
    try {
      final init = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      await _socket.sendDriverLocation(
        pedidoId: pedidoId,
        lat: init.latitude,
        lng: init.longitude,
        accuracy: init.accuracy,
        speed: init.speed,
        heading: init.heading,
        ts: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      if (kDebugMode) print('Tracking: getCurrentPosition error: $e');
    }

    // Suscribirse a actualizaciones del GPS
    _sub?.cancel();
    _sub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5, // emitir cuando se mueva al menos 5m
          ),
        ).listen((pos) async {
          if (_pedidoIdActual != pedidoId) return;
          try {
            await _socket.sendDriverLocation(
              pedidoId: pedidoId,
              lat: pos.latitude,
              lng: pos.longitude,
              accuracy: pos.accuracy,
              speed: pos.speed,
              heading: pos.heading,
              ts: DateTime.now().millisecondsSinceEpoch,
            );
          } catch (e) {
            if (kDebugMode) print('Tracking: sendDriverLocation error: $e');
          }
        });
  }

  /// Detiene el tracking actual (si existe)
  Future<void> stop() async {
    _pedidoIdActual = null;
    await _sub?.cancel();
    _sub = null;
    // Dejamos el socket vivo por si el app lo reutiliza.
  }
}
