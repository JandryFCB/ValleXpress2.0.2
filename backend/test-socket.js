const { io } = require("socket.io-client");

// ===== CONFIG =====
const URL = "http://localhost:3000";

// Pon aquí un token de CLIENTE (dueño del pedido) para escuchar
const TOKEN_CLIENTE = "PEGA_AQUI_TOKEN_CLIENTE";

// Pon aquí un token de REPARTIDOR (asignado al pedido) para emitir ubicación
const TOKEN_REPARTIDOR = "PEGA_AQUI_TOKEN_REPARTIDOR";

// ID del pedido real (el mismo para ambos)
const PEDIDO_ID = 1; // <-- cambia esto

// =====================
// SOCKET CLIENTE (escucha)
// =====================
const cliente = io(URL, {
  auth: { token: TOKEN_CLIENTE },
  transports: ["websocket"],
});

cliente.on("connect", () => {
  console.log("✅ CLIENTE conectado:", cliente.id);

  cliente.emit("pedido:join", { pedidoId: PEDIDO_ID }, (ack) => {
    console.log("CLIENTE join ack:", ack);
  });
});

cliente.on("pedido:ubicacion", (data) => {
  console.log("📍 CLIENTE recibe ubicacion:", data);
});

cliente.on("connect_error", (e) => {
  console.log("❌ CLIENTE connect_error:", e.message);
});

// =====================
// SOCKET REPARTIDOR (emite)
// =====================
const repartidor = io(URL, {
  auth: { token: TOKEN_REPARTIDOR },
  transports: ["websocket"],
});

repartidor.on("connect", () => {
  console.log("✅ REPARTIDOR conectado:", repartidor.id);

  repartidor.emit("pedido:join", { pedidoId: PEDIDO_ID }, (ack) => {
    console.log("REPARTIDOR join ack:", ack);
  });

  // Simular ubicación cada 3s (respeta tu anti-spam de 2s)
  setInterval(() => {
    repartidor.emit(
      "repartidor:ubicacion",
      {
        pedidoId: PEDIDO_ID,
        lat: -3.9931,
        lng: -79.2042,
        heading: 90,
        speed: 5,
        accuracy: 10,
      },
      (ack) => {
        console.log("REPARTIDOR ubic ack:", ack);
      }
    );
  }, 3000);
});

repartidor.on("connect_error", (e) => {
  console.log("❌ REPARTIDOR connect_error:", e.message);
});
