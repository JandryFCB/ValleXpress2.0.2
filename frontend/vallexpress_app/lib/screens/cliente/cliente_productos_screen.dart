import '../../config/theme.dart';
import 'package:flutter/material.dart';
import 'package:vallexpress_app/services/product_service.dart';
import 'package:vallexpress_app/services/pedido_service.dart';

class ClienteProductosScreen extends StatefulWidget {
  const ClienteProductosScreen({super.key});

  @override
  State<ClienteProductosScreen> createState() => _ClienteProductosScreenState();
}

class _ClienteProductosScreenState extends State<ClienteProductosScreen> {
  List<dynamic> productos = [];
  bool loading = true;
  Map<String, int> carrito = {}; // productId -> cantidad

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Map<String, List<dynamic>> _agruparPorTienda(List<dynamic> productos) {
    final map = <String, List<dynamic>>{};
    for (final p in productos) {
      final vendedor = p['vendedor'];
      final tienda = (vendedor?['nombreNegocio'] ?? 'Sin tienda').toString();
      map.putIfAbsent(tienda, () => []);
      map[tienda]!.add(p);
    }
    return map;
  }

  String? _getVendedorIdDeProducto(dynamic producto) {
    final vendedor = producto['vendedor'];
    if (vendedor is Map) {
      return vendedor['id']?.toString();
    }
    return null;
  }

  Future<void> _cargar() async {
    try {
      final data = await ProductService.listarProductosPublicos();
      if (!mounted) return;
      setState(() {
        productos = data;
        loading = false;
      });
    } catch (e) {
      debugPrint('ERROR CLIENTE PRODUCTOS: $e');
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _agregarAlCarrito(dynamic producto) {
    setState(() {
      final id = producto['id'].toString();
      carrito[id] = (carrito[id] ?? 0) + 1;
    });
  }

  void _removerDelCarrito(dynamic producto) {
    setState(() {
      final id = producto['id'].toString();
      if (carrito.containsKey(id) && carrito[id]! > 0) {
        carrito[id] = carrito[id]! - 1;
        if (carrito[id] == 0) {
          carrito.remove(id);
        }
      }
    });
  }

  Future<void> _hacerPedido() async {
    if (carrito.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Carrito vacío')));
      return;
    }

    // Agrupar productos por vendedor
    final productosPorVendedor = <String, List<Map<String, dynamic>>>{};

    for (final id in carrito.keys) {
      final producto = productos.firstWhere((p) => p['id'].toString() == id);
      final vendedorId = _getVendedorIdDeProducto(producto);

      if (vendedorId == null) continue;

      productosPorVendedor.putIfAbsent(vendedorId, () => []);
      productosPorVendedor[vendedorId]!.add({
        'productoId': id,
        'cantidad': carrito[id],
      });
    }

    // Crear pedido para cada vendedor
    try {
      for (final vendedorId in productosPorVendedor.keys) {
        await PedidoService.crearPedido(
          vendedorId: vendedorId,
          productos: productosPorVendedor[vendedorId]!,
          metodoPago: 'efectivo',
          notasCliente: '',
        );
      }

      if (!mounted) return;

      setState(() => carrito.clear());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Pedidos creados exitosamente!')),
      );

      // Volver a pantalla anterior
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _badgeCantidad(int cantidad) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.35)),
      ),
      child: Text(
        'x$cantidad',
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _btnCircle(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final grupos = _agruparPorTienda(productos);
    final tiendas = grupos.keys.toList();

    double totalGastado = 0.0;
    carrito.forEach((id, cantidad) {
      final producto = productos.firstWhere(
        (p) => p['id'].toString() == id,
        orElse: () => null,
      );
      if (producto != null && producto['precio'] != null) {
        totalGastado +=
            (double.tryParse(producto['precio'].toString()) ?? 0) * cantidad;
      }
    });
    final totalCarrito = carrito.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Productos'),
        elevation: 0,
        backgroundColor: const Color(0xFF0F2F3A),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargar,
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: tiendas.length,
              itemBuilder: (_, i) {
                final tienda = tiendas[i];
                final items = grupos[tienda]!;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título tienda
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          tienda,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Productos
                      ...items.map((p) {
                        final id = p['id'].toString();
                        final cantidad = carrito[id] ?? 0;
                        final disponible = (p['disponible'] == true);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F2F3A).withOpacity(0.60),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icono izq
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.shopping_bag,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (p['nombre'] ?? 'Producto').toString(),
                                      style: TextStyle(
                                        color: disponible
                                            ? Colors.white
                                            : Colors.white38,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${p['precio']}',
                                      style: TextStyle(
                                        color: disponible
                                            ? const Color(0xFF52FF7A)
                                            : Colors.white38,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '⏱ ${p['tiempoPreparacion'] ?? 0} min preparación',
                                      style: TextStyle(
                                        color: disponible
                                            ? AppTheme.primaryColor
                                            : Colors.white38,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (!disponible) ...[
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Producto no disponible',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                    if (cantidad > 0) ...[
                                      const SizedBox(height: 8),
                                      _badgeCantidad(cantidad),
                                    ],
                                  ],
                                ),
                              ),

                              // Botones + / -
                              Column(
                                children: [
                                  _btnCircle(
                                    Icons.add,
                                    disponible
                                        ? () => _agregarAlCarrito(p)
                                        : null,
                                  ),
                                  const SizedBox(height: 10),
                                  if (cantidad > 0)
                                    _btnCircle(
                                      Icons.remove,
                                      () => _removerDelCarrito(p),
                                    )
                                  else
                                    const SizedBox(height: 30),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),

      // Barra inferior (igual a tu look)
      bottomNavigationBar: totalCarrito > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2F3A),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.06)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalCarrito producto${totalCarrito != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total: \$${totalGastado.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF52FF7A),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _hacerPedido,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.backgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Pedir ahora',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
