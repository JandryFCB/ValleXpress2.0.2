-- =====================================================
-- Insertar datos para usuarios existentes en la BD
-- =====================================================

-- VENDEDOR: jandry1@gmail.com (id: 412eeb98-2075-4df1-a961-58aff9ade5f5)
INSERT INTO "public"."vendedores" 
("id", "usuario_id", "nombre_negocio", "descripcion", "logo", "banner", "categoria", 
 "calificacion_promedio", "total_calificaciones", "direccion_id", "horario_apertura", 
 "horario_cierre", "dias_atencion", "tiempo_preparacion_promedio", "costo_delivery", 
 "radio_cobertura", "abierto_ahora", "created_at", "updated_at")
VALUES 
('550e8400-e29b-41d4-a716-446655440001', '412eeb98-2075-4df1-a961-58aff9ade5f5', 
 'Jandry Foods', 'Comidas deliciosas y rápidas', NULL, NULL, 'Comida Rápida',
 4.5, 12, NULL, '10:00', '22:00', 'Lunes,Martes,Miércoles,Jueves,Viernes,Sábado,Domingo', 
 20, 2.50, 5, true, NOW(), NOW());

-- REPARTIDOR: jandry2@gmail.com (id: 89fb2f9a-9319-45ac-8045-b97e2250cfe6)
INSERT INTO "public"."repartidores" 
("id", "usuario_id", "vehiculo", "placa", "licencia", "calificacion_promedio", 
 "total_calificaciones", "disponible", "ultima_ubicacion_lat", "ultima_ubicacion_lng", 
 "pedidos_completados", "created_at", "updated_at")
VALUES 
('550e8400-e29b-41d4-a716-446655440002', '89fb2f9a-9319-45ac-8045-b97e2250cfe6',
 'Moto', 'ABC-123', 'LIC123456', 4.8, 25, true, 3.5375, -76.5303, 45, NOW(), NOW());

-- =====================================================
-- Verificar datos insertados
-- =====================================================
-- SELECT * FROM vendedores WHERE usuario_id = '412eeb98-2075-4df1-a961-58aff9ade5f5';
-- SELECT * FROM repartidores WHERE usuario_id = '89fb2f9a-9319-45ac-8045-b97e2250cfe6';
