import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/pedido_service.dart';
import '../../services/socket_tracking_service.dart';
import '../../widgets/mini_tracking_map.dart';

class RastrearPedidoScreen extends StatefulWidget {
  final String pedidoId; // ⚠️ debe ser el UUID real del pedido (PK)

  const RastrearPedidoScreen({super.key, required this.pedidoId});

  @override
  State<RastrearPedidoScreen> createState() => _RastrearPedidoScreenState();
}

class _RastrearPedidoScreenState extends State<RastrearPedidoScreen> {
  late Future<dynamic> _pedidoFuture;

  final TrackingSocketService _socketService = TrackingSocketService();
  StreamSubscription<Map<String, dynamic>>? _sub;

  // Para mover el marcador del repartidor
  LatLng? _driverLatLng;

  @override
  void initState() {
    super.initState();
    _pedidoFuture = PedidoService.obtenerPorId(widget.pedidoId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Aquí SÍ ya puedes leer Provider seguro
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    if (token == null) return;

    // Conectar socket (una sola vez)
    if (!_socketService.isConnected) {
      _socketService.connect(baseUrl: AppConstants.socketUrl, token: token);

      // unirse al room del pedido
      Future.delayed(const Duration(milliseconds: 700), () async {
        final ack = await _socketService.joinPedido(widget.pedidoId);
        print('ACK pedido:join => $ack');
      });

      // escuchar ubicaciones
      _sub = _socketService.locationStream.listen((data) {
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return;

        setState(() {
          _driverLatLng = LatLng(lat, lng);
        });
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _socketService.dispose();
    super.dispose();
  }

  String _estadoTexto(String estado) {
    const mapa = {
      'pendiente': 'Pendiente',
      'confirmado': 'Confirmado',
      'preparando': 'Preparando',
      'listo': 'Listo',
      'en_camino': 'En camino',
      'entregado': 'Entregado',
      'recibido_cliente': 'Recibido',
      'cancelado': 'Cancelado',
    };
    return mapa[estado] ?? estado.replaceAll('_', ' ');
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFF8E9AAF);
      case 'confirmado':
        return const Color(0xFF2D6A9F);
      case 'preparando':
        return const Color(0xFFB08900);
      case 'listo':
        return const Color(0xFF2E7D32);
      case 'en_camino':
        return const Color(0xFF1565C0);
      case 'entregado':
      case 'recibido_cliente':
        return const Color(0xFF2E7D32);
      case 'cancelado':
        return const Color(0xFFD32F2F);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final token = authProvider.token;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3A4A),
        elevation: 0,
        title: const Text(
          'Rastrear pedido',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh, color: Color(0xFFFDB827)),
            onPressed: () {
              setState(() {
                _pedidoFuture = PedidoService.obtenerPorId(widget.pedidoId);
              });
            },
          ),
        ],
      ),
      body: token == null
          ? _buildError('No hay sesión activa (token null).')
          : FutureBuilder<dynamic>(
              future: _pedidoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pedido = snapshot.data;
                final estado = (pedido?['estado'] ?? 'en_camino').toString();
                final numeroPedido = (pedido?['numeroPedido'] ?? '').toString();
                final vendedor = pedido?['vendedor'];
                final tienda = (vendedor?['nombreNegocio'] ?? '').toString();

                // Si todavía no hay ubicación real, usamos un fallback
                final driver =
                    _driverLatLng ??
                    LatLng(AppConstants.vendorLat, AppConstants.vendorLng);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.borderColor.withOpacity(0.25),
                              width: 1.3,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.local_shipping,
                                color: Color(0xFFFDB827),
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      numeroPedido.isNotEmpty
                                          ? '#$numeroPedido'
                                          : 'Pedido',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    if (tienda.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tienda: $tienda',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.75),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: _estadoColor(estado),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  _estadoTexto(estado),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Ubicación del repartidor',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.textPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),

                        const SizedBox(height: 12),

                        // FlutterMap requiere constraints finitos en Web; envolver con SizedBox.
                        SizedBox(
                          height: 320,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: MiniTrackingMap(
                              initialCenter: driver,
                              // luego conectamos cliente/vendedor reales, por ahora placeholders
                              clientLocation: LatLng(
                                AppConstants.clientLat,
                                AppConstants.clientLng,
                              ),
                              vendorLocation: LatLng(
                                AppConstants.vendorLat,
                                AppConstants.vendorLng,
                              ),
                              driverLocation:
                                  driver, // 👈 ESTE se mueve en vivo
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          _socketService.isConnected
                              ? '🟢 Conectado. Esperando ubicación del repartidor...'
                              : '🔴 Socket no conectado (revisa IP/token).',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
