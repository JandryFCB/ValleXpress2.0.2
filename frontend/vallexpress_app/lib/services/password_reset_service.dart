import 'dart:convert';
import 'package:http/http.dart' as http;

class PasswordResetService {
  // Ajusta tu baseUrl (si usas emulador Android: 10.0.2.2)
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<void> forgotPassword(String email) async {
    final uri = Uri.parse('$baseUrl/auth/forgot-password');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['error'] ?? 'Error solicitando código');
    }
  }

  static Future<String> verifyCode(String email, String code) async {
    final uri = Uri.parse('$baseUrl/auth/verify-reset-code');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Código inválido');
    }
    return (data['resetToken'] ?? '').toString();
  }

  static Future<void> resetPassword(
    String resetToken,
    String newPassword,
  ) async {
    final uri = Uri.parse('$baseUrl/auth/reset-password');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'resetToken': resetToken, 'newPassword': newPassword}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Error reseteando contraseña');
    }
  }
}
