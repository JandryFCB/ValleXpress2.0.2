import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class AuthService {
  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al iniciar sesión');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Registro
  Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required String cedula,
    required String password,
    required String tipoUsuario,
    String? nombreNegocio,
    String? vehiculo,
    String? placa,
  }) async {
    try {
      final body = {
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'telefono': telefono,
        'cedula': cedula,
        'password': password,
        'tipoUsuario': tipoUsuario,
      };

      // Agregar campos opcionales según el tipo de usuario
      if (tipoUsuario == 'vendedor' && nombreNegocio != null) {
        body['nombreNegocio'] = nombreNegocio;
      }
      if (tipoUsuario == 'repartidor') {
        if (vehiculo != null) body['vehiculo'] = vehiculo;
        if (placa != null) body['placa'] = placa;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al registrar usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
