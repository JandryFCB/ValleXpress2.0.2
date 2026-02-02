import 'package:flutter/material.dart';
import '../../services/pedido_service.dart';

class ClienteMisPedidosScreen extends StatefulWidget {
  const ClienteMisPedidosScreen({super.key});

  @override
  State<ClienteMisPedidosScreen> createState() =>
      _ClienteMisPedidosScreenState();
}

class _ClienteMisPedidosScreenState extends State<ClienteMisPedidosScreen> {
  List<dynamic> pedidos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await PedidoService.misPedidos();
      if (!mounted) return;
      setState(() {
        pedidos = data;
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
    return '${now.day.toString().padLeft(2, '0')} ${meses[now.month - 1]} ${now.year}';
  }

  Widget _filaTotal(String label, dynamic value, {bool bold = false}) {
    final v = (value is num)
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          '\$${v.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _mostrarDetallePedido(dynamic p) {
    final vendedor = p['vendedor'];
    final detalles = (p['detalles'] as List?) ?? [];
    final estado = (p['estado'] ?? 'pendiente').toString();
    final tienda = (vendedor?['nombreNegocio'] ?? 'Sin tienda').toString();

    final double subtotal =
        double.tryParse(p['subtotal']?.toString() ?? '') ?? 0.0;
    final double costoDelivery =
        double.tryParse(p['costoDelivery']?.toString() ?? '') ?? 0.0;
    final double total = subtotal + costoDelivery;

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
                  // HEADER (3 filas) + badge
                  Row(
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
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tienda: $tienda',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '#${p['numeroPedido'] ?? ''}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
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

                  const Text(
                    'Productos',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (detalles.isEmpty)
                    Text(
                      'Sin productos',
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    )
                  else
                    ...detalles.map((d) {
                      final producto = d['producto'];
                      final nombre = (producto?['nombre'] ?? 'Producto')
                          .toString();
                      final cantidad = (d['cantidad'] ?? 0).toString();
                      final precioU = d['precioUnitario']?.toString() ?? '0.00';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shopping_bag,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$nombre  x$cantidad',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                            Text(
                              '\$$precioU',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const Divider(color: Colors.white12),
                  const SizedBox(height: 10),

                  _filaTotal('Subtotal', subtotal),
                  _filaTotal('Delivery', costoDelivery),
                  const SizedBox(height: 6),
                  _filaTotal('Total', total, bold: true),

                  const SizedBox(height: 14),

                  if (estado == 'pendiente')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await PedidoService.cancelarPedido(p['id']);
                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pedido cancelado')),
                            );
                            _cargar();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                  if (estado == 'entregado')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await PedidoService.marcarRecibidoCliente(p['id']);
                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('¡Pedido marcado como recibido!'),
                              ),
                            );
                            _cargar();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        child: const Text('Marcar como recibido'),
                      ),
                    ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3A4A),
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Mis Pedidos',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            Text(
              _fechaHoy(),
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFDB827)),
            tooltip: 'Actualizar',
            onPressed: _cargar,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : pedidos.isEmpty
          ? const Center(child: Text('No tienes pedidos aún'))
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView.builder(
                itemCount: pedidos.length,
                itemBuilder: (_, i) {
                  final p = pedidos[i];
                  final vendedor = p['vendedor'];
                  final estado = (p['estado'] ?? 'pendiente').toString();
                  final tienda = (vendedor?['nombreNegocio'] ?? 'Sin tienda')
                      .toString();

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _mostrarDetallePedido(p),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2F3A).withOpacity(0.55),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 3 FILAS
                                  const Text(
                                    'Pedido',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tienda: $tienda',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '#${p['numeroPedido'] ?? ''}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
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
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
