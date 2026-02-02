-- =====================================================
-- DATOS MOCK PARA VALLEXPRESS - BASE DE DATOS
-- =====================================================

-- LIMPIAR DATOS (opcional - comentar si necesitas mantener datos)
DELETE FROM detalle_pedidos;
DELETE FROM pedidos;
DELETE FROM productos;
DELETE FROM repartidores;
DELETE FROM vendedores;
DELETE FROM usuarios;

-- =====================================================
-- 1. INSERTAR USUARIOS
-- =====================================================

INSERT INTO usuarios (id, nombre, apellido, email, telefono, cedula, password_hash, tipo_usuario, activo, verificado, fecha_registro, created_at, updated_at) VALUES
-- Cliente
('550e8400-e29b-41d4-a716-446655440001', 'Juan', 'García', 'juan.garcia@ejemplo.com', '0987654321', '1234567890', '$2a$10$YmVyeWZvcm5hdGVkUGFzc3dvcmRIYXNoSGVyZQ==', 'cliente', true, true, NOW(), NOW(), NOW()),

-- Vendedores
('550e8400-e29b-41d4-a716-446655440002', 'Carlos', 'López', 'carlos.lopez@ejemplo.com', '0991234567', '1234567891', '$2a$10$YmVyeWZvcm5hdGVkUGFzc3dvcmRIYXNoSGVyZQ==', 'vendedor', true, true, NOW(), NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440003', 'Ana', 'Martínez', 'ana.martinez@ejemplo.com', '0992345678', '1234567892', '$2a$10$YmVyeWZvcm5hdGVkUGFzc3dvcmRIYXNoSGVyZQ==', 'vendedor', true, true, NOW(), NOW(), NOW()),

-- Repartidores
('550e8400-e29b-41d4-a716-446655440004', 'Miguel', 'Rodríguez', 'miguel.rodriguez@ejemplo.com', '0985432109', '1234567893', '$2a$10$YmVyeWZvcm5hdGVkUGFzc3dvcmRIYXNoSGVyZQ==', 'repartidor', true, true, NOW(), NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440005', 'David', 'García', 'david.garcia@ejemplo.com', '0984567890', '1234567894', '$2a$10$YmVyeWZvcm5hdGVkUGFzc3dvcmRIYXNoSGVyZQ==', 'repartidor', true, true, NOW(), NOW(), NOW());

-- =====================================================
-- 2. INSERTAR VENDEDORES
-- =====================================================

INSERT INTO vendedores (id, usuario_id, nombre_negocio, categoria, descripcion, calificacion_promedio, total_calificaciones, horario_apertura, horario_cierre, dias_atencion, tiempo_preparacion_promedio, costo_delivery, abierto_ahora, created_at, updated_at) VALUES
('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', 'Comidas Rápidas Don Carlos', 'Comida Rápida', 'Somos expertos en hamburguesas, alitas y más.', 4.8, 156, '10:00', '22:00', 'Lunes a Domingo', 25, 2.50, true, NOW(), NOW()),
('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003', 'Pizzería Italia', 'Italiana', 'Pizzas artesanales 100% italiana.', 4.9, 234, '11:00', '23:00', 'Martes a Domingo', 30, 3.00, true, NOW(), NOW());

-- =====================================================
-- 3. INSERTAR REPARTIDORES
-- =====================================================

INSERT INTO repartidores (id, usuario_id, vehiculo, placa, calificacion_promedio, total_calificaciones, disponible, latitud, longitud, pedidos_completados, created_at, updated_at) VALUES
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440004', 'Moto', 'ABC123', 4.9, 245, true, 3.5375, -76.5303, 245, NOW(), NOW()),
('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440005', 'Bicicleta', 'N/A', 4.7, 189, true, 3.5200, -76.5100, 189, NOW(), NOW());

-- =====================================================
-- 4. INSERTAR PRODUCTOS
-- =====================================================

-- Productos Don Carlos (vendedor_id = '660e8400-e29b-41d4-a716-446655440001')
INSERT INTO productos (id, vendedor_id, nombre, descripcion, precio, categoria, disponible, stock, tiempo_preparacion, created_at, updated_at) VALUES
('880e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440001', 'Hamburguesa Clásica', 'Pan tostado, carne 200g, queso, lechuga, tomate', 12.99, 'Comida', true, 50, 15, NOW(), NOW()),
('880e8400-e29b-41d4-a716-446655440002', '660e8400-e29b-41d4-a716-446655440001', 'Alitas BBQ (6 unidades)', 'Alitas marinadas en salsa BBQ casera, acompañadas de papas', 9.99, 'Comida', true, 30, 20, NOW(), NOW()),
('880e8400-e29b-41d4-a716-446655440003', '660e8400-e29b-41d4-a716-446655440001', 'Papas Rellenas', 'Papas criollas rellenas de carne molida y queso gratinado', 6.99, 'Entrada', true, 40, 10, NOW(), NOW()),
('880e8400-e29b-41d4-a716-446655440004', '660e8400-e29b-41d4-a716-446655440001', 'Refresco Natural (500ml)', 'Jugo natural de naranja, limón o piña', 2.99, 'Bebida', true, 100, 5, NOW(), NOW());

-- Productos Pizzería Italia (vendedor_id = '660e8400-e29b-41d4-a716-446655440002')
INSERT INTO productos (id, vendedor_id, nombre, descripcion, precio, categoria, disponible, stock, tiempo_preparacion, created_at, updated_at) VALUES
('880e8400-e29b-41d4-a716-446655440005', '660e8400-e29b-41d4-a716-446655440002', 'Pizza Margarita', 'Clásica pizza con tomate, mozzarella fresca y albahaca', 14.99, 'Pizza', true, 20, 25, NOW(), NOW()),
('880e8400-e29b-41d4-a716-446655440006', '660e8400-e29b-41d4-a716-446655440002', 'Pizza Pepperoni', 'Pizza con pepperoni y queso mozzarella derretido', 16.99, 'Pizza', true, 25, 25, NOW(), NOW()),
('880e8400-e29b-41d4-a716-446655440007', '660e8400-e29b-41d4-a716-446655440002', 'Pasta Carbonara', 'Pasta con salsa de huevo, queso y tocino', 11.99, 'Pasta', true, 35, 15, NOW(), NOW());

-- =====================================================
-- 5. INSERTAR PEDIDOS
-- =====================================================

-- Pedido 1: Entregado
INSERT INTO pedidos (id, numero_pedido, cliente_id, vendedor_id, repartidor_id, estado, subtotal, costo_delivery, total, metodo_pago, pagado, notas_cliente, tiempo_estimado, fecha_pedido, fecha_entrega, created_at, updated_at) VALUES
('990e8400-e29b-41d4-a716-446655440001', 'PED-123456789-001', '550e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440001', '770e8400-e29b-41d4-a716-446655440001', 'entregado', 25.98, 2.50, 28.48, 'efectivo', true, 'Sin cebolla por favor', 25, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW(), NOW());

-- Pedido 2: Entregado
INSERT INTO pedidos (id, numero_pedido, cliente_id, vendedor_id, repartidor_id, estado, subtotal, costo_delivery, total, metodo_pago, pagado, notas_cliente, tiempo_estimado, fecha_pedido, fecha_entrega, created_at, updated_at) VALUES
('990e8400-e29b-41d4-a716-446655440002', 'PED-123456789-002', '550e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440002', '770e8400-e29b-41d4-a716-446655440002', 'entregado', 31.98, 3.00, 34.98, 'tarjeta', true, 'Extra queso', 30, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW(), NOW());

-- Pedido 3: En camino
INSERT INTO pedidos (id, numero_pedido, cliente_id, vendedor_id, repartidor_id, estado, subtotal, costo_delivery, total, metodo_pago, pagado, notas_cliente, tiempo_estimado, fecha_pedido, fecha_recogida, created_at, updated_at) VALUES
('990e8400-e29b-41d4-a716-446655440003', 'PED-123456789-003', '550e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440001', '770e8400-e29b-41d4-a716-446655440001', 'en_camino', 19.98, 2.50, 22.48, 'efectivo', true, '', 20, NOW() - INTERVAL '2 hours', NOW() - INTERVAL '30 minutes', NOW(), NOW());

-- =====================================================
-- 6. INSERTAR DETALLES DE PEDIDOS
-- =====================================================

-- Detalles Pedido 1
INSERT INTO detalle_pedidos (id, pedido_id, producto_id, cantidad, precio_unitario, subtotal, created_at, updated_at) VALUES
('aa0e8400-e29b-41d4-a716-446655440001', '990e8400-e29b-41d4-a716-446655440001', '880e8400-e29b-41d4-a716-446655440001', 2, 12.99, 25.98, NOW(), NOW()),
('aa0e8400-e29b-41d4-a716-446655440002', '990e8400-e29b-41d4-a716-446655440001', '880e8400-e29b-41d4-a716-446655440004', 1, 2.99, 2.99, NOW(), NOW());

-- Detalles Pedido 2
INSERT INTO detalle_pedidos (id, pedido_id, producto_id, cantidad, precio_unitario, subtotal, created_at, updated_at) VALUES
('aa0e8400-e29b-41d4-a716-446655440003', '990e8400-e29b-41d4-a716-446655440002', '880e8400-e29b-41d4-a716-446655440005', 1, 14.99, 14.99, NOW(), NOW()),
('aa0e8400-e29b-41d4-a716-446655440004', '990e8400-e29b-41d4-a716-446655440002', '880e8400-e29b-41d4-a716-446655440006', 1, 16.99, 16.99, NOW(), NOW());

-- Detalles Pedido 3
INSERT INTO detalle_pedidos (id, pedido_id, producto_id, cantidad, precio_unitario, subtotal, created_at, updated_at) VALUES
('aa0e8400-e29b-41d4-a716-446655440005', '990e8400-e29b-41d4-a716-446655440003', '880e8400-e29b-41d4-a716-446655440002', 2, 9.99, 19.98, NOW(), NOW());

-- =====================================================
-- CONSULTAS ÚTILES PARA VERIFICAR DATOS
-- =====================================================

-- Ver todos los usuarios
-- SELECT * FROM Usuario;

-- Ver todos los vendedores
-- SELECT * FROM Vendedor;

-- Ver todos los productos
-- SELECT * FROM Producto;

-- Ver todos los repartidores
-- SELECT * FROM Repartidor;

-- Ver todos los pedidos con detalles
-- SELECT p.*, d.* FROM Pedido p LEFT JOIN DetallePedido d ON p.id = d.pedidoId;

-- Ver productos de un vendedor específico
-- SELECT * FROM Producto WHERE vendedorId = 1;

-- Ver pedidos entregados
-- SELECT * FROM Pedido WHERE estado = 'entregado';
