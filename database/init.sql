-- Crear extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
--CREATE EXTENSION IF NOT EXISTS "postgis";

-- Tabla de Usuarios (base para todos los tipos)
CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    tipo_usuario VARCHAR(20) CHECK (tipo_usuario IN ('cliente', 'vendedor', 'repartidor')),
    foto_perfil TEXT,
    activo BOOLEAN DEFAULT true,
    verificado BOOLEAN DEFAULT false,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultima_conexion TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Direcciones
CREATE TABLE direcciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    alias VARCHAR(50),
    direccion_completa TEXT NOT NULL,
    referencias TEXT,
    latitud DECIMAL(10, 8) NOT NULL,
    longitud DECIMAL(11, 8) NOT NULL,
    --ubicacion GEOGRAPHY(POINT, 4326),
    es_principal BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Vendedores (negocios)
CREATE TABLE vendedores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre_negocio VARCHAR(200) NOT NULL,
    descripcion TEXT,
    logo TEXT,
    banner TEXT,
    categoria VARCHAR(50),
    calificacion_promedio DECIMAL(3, 2) DEFAULT 0.00,
    total_calificaciones INTEGER DEFAULT 0,
    direccion_id UUID REFERENCES direcciones(id),
    horario_apertura TIME,
    horario_cierre TIME,
    dias_atencion VARCHAR(100),
    tiempo_preparacion_promedio INTEGER, -- en minutos
    costo_delivery DECIMAL(10, 2),
    radio_cobertura INTEGER, -- en kilómetros
    abierto_ahora BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Productos
CREATE TABLE productos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendedor_id UUID REFERENCES vendedores(id) ON DELETE CASCADE,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10, 2) NOT NULL,
    imagen TEXT,
    categoria VARCHAR(50),
    disponible BOOLEAN DEFAULT true,
    tiempo_preparacion INTEGER, -- en minutos
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Repartidores
CREATE TABLE repartidores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    vehiculo VARCHAR(50),
    placa VARCHAR(20),
    licencia VARCHAR(50),
    calificacion_promedio DECIMAL(3, 2) DEFAULT 0.00,
    total_calificaciones INTEGER DEFAULT 0,
    disponible BOOLEAN DEFAULT false,
    --ubicacion_actual GEOGRAPHY(POINT, 4326),
    ultima_ubicacion_lat DECIMAL(10, 8),
    ultima_ubicacion_lng DECIMAL(11, 8),
    pedidos_completados INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Pedidos
CREATE TABLE pedidos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numero_pedido VARCHAR(20) UNIQUE NOT NULL,
    cliente_id UUID REFERENCES usuarios(id),
    vendedor_id UUID REFERENCES vendedores(id),
    repartidor_id UUID REFERENCES repartidores(id),
    direccion_entrega_id UUID REFERENCES direcciones(id),
    estado VARCHAR(50) CHECK (estado IN ('pendiente', 'confirmado', 'preparando', 'listo', 'en_camino', 'entregado', 'cancelado')),
    subtotal DECIMAL(10, 2) NOT NULL,
    costo_delivery DECIMAL(10, 2) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    metodo_pago VARCHAR(50),
    pagado BOOLEAN DEFAULT false,
    paypal_order_id VARCHAR(100),
    notas_cliente TEXT,
    tiempo_estimado INTEGER, -- en minutos
    fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_confirmacion TIMESTAMP,
    fecha_preparacion TIMESTAMP,
    fecha_listo TIMESTAMP,
    fecha_recogida TIMESTAMP,
    fecha_entrega TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Detalle de Pedidos
CREATE TABLE detalle_pedidos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pedido_id UUID REFERENCES pedidos(id) ON DELETE CASCADE,
    producto_id UUID REFERENCES productos(id),
    cantidad INTEGER NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    notas TEXT
);

-- Tabla de Calificaciones
CREATE TABLE calificaciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pedido_id UUID REFERENCES pedidos(id),
    usuario_id UUID REFERENCES usuarios(id),
    vendedor_id UUID REFERENCES vendedores(id),
    repartidor_id UUID REFERENCES repartidores(id),
    puntuacion INTEGER CHECK (puntuacion BETWEEN 1 AND 5),
    comentario TEXT,
    tipo VARCHAR(20) CHECK (tipo IN ('vendedor', 'repartidor')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Notificaciones
CREATE TABLE notificaciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    titulo VARCHAR(200) NOT NULL,
    mensaje TEXT NOT NULL,
    tipo VARCHAR(50),
    leida BOOLEAN DEFAULT false,
    pedido_id UUID REFERENCES pedidos(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejorar el rendimiento
CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_tipo ON usuarios(tipo_usuario);
CREATE INDEX idx_direcciones_usuario ON direcciones(usuario_id);
CREATE INDEX idx_productos_vendedor ON productos(vendedor_id);
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);
CREATE INDEX idx_pedidos_vendedor ON pedidos(vendedor_id);
CREATE INDEX idx_pedidos_repartidor ON pedidos(repartidor_id);
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
CREATE INDEX idx_vendedores_ubicacion ON vendedores USING GIST(direccion_id);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para updated_at
CREATE TRIGGER update_usuarios_updated_at BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vendedores_updated_at BEFORE UPDATE ON vendedores
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_productos_updated_at BEFORE UPDATE ON productos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_repartidores_updated_at BEFORE UPDATE ON repartidores
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pedidos_updated_at BEFORE UPDATE ON pedidos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();