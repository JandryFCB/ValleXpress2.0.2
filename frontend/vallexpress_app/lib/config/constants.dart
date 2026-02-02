class AppConstants {
  // API URL
  // static const String baseUrl =
  //   'http://172.17.240.1:3000/api'; // Para emulador Android
  static const String baseUrl =
      'http://192.168.0.103:3000/api'; // Para web/desktop
  static const String socketUrl = 'http://192.168.0.103:3000';

  // static const String baseUrl = 'http://172.17.240.1:3000/api'; // Para dispositivo físico

  // Storage keys
  static const String tokenKey = 'token';
  static const String userKey = 'user';

  // Rutas
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  // Opcional: si luego haces endpoints de imágenes o uploads
  static const String uploadsUrl = '$baseUrl/uploads';

  // Default coordinates (approx) for Yantzaza, Zamora Chinchipe
  // Adjust these when backend provides real coordinates.
  static const double vendorLat = -3.8320;
  static const double vendorLng = -78.7590;
  static const double clientLat = -3.8345;
  static const double clientLng = -78.7645;
}
