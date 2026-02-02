import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TrackingSocketService {
  IO.Socket? _socket;

  final _locationController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get locationStream => _locationController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect({
    required String baseUrl, // ej: http://192.168.0.103:3000  (SIN /api)
    required String token,
  }) {
    // si ya existe y está conectando/conectado, no recrear
    if (_socket != null && (_socket!.connected || _socket!.active)) return;

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection() // auto-reintentos
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(20)
          .setAuth({'token': token}) // 👈 backend lee handshake.auth.token
          .build(),
    );

    _socket!.onConnect((_) => print('🟢 Socket conectado'));
    _socket!.onDisconnect((_) => print('🔴 Socket desconectado'));
    _socket!.on(
      'reconnect_attempt',
      (a) => print('… Reintentando socket ($a)'),
    );
    _socket!.on('reconnect', (_) => print('🟢 Socket reconectado'));
    _socket!.on('reconnect_error', (e) => print('❌ reconnect_error: $e'));
    _socket!.on('reconnect_failed', (_) => print('❌ reconnect_failed'));

    _socket!.on('pedido:ubicacion', (data) {
      if (data is Map) {
        _locationController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.onConnectError((e) => print('❌ connect_error: $e'));
    _socket!.onError((e) => print('❌ error: $e'));
  }

  /// Forzar reconexión si el socket quedó desconectado
  Future<void> ensureConnected() async {
    if (_socket == null) return;
    if (!(_socket!.connected)) {
      try {
        _socket!.connect();
      } catch (_) {
        // no-op
      }
    }
  }

  Future<Map<String, dynamic>> joinPedido(String pedidoId) async {
    if (_socket == null) return {'ok': false, 'error': 'SOCKET_NULL'};

    final completer = Completer<Map<String, dynamic>>();

    _socket!.emitWithAck(
      'pedido:join',
      {'pedidoId': pedidoId},
      ack: (res) {
        if (res is Map) {
          completer.complete(Map<String, dynamic>.from(res));
        } else {
          completer.complete({'ok': false, 'error': 'ACK_INVALIDO'});
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () => {'ok': false, 'error': 'TIMEOUT_JOIN'},
    );
  }

  Future<Map<String, dynamic>> sendDriverLocation({
    required String pedidoId,
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    double? accuracy,
    int? ts,
  }) async {
    if (_socket == null) return {'ok': false, 'error': 'SOCKET_NULL'};

    final payload = <String, dynamic>{
      'pedidoId': pedidoId,
      'lat': lat,
      'lng': lng,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      if (accuracy != null) 'accuracy': accuracy,
      if (ts != null) 'ts': ts,
    };

    final completer = Completer<Map<String, dynamic>>();

    _socket!.emitWithAck(
      'repartidor:ubicacion',
      payload,
      ack: (res) {
        if (res is Map) {
          completer.complete(Map<String, dynamic>.from(res));
        } else {
          completer.complete({'ok': false, 'error': 'ACK_INVALIDO'});
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () => {'ok': false, 'error': 'TIMEOUT_UBICACION'},
    );
  }

  void disconnect() {
    _socket?.disconnect();
  }

  void dispose() {
    _socket?.dispose();
    _locationController.close();
  }
}
