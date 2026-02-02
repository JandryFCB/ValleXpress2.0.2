import 'package:flutter/material.dart';
import '../../services/vendedor_pedidos_service.dart';

class VendedorMisPedidosScreen extends StatefulWidget {
  const VendedorMisPedidosScreen({super.key});

  @override
  State<VendedorMisPedidosScreen> createState() =>
      _VendedorMisPedidosScreenState();
}

class _VendedorMisPedidosScreenState extends State<VendedorMisPedidosScreen> {
  List<dynamic> pedidos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await VendedorPedidosService.misPedidos();
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
        return const Color(0xFF8E9AAF); // gris azulado
      case 'confirmado':
        return const Color(0xFF2D6A9F); // azul elegante
      case 'preparando':
        return const Color(0xFFB08900); // dorado suave
      case 'listo':
        return const Color(0xFF2E7D32); // verde
      case 'en_camino':
        return const Color(0xFF1565C0); // azul fuerte
      case 'entregado':
      case 'recibido_cliente':
        return const Color(0xFF2E7D32); // verde (finalizado)
      case 'cancelado':
        return const Color(0xFFD32F2F); // rojo
      default:
        return Colors.grey;
    }
  }

  Future<void> _cambiarEstado(dynamic pedido, String nuevoEstado) async {
    try {
      await VendedorPedidosService.actualizarEstado(
        pedidoId: pedido['id'],
        estado: nuevoEstado,
      );

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

  void _mostrarDetallePedido(BuildContext context, dynamic p) {
    final cliente = p['cliente'];
    final detalles = (p['detalles'] as List?) ?? [];
    final estado = (p['estado'] ?? 'pendiente').toString();

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
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),

                            const SizedBox(height: 4),
                            Text(
                              '#${p['numeroPedido']}',
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
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _getEstadoColor(estado).withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
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

                  const SizedBox(height: 16),

                  // Cliente (más grande, como pediste)
                  Text(
                    'Cliente: ${cliente?['nombre']} ${cliente?['apellido'] ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Contacto: ${cliente?['telefono'] ?? 'N/A'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12),

                  // Productos
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
                                '${producto?['nombre']} x${d['cantidad']}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                            Text(
                              '\$${d['precioUnitario']}',
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

                  // Totales (más claro)
                  _filaTotal('Subtotal', p['subtotal']),
                  _filaTotal('Delivery', p['costoDelivery']),
                  const SizedBox(height: 6),
                  _filaTotal('Total', p['total'], bold: true),

                  const SizedBox(height: 18),

                  // ✅ Acciones del vendedor (CAMBIO DE ESTADO)
                  if (estado == 'pendiente')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // cierra el dialog
                          await _cambiarEstado(p, 'confirmado');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDB827),
                          foregroundColor: const Color(0xFF0B1F26),
                        ),
                        child: const Text(
                          'Confirmar pedido',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    )
                  else if (estado == 'confirmado')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _cambiarEstado(p, 'preparando');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDB827),
                          foregroundColor: const Color(0xFF0B1F26),
                        ),
                        child: const Text(
                          'Marcar como preparando',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    )
                  else if (estado == 'preparando')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _cambiarEstado(p, 'listo');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDB827),
                          foregroundColor: const Color(0xFF0B1F26),
                        ),
                        child: const Text(
                          'Marcar como listo',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Cerrar
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

  Widget _filaTotal(String label, dynamic value, {bool bold = false}) {
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
          '\$${value ?? '0.00'}',
          style: TextStyle(
            color: Colors.white,
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
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
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFFFDB827), // amarillo del theme
            ),
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
                  final cliente = p['cliente'];
                  final detalles = p['detalles'] as List?;
                  final estado = (p['estado'] ?? 'pendiente').toString();

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _mostrarDetallePedido(context, p),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0F2F3A,
                          ).withOpacity(0.55), // similar a tu UI
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
                                  // 1️⃣ PEDIDO (GRANDE)
                                  const Text(
                                    'Pedido',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22, // GRANDE
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // 2️⃣ CLIENTE (MEDIANO)
                                  Text(
                                    'Cliente: ${cliente?['nombre']} ${cliente?['apellido'] ?? ''}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16, // MEDIANO
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // 3️⃣ #PED (PEQUEÑO)
                                  Text(
                                    '#${p['numeroPedido']}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 13, // PEQUEÑO
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // BADGE
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
