import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../config/theme.dart';
import '../../config/constants.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/vendedor_service.dart';

class VendedorProfileScreen extends StatefulWidget {
  const VendedorProfileScreen({super.key});

  @override
  State<VendedorProfileScreen> createState() => _VendedorProfileScreenState();
}

class _VendedorProfileScreenState extends State<VendedorProfileScreen> {
  late final TextEditingController _nombreNegocioController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _horaAperturaController;
  late final TextEditingController _horaCierreController;

  Map<String, dynamic>? _vendedorData;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nombreNegocioController = TextEditingController();
    _descripcionController = TextEditingController();
    _categoriaController = TextEditingController();
    _horaAperturaController = TextEditingController();
    _horaCierreController = TextEditingController();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreNegocioController.dispose();
    _descripcionController.dispose();
    _categoriaController.dispose();
    _horaAperturaController.dispose();
    _horaCierreController.dispose();
    super.dispose();
  }

  // ================= PERFIL =================

  Future<void> _cargarPerfil() async {
    try {
      final datos = await VendedorService.obtenerPerfilVendedor();

      if (!mounted) return;
      setState(() {
        _vendedorData = datos;
        _nombreNegocioController.text =
            (datos['nombreNegocio'] ?? datos['nombre_negocio'] ?? '')
                .toString();
        _descripcionController.text = (datos['descripcion'] ?? '').toString();
        _categoriaController.text = (datos['categoria'] ?? '').toString();
        _horaAperturaController.text =
            (datos['horarioApertura'] ?? datos['horario_apertura'] ?? '')
                .toString();
        _horaCierreController.text =
            (datos['horarioCierre'] ?? datos['horario_cierre'] ?? '')
                .toString();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar perfil: $e');
    }
  }

  Future<void> _guardarCambios() async {
    if (_vendedorData == null) return;

    try {
      _mostrarCargando('Guardando cambios...');

      await VendedorService.actualizarPerfilVendedor(
        nombreNegocio: _nombreNegocioController.text.trim(),
        categoria: _categoriaController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        direccion: (_vendedorData!['direccion'] ?? '').toString(),
        ciudad: (_vendedorData!['ciudad'] ?? '').toString(),
        telefono: (_vendedorData!['telefono'] ?? '').toString(),
        horarioApertura: _horaAperturaController.text.trim(),
        horarioCierre: _horaCierreController.text.trim(),
        diaDescanso:
            (_vendedorData!['diaDescanso'] ??
                    (_vendedorData!['dia_descanso'] ?? 'Lunes'))
                .toString(),
      );

      if (!mounted) return;
      Navigator.pop(context);

      setState(() {
        _isEditing = false;
        _vendedorData!['nombre_negocio'] = _nombreNegocioController.text.trim();
        _vendedorData!['descripcion'] = _descripcionController.text.trim();
        _vendedorData!['categoria'] = _categoriaController.text.trim();
        _vendedorData!['horario_apertura'] = _horaAperturaController.text
            .trim();
        _vendedorData!['horario_cierre'] = _horaCierreController.text.trim();
      });

      _mostrarExito('Perfil actualizado correctamente');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _mostrarError('Error al guardar: $e');
    }
  }

  // ================= LOGO Y BANNER =================

  Future<void> _subirLogo() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      _mostrarCargando('Subiendo foto...');

      final base64 = await VendedorService.xfileToBase64(image);
      await VendedorService.actualizarLogoBase64(base64);

      if (!mounted) return;
      Navigator.pop(context);

      setState(() {
        _vendedorData!['logo'] = base64;
      });

      _mostrarExito('Foto actualizada correctamente');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _mostrarError('Error al subir foto: $e');
    }
  }

  Future<void> _subirBanner() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      _mostrarCargando('Subiendo banner...');

      final base64 = await VendedorService.xfileToBase64(image);
      await VendedorService.actualizarBannerBase64(base64);

      if (!mounted) return;
      Navigator.pop(context);

      setState(() {
        _vendedorData!['banner'] = base64;
      });

      _mostrarExito('Banner actualizado correctamente');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _mostrarError('Error al subir banner: $e');
    }
  }

  // ================= UI HELPERS =================

  void _mostrarCargando(String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  String _obtenerIniciales() {
    final usuario = _vendedorData?['usuario'];
    final nombreUsuario = usuario != null ? (usuario['nombre'] ?? '') : '';
    final negocio = (_vendedorData?['nombre_negocio'] ?? '').toString();
    final source = nombreUsuario.toString().isNotEmpty
        ? nombreUsuario.toString()
        : negocio;
    return source.isNotEmpty ? source.substring(0, 1).toUpperCase() : 'V';
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_vendedorData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Negocio'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: const Center(child: Text('No se pudo cargar el perfil')),
      );
    }

    final nombreNegocio = (_vendedorData!['nombre_negocio'] ?? '').toString();
    final calificacion = (_vendedorData!['calificacion_promedio'] ?? 0.0)
        .toString();
    final logo = (_vendedorData!['logo'] ?? '').toString();
    final banner = (_vendedorData!['banner'] ?? '').toString();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mi Negocio'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // BANNER
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                image: banner.isNotEmpty
                    ? DecorationImage(
                        image: banner.startsWith('http')
                            ? NetworkImage(banner)
                            : MemoryImage(base64Decode(banner))
                                  as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: banner.isEmpty
                  ? const Center(
                      child: Icon(Icons.store, size: 60, color: Colors.white54),
                    )
                  : null,
            ),

            Transform.translate(
              offset: const Offset(0, -40),
              child: Column(
                children: [
                  // LOGO
                  Stack(
                    children: [
                      logo.isNotEmpty
                          ? CircleAvatar(
                              radius: 60,
                              backgroundImage: logo.startsWith('http')
                                  ? NetworkImage(logo)
                                  : MemoryImage(base64Decode(logo))
                                        as ImageProvider,
                            )
                          : CircleAvatar(
                              radius: 60,
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                _obtenerIniciales(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _subirLogo,
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryColor,
                            child: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Mostrar el nombre del usuario si viene en la relación, si no, el nombre del negocio
                  Text(
                    (_vendedorData?['usuario'] != null
                            ? '${_vendedorData!['usuario']['nombre'] ?? ''} ${_vendedorData!['usuario']['apellido'] ?? ''}'
                            : nombreNegocio)
                        .trim(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        calificacion,
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'VENDEDOR',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // FORMULARIO
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _editableTile('Nombre del Negocio', _nombreNegocioController),
                  const SizedBox(height: 12),
                  _editableTile(
                    'Descripción',
                    _descripcionController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _editableTile('Categoría', _categoriaController),
                  const SizedBox(height: 12),
                  _editableTile('Hora Apertura', _horaAperturaController),
                  const SizedBox(height: 12),
                  _editableTile('Hora Cierre', _horaCierreController),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isEditing
                          ? _guardarCambios
                          : () => setState(() => _isEditing = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        _isEditing ? 'Guardar cambios' : 'Editar perfil',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ===== Ubicación del negocio =====
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ubicación del negocio',
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                            AppConstants.vendorLat,
                            AppConstants.vendorLng,
                          ),
                          initialZoom: 15,
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.pinchZoom |
                                InteractiveFlag.drag |
                                InteractiveFlag.doubleTapZoom,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.vallexpress.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  AppConstants.vendorLat,
                                  AppConstants.vendorLng,
                                ),
                                width: 54,
                                height: 54,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFDB827),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.storefront_rounded,
                                      size: 28,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editableTile(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            enabled: _isEditing,
            maxLines: maxLines,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: '-',
            ),
          ),
        ],
      ),
    );
  }
}
