import 'dart:async';
import 'package:flutter/foundation.dart';
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
  final String pedidoId;

  const RastrearPedidoScreen({super.key, required this.pedidoId});

  @override
  State<RastrearPedidoScreen> createState() => _RastrearPedidoScreenState();
}

class _RastrearPedidoScreenState extends State<RastrearPedidoScreen> {
  late Future<dynamic> _pedidoFuture;

  final TrackingSocketService _socketService = TrackingSocketService();
  StreamSubscription<Map<String, dynamic>>? _sub;

  LatLng? _driverLatLng;

  List<dynamic> _enCamino = [];
  String? _selectedId;
  bool _loadingLista = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _pedidoFuture = PedidoService.obtenerPorId(widget.pedidoId);
    _selectedId = widget.pedidoId;
    _cargarPedidosEnCamino();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    if (token == null) return;

    _connectAndJoin();
  }

  Future<void> _connectAndJoin() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    if (token == null) return;

    _socketService.connect(baseUrl: AppConstants.socketUrl, token: token);
    if (kDebugMode) print('🌐 Cliente conectando socket...');

    await _socketService.ensureConnected();
    final ack = await _socketService.joinPedido(widget.pedidoId);
    if (kDebugMode) print('ACK pedido:join => $ack');
    if (kDebugMode) print('✅ Cliente join => $ack');

    _sub ??= _socketService.locationStream.listen((data) {
      if (kDebugMode) print('📥 Cliente recibe ubicacion => $data');
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat == null || lng == null || lat.isNaN || lng.isNaN) return;

      if (mounted) {
        setState(() {
          _driverLatLng = LatLng(lat, lng);
          _isConnected = true;
        });
      }
    });

    if (mounted) {
      setState(() {
        _isConnected = _socketService.isConnected;
      });
    }
  }

  Future<void> _cargarPedidosEnCamino() async {
    if (!mounted) return;
    setState(() => _loadingLista = true);
    try {
      final lista = await PedidoService.misPedidos();
      final en = lista
          .where((p) => (p['estado'] ?? '').toString() == 'en_camino')
          .toList();
      if (!mounted) return;
      setState(() {
        _enCamino = en;
        _loadingLista = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLista = false);
    }
  }

  Widget _buildSelectorPedidos() {
    if (_enCamino.length <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.25),
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFDB827).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFDB827), width: 1),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: Color(0xFFFDB827),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedId,
                isExpanded: true,
                dropdownColor: AppTheme.cardColor,
                iconEnabledColor: const Color(0xFFFDB827),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                ),
                items: _enCamino.map<DropdownMenuItem<String>>((p) {
                  final id = (p['id'] as String?) ?? '';
                  final numPed = (p['numeroPedido'] ?? '').toString();
                  final label = numPed.isNotEmpty ? '#$numPed' : id;
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null && id != widget.pedidoId) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RastrearPedidoScreen(pedidoId: id),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          if (_loadingLista) ...[
            const SizedBox(width: 8),
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFDB827),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _socketService.disconnect();
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
            onPressed: () async {
              setState(() {
                _pedidoFuture = PedidoService.obtenerPorId(widget.pedidoId);
              });
              await _connectAndJoin();
              await _cargarPedidosEnCamino();
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

                final driver =
                    _driverLatLng ??
                    LatLng(AppConstants.vendorLat, AppConstants.vendorLng);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSelectorPedidos(),
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

                        if (estado == 'en_camino') ...[
                          Text(
                            'Ubicación del repartidor',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.textPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 320,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: MiniTrackingMap(
                                initialCenter: driver,
                                clientLocation: LatLng(
                                  AppConstants.clientLat,
                                  AppConstants.clientLng,
                                ),
                                vendorLocation: LatLng(
                                  AppConstants.vendorLat,
                                  AppConstants.vendorLng,
                                ),
                                driverLocation: driver,
                                onRefresh: () async {
                                  await _connectAndJoin();
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ] else ...[
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
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFFFDB827),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No tienes un pedido en camino para rastrear.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        Text(
                          _isConnected
                              ? (_driverLatLng != null
                                    ? '🟢 Conectado. Recibiendo ubicación del repartidor.'
                                    : '🟢 Conectado. Esperando la primera ubicación…')
                              : '🔴 Desconectado. Toca recargar o verifica tu conexión.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
