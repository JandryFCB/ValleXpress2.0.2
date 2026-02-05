import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../config/theme.dart';
import '../../services/address_service.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  bool _loading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await AddressService.listar();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _createOrEdit({Map<String, dynamic>? current}) async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(
      text: (current?['nombre'] ?? '').toString(),
    );
    final direccionCtrl = TextEditingController(
      text: (current?['direccion'] ?? '').toString(),
    );
    final latCtrl = TextEditingController(
      text: (current?['latitud'] ?? '').toString(),
    );
    final lngCtrl = TextEditingController(
      text: (current?['longitud'] ?? '').toString(),
    );
    bool esPred =
        (current?['esPredeterminada'] ??
            current?['es_predeterminada'] ??
            false) ==
        true;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(current == null ? 'Nueva dirección' : 'Editar dirección'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre (opcional)',
                  ),
                ),
                TextFormField(
                  controller: direccionCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: latCtrl,
                  decoration: const InputDecoration(labelText: 'Latitud'),
                  validator: (v) => v == null || double.tryParse(v) == null
                      ? 'Num válido'
                      : null,
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: lngCtrl,
                  decoration: const InputDecoration(labelText: 'Longitud'),
                  validator: (v) => v == null || double.tryParse(v) == null
                      ? 'Num válido'
                      : null,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: esPred,
                      onChanged: (v) => setState(() {
                        esPred = v ?? false;
                      }),
                    ),
                    const Text('Marcar como predeterminada'),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                if (current == null) {
                  await AddressService.crear(
                    nombre: nombreCtrl.text.trim().isEmpty
                        ? null
                        : nombreCtrl.text.trim(),
                    direccion: direccionCtrl.text.trim(),
                    latitud: double.parse(latCtrl.text.trim()),
                    longitud: double.parse(lngCtrl.text.trim()),
                    esPredeterminada: esPred,
                  );
                } else {
                  await AddressService.actualizar(
                    (current['id'] ?? '').toString(),
                    nombre: nombreCtrl.text.trim().isEmpty
                        ? null
                        : nombreCtrl.text.trim(),
                    direccion: direccionCtrl.text.trim(),
                    latitud: double.parse(latCtrl.text.trim()),
                    longitud: double.parse(lngCtrl.text.trim()),
                    esPredeterminada: esPred,
                  );
                }
                if (!mounted) return;
                Navigator.pop(context);
                await _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _setDefault(Map<String, dynamic> item) async {
    try {
      await AddressService.marcarPredeterminada((item['id'] ?? '').toString());
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    try {
      await AddressService.eliminar((item['id'] ?? '').toString());
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mis direcciones'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Recargar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrEdit(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(
              child: Text(
                'No tienes direcciones registradas',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (_, i) {
                final it = _items[i];
                final nombre = (it['nombre'] ?? '').toString();
                final direccion = (it['direccion'] ?? '').toString();
                final lat = double.tryParse((it['latitud'] ?? '').toString());
                final lng = double.tryParse((it['longitud'] ?? '').toString());
                final pred =
                    (it['esPredeterminada'] ??
                        it['es_predeterminada'] ??
                        false) ==
                    true;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: pred
                          ? Colors.amber
                          : AppTheme.borderColor.withOpacity(0.3),
                      width: pred ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            pred ? Icons.star : Icons.place,
                            color: pred ? Colors.amber : Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              nombre.isNotEmpty ? nombre : 'Dirección',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit, color: Colors.white70),
                            onPressed: () => _createOrEdit(current: it),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _delete(it),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        direccion,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: (lat != null && lng != null)
                                  ? LatLng(lat, lng)
                                  : const LatLng(0, 0),
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
                              if (lat != null && lng != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(lat, lng),
                                      width: 46,
                                      height: 46,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0AB6FF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.place,
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
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!pred)
                            TextButton.icon(
                              onPressed: () => _setDefault(it),
                              icon: const Icon(
                                Icons.star_border,
                                color: Colors.amber,
                              ),
                              label: const Text('Marcar predeterminada'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: _items.length,
            ),
    );
  }
}
