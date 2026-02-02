import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:vallexpress_app/providers/auth_provider.dart';
import 'package:vallexpress_app/screens/vendedor/mis_productos_screen.dart';
import 'package:vallexpress_app/screens/vendedor/agregar_producto_screen.dart';
import 'package:vallexpress_app/screens/vendedor/vendedor_mis_pedidos_screen.dart';
import 'package:vallexpress_app/screens/cliente/cliente_mis_pedidos_screen.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../profile/cliente_profile_screen.dart';
import '../profile/vendedor_profile_screen.dart';
import '../profile/repartidor_profile_screen.dart';
import '../profile/settings_screen.dart';
import 'package:vallexpress_app/screens/cliente/cliente_productos_screen.dart';
import 'package:vallexpress_app/screens/repartidor/repartidor_pedidos_screen.dart';
import '../../providers/pedidos_provider.dart';
import 'package:vallexpress_app/widgets/map_preview.dart';
import 'package:vallexpress_app/widgets/mini_tracking_map.dart';
import 'package:vallexpress_app/screens/cliente/rastrear_pedido_screen.dart';
import 'dart:async';
import '../../services/socket_tracking_service.dart';
import '../../services/pedido_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TrackingSocketService _homeSocket = TrackingSocketService();
  StreamSubscription<Map<String, dynamic>>? _homeSub;
  LatLng? _driverLatLngHome;
  String? _joinedPedidoId;
  DateTime? _lastPedidosFetch;
  Map<String, dynamic>? _activePedidoCache;

  @override
  void dispose() {
    _homeSub?.cancel();
    _homeSocket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(context),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final tipoUsuario = authProvider.usuario?['tipoUsuario'] ?? 'cliente';

          // Mostrar contenido según el rol
          switch (tipoUsuario) {
            case 'vendedor':
              return _buildVendedorHome(context, authProvider);
            case 'repartidor':
              return _buildRepartidorHome(context, authProvider);
            case 'cliente':
            default:
              return _buildClienteHome(context, authProvider);
          }
        },
      ),
    );
  }

  // ===== HOME PARA CLIENTE =====
  Widget _buildClienteHome(BuildContext context, AuthProvider authProvider) {
    final nombre = authProvider.usuario?['nombre'] ?? 'Usuario';
    final pedidosProvider = context.watch<PedidosProvider>();

    // Cargar pedidos una sola vez al entrar (cuando aún no ha cargado nada)
    if (!pedidosProvider.loading && pedidosProvider.pedidos.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // doble-check por seguridad
        if (!pedidosProvider.loading && pedidosProvider.pedidos.isEmpty) {
          pedidosProvider.cargarMisPedidos();
        }
      });
    }

    // Si aún no hay pedido activo, forzar un refresh controlado para reflejar
    // cambios que pudieron ocurrir en otra app (repartidor).
    if (pedidosProvider.pedidoActivo == null) {
      final now = DateTime.now();
      final shouldRefresh =
          _lastPedidosFetch == null ||
          now.difference(_lastPedidosFetch!).inSeconds >= 5;
      if (shouldRefresh) {
        _lastPedidosFetch = now;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          pedidosProvider.cargarMisPedidos();
        });
      }
    }

    // Fallback: si el Provider aún no trae activo, intenta obtenerlo directo del backend
    if (pedidosProvider.pedidoActivo == null && _activePedidoCache == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final lista = await PedidoService.misPedidos();
          Map<String, dynamic>? encontrado;
          for (final p in lista) {
            if ((p['estado'] ?? '').toString() == 'en_camino') {
              encontrado = Map<String, dynamic>.from(p);
              break;
            }
          }
          if (encontrado != null) {
            if (!mounted) return;
            setState(() {
              _activePedidoCache = encontrado;
            });
          }
        } catch (_) {
          // ignorar
        }
      });
    }

    // Iniciar tracking live en Home si hay pedido activo
    final token = context.read<AuthProvider>().token;
    final ap = (pedidosProvider.pedidoActivo ?? _activePedidoCache);
    final String? apId = ap != null ? (ap['id'] as String?) : null;
    if (apId != null && token != null && _joinedPedidoId != apId) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!_homeSocket.isConnected) {
          _homeSocket.connect(baseUrl: AppConstants.socketUrl, token: token);
          await Future.delayed(const Duration(milliseconds: 600));
        }
        await _homeSocket.joinPedido(apId);

        _homeSub?.cancel();
        _homeSub = _homeSocket.locationStream.listen((data) {
          final lat = (data['lat'] as num?)?.toDouble();
          final lng = (data['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) return;
          setState(() {
            _driverLatLngHome = LatLng(lat, lng);
          });
        });

        setState(() {
          _joinedPedidoId = apId;
        });
      });
    }

    Future<void> _abrirRastreo() async {
      // 1) Usar el activo del Provider si existe
      var activo = pedidosProvider.pedidoActivo;

      // 2) Si no hay, forzar fetch inmediato para capturar cambios hechos desde la app del repartidor
      if (activo == null) {
        try {
          final lista = await PedidoService.misPedidos();
          Map<String, dynamic>? encontrado;
          for (final p in lista) {
            if ((p['estado'] ?? '').toString() == 'en_camino') {
              encontrado = Map<String, dynamic>.from(p);
              break;
            }
          }
          if (encontrado != null) {
            setState(() {
              _activePedidoCache = encontrado;
            });
            activo = encontrado;
          }
        } catch (_) {
          // Ignorar, mostraremos el SnackBar abajo
        }
      }

      if (activo == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes un pedido en camino para rastrear.'),
          ),
        );
        return;
      }

      if (!mounted) return;
      final ap2 = activo as Map<String, dynamic>;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RastrearPedidoScreen(pedidoId: ap2['id']),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenida
            _buildWelcomeCard(context, nombre, '👤 Cliente'),
            const SizedBox(height: 16),

            // Preview rastreo (solo si hay pedido en_camino)
            if ((pedidosProvider.pedidoActivo ?? _activePedidoCache) !=
                null) ...[
              Text(
                'Tu repartidor está en camino 🚴',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Mini mapa de seguimiento en tiempo real
              GestureDetector(
                onTap: _abrirRastreo,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MiniTrackingMap(
                      initialCenter:
                          _driverLatLngHome ??
                          LatLng(
                            AppConstants.vendorLat,
                            AppConstants.vendorLng,
                          ),
                      driverLocation:
                          _driverLatLngHome ??
                          LatLng(
                            AppConstants.vendorLat,
                            AppConstants.vendorLng,
                          ),
                      vendorLocation: LatLng(
                        AppConstants.vendorLat,
                        AppConstants.vendorLng,
                      ),
                      clientLocation: LatLng(
                        AppConstants.clientLat,
                        AppConstants.clientLng,
                      ),
                      animateMock: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              const SizedBox(height: 8),
            ],

            // Acciones rápidas
            Text(
              'Mis Pedidos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.add_shopping_cart,
                  title: 'Nuevo Pedido',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClienteProductosScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.list,
                  title: 'Mis Pedidos',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClienteMisPedidosScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.location_on,
                  title: 'Rastrear',
                  onTap: _abrirRastreo, // ✅ ahora sí abre la pantalla
                ),
                _buildActionCard(
                  context,
                  icon: Icons.star,
                  title: 'Calificaciones',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Estadísticas cliente
            Text(
              'Mis Estadísticas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            _buildStatsCard(
              children: [
                _buildStatItem('Pedidos Completados', '0', Icons.check_circle),
                const SizedBox(height: 16),
                _buildStatItem('Pedidos Pendientes', '0', Icons.schedule),
                const SizedBox(height: 16),
                _buildStatItem('Gasto Total', '\$0.00', Icons.payment),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== HOME PARA VENDEDOR =====
  Widget _buildVendedorHome(BuildContext context, AuthProvider authProvider) {
    final nombre = authProvider.usuario?['nombre'] ?? 'Usuario';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenida
            _buildWelcomeCard(context, nombre, '🏪 Vendedor'),
            const SizedBox(height: 24),

            // Acciones rápidas
            Text(
              'Mi Negocio',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.add_box,
                  title: 'Agregar Producto',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AgregarProductoScreen(),
                      ),
                    );
                  },
                ),

                _buildActionCard(
                  context,
                  icon: Icons.inventory,
                  title: 'Mis Productos',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MisProductosScreen(),
                      ),
                    );
                  },
                ),

                _buildActionCard(
                  context,
                  icon: Icons.shopping_bag,
                  title: 'Mis Pedidos',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VendedorMisPedidosScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.trending_up,
                  title: 'Ventas',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Estadísticas vendedor
            Text(
              'Mis Ventas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            _buildStatsCard(
              children: [
                _buildStatItem('Productos', '0', Icons.inventory_2),
                const SizedBox(height: 16),
                _buildStatItem('Ventas Hoy', '0', Icons.today),
                const SizedBox(height: 16),
                _buildStatItem('Ingresos Totales', '\$0.00', Icons.money),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== HOME PARA REPARTIDOR =====
  Widget _buildRepartidorHome(BuildContext context, AuthProvider authProvider) {
    final nombre = authProvider.usuario?['nombre'] ?? 'Usuario';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenida
            _buildWelcomeCard(context, nombre, '🚚 Repartidor'),
            const SizedBox(height: 24),

            // Acciones rápidas
            Text(
              'Mis Entregas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.local_shipping,
                  title: 'Nuevas Entregas',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RepartidorPedidosScreen(),
                      ),
                    );
                  },
                ),

                _buildActionCard(
                  context,
                  icon: Icons.map,
                  title: 'Rutas',
                  onTap: () {},
                ),
                _buildActionCard(
                  context,
                  icon: Icons.done_all,
                  title: 'Completadas',
                  onTap: () {},
                ),
                _buildActionCard(
                  context,
                  icon: Icons.payment,
                  title: 'Ganancias',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Estadísticas repartidor
            Text(
              'Mis Entregas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            _buildStatsCard(
              children: [
                _buildStatItem('Entregas Hoy', '0', Icons.today),
                const SizedBox(height: 16),
                _buildStatItem('Completadas', '0', Icons.check_circle),
                const SizedBox(height: 16),
                _buildStatItem('Ganancias Hoy', '\$0.00', Icons.attach_money),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== WIDGETS COMPARTIDOS =====

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.cardColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo.png', width: 40, height: 40),
          const SizedBox(width: 8),
          Text(
            'ValleXpress',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          color: AppTheme.cardColor,
          icon: const Icon(Icons.menu, color: AppTheme.primaryColor, size: 28),
          onSelected: (value) {
            final tipoUsuario =
                context.read<AuthProvider>().usuario?['tipoUsuario'] ??
                'cliente';
            switch (value) {
              case 'perfil':
                Widget profileScreen;
                if (tipoUsuario == 'vendedor') {
                  profileScreen = const VendedorProfileScreen();
                } else if (tipoUsuario == 'repartidor') {
                  profileScreen = RepartidorProfileScreen();
                } else {
                  profileScreen = const ClienteProfileScreen();
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => profileScreen),
                );
                break;
              case 'configuracion':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
                break;
              case 'logout':
                _showLogoutDialog(context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'perfil',
              child: Row(
                children: const [
                  Icon(Icons.person, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Mi Perfil',
                    style: TextStyle(color: AppTheme.textPrimaryColor),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'configuracion',
              child: Row(
                children: const [
                  Icon(Icons.settings, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Configuración',
                    style: TextStyle(color: AppTheme.textPrimaryColor),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: const [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String nombre, String rol) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Hola, $nombre!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Bienvenido a ValleXpress $rol',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap, // ✅ aquí se ejecuta
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(color: AppTheme.textPrimaryColor),
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(color: AppTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context);
              Navigator.of(
                context,
              ).pushReplacementNamed(AppConstants.loginRoute);
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
