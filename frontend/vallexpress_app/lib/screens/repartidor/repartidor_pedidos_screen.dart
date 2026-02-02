import 'package:flutter/material.dart';
import '../../services/repartidor_pedidos_service.dart';
import '../../services/repartidor_tracking_service.dart';

class RepartidorPedidosScreen extends StatefulWidget {
  const RepartidorPedidosScreen({super.key});

  @override
  State<RepartidorPedidosScreen> createState() =>
      _RepartidorPedidosScreenState();
}

class _RepartidorPedidosScreenState extends State<RepartidorPedidosScreen> {
  List<dynamic> pedidosAsignados = [];
  List<dynamic> pedidosPendientes = [];
  List<dynamic> pedidosVista = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final asignados = await RepartidorPedidosService.obtenerPedidos();
      final pendientes =
          await RepartidorPedidosService.obtenerPedidosPendientes();
      final vista = await RepartidorPedidosService.obtenerPedidosVista();
      if (!mounted) return;
      setState(() {
        pedidosAsignados = asignados;
        pedidosPendientes = pendientes;
        pedidosVista = vista;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _getEstadoTexto(String estado) {
    final mapa = {
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

  Color _getEstadoColor(String estado) {
    // Colores más “bonitos” como lo pediste (similar a vendedor/cliente)
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

  Future<void> _cambiarEstado(dynamic pedido, String nuevoEstado) async {
    try {
      await RepartidorPedidosService.cambiarEstado(pedido['id'], nuevoEstado);

      // Iniciar/Detener tracking según estado
      if (nuevoEstado == 'en_camino') {
        await RepartidorTrackingService.instance.start(context, pedido['id']);
      } else if (nuevoEstado == 'entregado') {
        await RepartidorTrackingService.instance.stop();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido marcado como $nuevoEstado')),
      );

      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // =========================
  // UI helpers
  // =========================
  static const _bg = Color(0xFF0A2A3A);
  static const _card = Color(0xFF133B4F);
  static const _yellow = Color(0xFFFDB827);

  String _fechaHoy() {
    final now = DateTime.now();
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${now.day.toString().padLeft(2, '0')} '
        '${meses[now.month - 1]} '
        '${now.year}';
  }

  String _money(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '0') ?? 0.0;
    return d.toStringAsFixed(2);
  }

  // =========================
  // Dialog: Detalle
  // =========================
  void _mostrarDetallesPedido(dynamic pedido, String tipo) {
    final estado = (pedido['estado'] ?? '').toString();
    final numeroPedido =
        (pedido['numeroPedido'] ?? pedido['numero_pedido'] ?? pedido['id'])
            ?.toString() ??
        '';
    final total = pedido['total'];
    final subtotal = pedido['subtotal'];
    final delivery = pedido['costoDelivery'];
    final direccion = pedido['direccion_entrega']?.toString();
    final notas = pedido['notas']?.toString();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: const Color(0xFF0B1F26),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pedido',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '#$numeroPedido',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getEstadoColor(estado),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getEstadoTexto(estado),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12),

                  // Info básica
                  Text(
                    'Total: \$${_money(total)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (tipo == 'asignados') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Subtotal: \$${_money(subtotal)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Delivery: \$${_money(delivery)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],

                  if (direccion != null && direccion.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Dirección: $direccion',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],

                  if (notas != null && notas.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Notas: $notas',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ✅ Acciones según TAB
                  if (tipo == 'pendientes') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _aceptarPedido(pedido);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _yellow,
                          foregroundColor: const Color(0xFF0B1F26),
                        ),
                        child: const Text(
                          'Aceptar pedido',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ] else if (tipo == 'asignados') ...[
                    if (estado == 'listo') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _cambiarEstado(pedido, 'en_camino');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _yellow,
                            foregroundColor: const Color(0xFF0B1F26),
                          ),
                          child: const Text(
                            'Marcar en camino',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else if (estado == 'en_camino') ...[
                      // Botón para iniciar/reenviar tracking de ubicación
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final running =
                                  RepartidorTrackingService.instance.running;
                              if (running) {
                                await RepartidorTrackingService.instance.stop();
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Tracking detenido'),
                                  ),
                                );
                                setState(() {});
                              } else {
                                // Cerrar el diálogo y activar tracking
                                Navigator.pop(context);
                                await RepartidorTrackingService.instance.start(
                                  context,
                                  pedido['id'],
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Tracking de ubicación activo',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0B1F26),
                          ),
                          child: Text(
                            RepartidorTrackingService.instance.running
                                ? 'Detener tracking'
                                : 'Iniciar tracking',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _cambiarEstado(pedido, 'entregado');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _yellow,
                            foregroundColor: const Color(0xFF0B1F26),
                          ),
                          child: const Text(
                            'Marcar como entregado',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],

                  // Cerrar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _yellow,
                        foregroundColor: const Color(0xFF0B1F26),
                      ),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================
  // Dialog: Aceptar pedido (costo delivery)
  // =========================
  Future<void> _aceptarPedido(dynamic pedido) async {
    final costoController = TextEditingController();

    final result = await showDialog<double>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: const Color(0xFF0B1F26),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aceptar pedido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: costoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Costo de delivery',
                    prefixText: '\$ ',
                    filled: true,
                    fillColor: _card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _yellow, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _yellow.withOpacity(0.55),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _yellow, width: 1.8),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(color: _yellow.withOpacity(0.9)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final costo = double.tryParse(
                            costoController.text.trim().replaceAll(',', '.'),
                          );
                          if (costo != null && costo >= 0) {
                            Navigator.pop(context, costo);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _yellow,
                          foregroundColor: const Color(0xFF0B1F26),
                        ),
                        child: const Text(
                          'Aceptar',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return;

    try {
      await RepartidorPedidosService.aceptarPedido(pedido['id'], result);
      // Activar tracking automáticamente al aceptar
      await RepartidorTrackingService.instance.start(context, pedido['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido aceptado. Tracking activado')),
      );
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // =========================
  // Lista UI bonita
  // =========================
  Widget _buildPedidosList(List<dynamic> pedidos, String tipo) {
    if (pedidos.isEmpty) {
      return const Center(
        child: Text('No hay pedidos', style: TextStyle(color: Colors.white70)),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: pedidos.length,
        itemBuilder: (_, i) {
          final pedido = pedidos[i];
          final estado = (pedido['estado'] ?? '').toString();

          // ✅ usar numeroPedido (fallback por seguridad)
          final numeroPedido =
              (pedido['numeroPedido'] ??
                      pedido['numero_pedido'] ??
                      pedido['id'])
                  .toString();

          // total mostrado
          final total = (tipo == 'asignados')
              ? ((double.tryParse(pedido['subtotal']?.toString() ?? '0') ?? 0) +
                    (double.tryParse(
                          pedido['costoDelivery']?.toString() ?? '0',
                        ) ??
                        0))
              : (double.tryParse(pedido['total']?.toString() ?? '0') ?? 0);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _mostrarDetallesPedido(pedido, tipo),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _card.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pedido',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // 🔥 AQUÍ YA NO SALE EL UUID
                          Text(
                            '#$numeroPedido',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 6),
                          Text(
                            'Estado: ${_getEstadoTexto(estado)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Total: \$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF7CFF7C),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(estado),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3A4A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pedidos repartidor',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              _fechaHoy(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh, color: _yellow),
            tooltip: 'Actualizar',
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: _yellow,
                    labelColor: _yellow,
                    unselectedLabelColor: Colors.white70,
                    tabs: [
                      Tab(text: 'Nuevas entregas'),
                      Tab(text: 'Pedidos disponibles'),
                      Tab(text: 'Mis pedidos'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildPedidosList(pedidosPendientes, 'pendientes'),
                        _buildPedidosList(pedidosVista, 'disponibles'),
                        _buildPedidosList(pedidosAsignados, 'asignados'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
