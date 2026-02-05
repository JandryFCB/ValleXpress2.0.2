# ValleXpress - TODO de implementación y verificación (Tracking en tiempo real)

Contexto:
- Backend y sockets E2E verificados con seed y test CLI (cliente y repartidor reciben/emiten ubicaciones en room del pedido).
- En frontend (Flutter) se integró/afinó el tracking en cliente (Home + Rastrear) y UX en Repartidor (activar/desactivar tracking automático).
- Coordenadas estáticas de vendedor/cliente en AppConstants; el marcador del repartidor se mueve en vivo por socket.

Estado actual (archivos relevantes en frontend):
- lib/widgets/mini_tracking_map.dart
  - Mapa con 3 pines (Repartidor, Vendedor, Cliente).
  - Botones de zoom y refresh opcional.
  - Recibe driverLocation y actualiza en vivo.
- lib/screens/cliente/rastrear_pedido_screen.dart
  - Conecta socket con token.
  - Join al room del pedido y escucha ubicaciones; renderiza mini mapa con Vendedor/Cliente estáticos + Repartidor en vivo.
  - Selector de pedidos en_camino si hubiese múltiples.
- lib/screens/home/home_screen.dart
  - Para Cliente: mini mapa si existe pedido en_camino (desde Provider o fallback con fetch directo).
  - Join/leave y cleanup de subscripción; estado visual de socket.
- lib/screens/repartidor/repartidor_pedidos_screen.dart
  - Al aceptar pedido => activación automática del tracking y cierre del diálogo.
  - Al marcar en_camino => inicia tracking (si no estaba).
  - Al marcar entregado => detiene tracking automáticamente.
  - Botón alterna Iniciar/Detener tracking en estado en_camino.

Tareas completadas
- [x] Alinear MiniTrackingMap (flutter_map v7): initialCenter/initialZoom, 3 pines, botones, onRefresh.
- [x] RastrearPedidoScreen: flujo socket robusto, selector de pedidos en_camino, UI y estado de conexión.
- [x] HomeScreen (Cliente): preview de rastreo con join/escucha; abre RastrearPedidoScreen; mensajes de estado.
- [x] RepartidorPedidosScreen: automatizar tracking en aceptar/en_camino/entregado; cerrar modal al iniciar; botón alterna.
- [x] AppConstants con coordenadas estáticas vendor/client.

Pruebas recomendadas (ruta crítica)
1) Backend:
   - Iniciar: npm --prefix backend run dev
   - (Opcional) seed y test sockets CLI si necesitas datos de prueba:
     - node backend/src/scripts/seed_mock_data.js
     - node backend/test-socket.js --config backend/tmp/socket-test.json

2) Frontend:
   - Ejecutar Flutter (web/desktop/móvil).
   - Iniciar sesión según tu entorno (crear usuarios reales en BD o usar tus cuentas).
   - Cliente:
     - Si hay pedido en_camino, ver mini mapa en Home con 3 pines.
     - Abrir "Rastrear" y verificar que el marcador del repartidor se mueve cuando el repartidor emite.
   - Repartidor:
     - Aceptar un pedido: se inicia el tracking automáticamente y se cierra el diálogo.
     - Botón alterna Iniciar/Detener tracking en estado en_camino.
     - Al marcar "entregado" el tracking se detiene automáticamente.
   - Vendedor:
     - Sin cambios críticos; validar navegación y pedidos.

Consideraciones
- Permisos de ubicación:
  - AndroidManifest.xml y iOS Info.plist ya contemplados.
  - En dispositivo real, conceder permisos de ubicación.
- Si usas Flutter Web, mantener alturas fijas en contenedores de mapas para evitar errores tipo "Unsupported operation: -Infinity".
- Si al reconectar el socket no muestra ubicaciones, usa el botón refresh del mapa (propaga un re-join controlado).

Pendiente (futuro)
- Consolidar database/schema.sql para evitar duplicidades y alinear con modelos actuales.
- Almacenamiento persistente de última ubicación (Redis) si se requiere tolerancia a reinicios/apagados del backend.
- Tracking en background (Android/iOS) si lo solicitas (requiere permisos adicionales y estrategia de ahorro de batería).
