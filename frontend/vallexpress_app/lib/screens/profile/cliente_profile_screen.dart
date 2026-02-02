import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../config/theme.dart';
import '../../config/constants.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/profile_service.dart';

class ClienteProfileScreen extends StatefulWidget {
  const ClienteProfileScreen({super.key});

  @override
  State<ClienteProfileScreen> createState() => _ClienteProfileScreenState();
}

class _ClienteProfileScreenState extends State<ClienteProfileScreen> {
  late final TextEditingController _telefonoController;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _telefonoController = TextEditingController();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    super.dispose();
  }

  // ================= PERFIL =================

  Future<void> _cargarPerfil() async {
    try {
      final datos = await ProfileService.obtenerPerfil();

      if (!mounted) return;
      setState(() {
        _userData = datos;
        _telefonoController.text = (datos['telefono'] ?? '').toString();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar perfil: $e');
    }
  }

  Future<void> _guardarCambios() async {
    if (_userData == null) return;

    try {
      _mostrarCargando('Guardando cambios...');

      await ProfileService.actualizarPerfil(
        nombre: (_userData!['nombre'] ?? '').toString(),
        apellido: (_userData!['apellido'] ?? '').toString(),
        telefono: _telefonoController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context); // cerrar loading

      setState(() {
        _isEditing = false;
        _userData!['telefono'] = _telefonoController.text.trim();
      });

      _mostrarExito('Perfil actualizado correctamente');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _mostrarError('Error al guardar: $e');
    }
  }

  // ================= FOTO =================

  Future<void> _subirFoto() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      _mostrarCargando('Subiendo foto...');

      final base64 = await ProfileService.xfileToBase64(image);
      await ProfileService.actualizarFotoPerfilBase64(base64);

      if (!mounted) return;
      Navigator.pop(context); // cerrar loading

      setState(() {
        _userData!['fotoPerfil'] = base64;
      });

      _mostrarExito('Foto actualizada correctamente');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _mostrarError('Error al subir foto: $e');
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
    final nombre = (_userData?['nombre'] ?? '').toString();
    final apellido = (_userData?['apellido'] ?? '').toString();

    final n = nombre.isNotEmpty ? nombre[0] : '';
    final a = apellido.isNotEmpty ? apellido[0] : '';
    return (n + a).toUpperCase();
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Perfil'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: const Center(child: Text('No se pudo cargar el perfil')),
      );
    }

    final nombre = (_userData!['nombre'] ?? '').toString();
    final apellido = (_userData!['apellido'] ?? '').toString();
    final email = (_userData!['email'] ?? '').toString();
    final cedula = (_userData!['cedula'] ?? '').toString();

    final foto = (_userData!['fotoPerfil'] ?? _userData!['foto_perfil'] ?? '')
        .toString();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // AVATAR
            Stack(
              children: [
                foto.isNotEmpty
                    ? CircleAvatar(
                        radius: 60,
                        backgroundImage: foto.startsWith('http')
                            ? NetworkImage(foto)
                            : MemoryImage(base64Decode(foto)) as ImageProvider,
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
                    onTap: _subirFoto,
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

            const SizedBox(height: 16),

            Text(
              '$nombre $apellido',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor, width: 1),
              ),
              child: const Text(
                'CLIENTE',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // INFO
            _infoTile('Email', email, enabled: false),
            const SizedBox(height: 12),
            _infoTile('Cédula', cedula, enabled: false),
            const SizedBox(height: 12),

            // Teléfono editable
            _telefonoTile(),

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
            // ===== Ubicación registrada del cliente =====
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ubicación registrada',
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
                      AppConstants.clientLat,
                      AppConstants.clientLng,
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
                            AppConstants.clientLat,
                            AppConstants.clientLng,
                          ),
                          width: 54,
                          height: 54,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF0AB6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.home_rounded,
                                size: 28,
                                color: Colors.white,
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
    );
  }

  Widget _infoTile(String label, String value, {required bool enabled}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _telefonoTile() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Teléfono',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _telefonoController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.right,
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
          ),
        ],
      ),
    );
  }
}
