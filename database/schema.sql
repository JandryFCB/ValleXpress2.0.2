-- Adminer 5.4.1 PostgreSQL 15.15 dump

DROP FUNCTION IF EXISTS "uuid_generate_v1";;
CREATE FUNCTION "uuid_generate_v1" () RETURNS uuid LANGUAGE c AS 'uuid_generate_v1';

DROP FUNCTION IF EXISTS "uuid_generate_v1mc";;
CREATE FUNCTION "uuid_generate_v1mc" () RETURNS uuid LANGUAGE c AS 'uuid_generate_v1mc';

DROP FUNCTION IF EXISTS "uuid_generate_v3";;
CREATE FUNCTION "uuid_generate_v3" (IN "namespace" uuid, IN "name" text) RETURNS uuid LANGUAGE c AS 'uuid_generate_v3';

DROP FUNCTION IF EXISTS "uuid_generate_v4";;
CREATE FUNCTION "uuid_generate_v4" () RETURNS uuid LANGUAGE c AS 'uuid_generate_v4';

DROP FUNCTION IF EXISTS "uuid_generate_v5";;
CREATE FUNCTION "uuid_generate_v5" (IN "namespace" uuid, IN "name" text) RETURNS uuid LANGUAGE c AS 'uuid_generate_v5';

DROP FUNCTION IF EXISTS "uuid_nil";;
CREATE FUNCTION "uuid_nil" () RETURNS uuid LANGUAGE c AS 'uuid_nil';

DROP FUNCTION IF EXISTS "uuid_ns_dns";;
CREATE FUNCTION "uuid_ns_dns" () RETURNS uuid LANGUAGE c AS 'uuid_ns_dns';

DROP FUNCTION IF EXISTS "uuid_ns_oid";;
CREATE FUNCTION "uuid_ns_oid" () RETURNS uuid LANGUAGE c AS 'uuid_ns_oid';

DROP FUNCTION IF EXISTS "uuid_ns_url";;
CREATE FUNCTION "uuid_ns_url" () RETURNS uuid LANGUAGE c AS 'uuid_ns_url';

DROP FUNCTION IF EXISTS "uuid_ns_x500";;
CREATE FUNCTION "uuid_ns_x500" () RETURNS uuid LANGUAGE c AS 'uuid_ns_x500';

DROP TABLE IF EXISTS "calificaciones";
CREATE TABLE "public"."calificaciones" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "pedido_id" uuid,
    "usuario_id" uuid,
    "vendedor_id" uuid,
    "repartidor_id" uuid,
    "puntuacion" numeric(2,1),
    "comentario" text,
    "tipo" character varying(20),
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "calificaciones_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "calificaciones_tipo_check" CHECK (((tipo)::text = ANY ((ARRAY['vendedor'::character varying, 'repartidor'::character varying])::text[]))),
    CONSTRAINT "calificaciones_puntuacion_check" CHECK (((puntuacion >= (1)::numeric) AND (puntuacion <= (5)::numeric)))
)
WITH (oids = false);

CREATE INDEX idx_calificaciones_usuario_id ON public.calificaciones USING btree (usuario_id);

CREATE INDEX idx_calificaciones_vendedor_id ON public.calificaciones USING btree (vendedor_id);

CREATE INDEX idx_calificaciones_repartidor_id ON public.calificaciones USING btree (repartidor_id);


DROP TABLE IF EXISTS "detalle_pedidos";
CREATE TABLE "public"."detalle_pedidos" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "pedido_id" uuid,
    "producto_id" uuid,
    "cantidad" integer NOT NULL,
    "precio_unitario" numeric(10,2) NOT NULL,
    "subtotal" numeric(10,2) NOT NULL,
    "notas" text,
    CONSTRAINT "detalle_pedidos_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE INDEX idx_detalle_pedidos_pedido_id ON public.detalle_pedidos USING btree (pedido_id);

CREATE INDEX idx_detalle_pedidos_producto_id ON public.detalle_pedidos USING btree (producto_id);


DROP TABLE IF EXISTS "direcciones";
CREATE TABLE "public"."direcciones" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "usuario_id" uuid,
    "nombre" character varying(50),
    "direccion" text NOT NULL,
    "latitud" numeric(10,8) NOT NULL,
    "longitud" numeric(11,8) NOT NULL,
    "es_predeterminada" boolean DEFAULT false,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "direcciones_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE INDEX idx_direcciones_usuario ON public.direcciones USING btree (usuario_id);

CREATE INDEX idx_direcciones_usuario_id ON public.direcciones USING btree (usuario_id);


DROP TABLE IF EXISTS "notificaciones";
CREATE TABLE "public"."notificaciones" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "usuario_id" uuid,
    "titulo" character varying(200) NOT NULL,
    "mensaje" text NOT NULL,
    "tipo" character varying(50),
    "leida" boolean DEFAULT false,
    "pedido_id" uuid,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "notificaciones_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE INDEX idx_notificaciones_usuario_id ON public.notificaciones USING btree (usuario_id);


DROP TABLE IF EXISTS "password_reset_codes";
CREATE TABLE "public"."password_reset_codes" (
    "id" uuid NOT NULL,
    "userId" uuid,
    "email" character varying(200) NOT NULL,
    "codeHash" character varying(255) NOT NULL,
    "expiresAt" timestamptz NOT NULL,
    "attempts" integer DEFAULT '0' NOT NULL,
    "usedAt" timestamptz,
    "createdAt" timestamptz NOT NULL,
    "updatedAt" timestamptz NOT NULL,
    CONSTRAINT "password_reset_codes_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);


DROP TABLE IF EXISTS "pedidos";
CREATE TABLE "public"."pedidos" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "numero_pedido" character varying(20) NOT NULL,
    "cliente_id" uuid,
    "vendedor_id" uuid,
    "repartidor_id" uuid,
    "direccion_entrega_id" uuid,
    "estado" character varying(50),
    "subtotal" numeric(10,2) NOT NULL,
    "costo_delivery" numeric(10,2) NOT NULL,
    "total" numeric(10,2) NOT NULL,
    "metodo_pago" character varying(50),
    "pagado" boolean DEFAULT false,
    "paypal_order_id" character varying(100),
    "notas_cliente" text,
    "tiempo_estimado" integer,
    "fecha_pedido" timestamp DEFAULT CURRENT_TIMESTAMP,
    "fecha_confirmacion" timestamp,
    "fecha_preparacion" timestamp,
    "fecha_listo" timestamp,
    "fecha_recogida" timestamp,
    "fecha_entrega" timestamp,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "pedidos_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "pedidos_estado_check" CHECK (((estado)::text = ANY ((ARRAY['pendiente'::character varying, 'confirmado'::character varying, 'preparando'::character varying, 'listo'::character varying, 'en_camino'::character varying, 'entregado'::character varying, 'recibido_cliente'::character varying, 'cancelado'::character varying])::text[])))
)
WITH (oids = false);

CREATE UNIQUE INDEX pedidos_numero_pedido_key ON public.pedidos USING btree (numero_pedido);

CREATE INDEX idx_pedidos_cliente ON public.pedidos USING btree (cliente_id);

CREATE INDEX idx_pedidos_vendedor ON public.pedidos USING btree (vendedor_id);

CREATE INDEX idx_pedidos_repartidor ON public.pedidos USING btree (repartidor_id);

CREATE INDEX idx_pedidos_estado ON public.pedidos USING btree (estado);

CREATE INDEX idx_pedidos_cliente_id ON public.pedidos USING btree (cliente_id);

CREATE INDEX idx_pedidos_vendedor_id ON public.pedidos USING btree (vendedor_id);

CREATE INDEX idx_pedidos_repartidor_id ON public.pedidos USING btree (repartidor_id);


DROP TABLE IF EXISTS "productos";
CREATE TABLE "public"."productos" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "vendedor_id" uuid,
    "nombre" character varying(200) NOT NULL,
    "descripcion" text,
    "precio" numeric(10,2) NOT NULL,
    "imagen" text,
    "categoria" character varying(50),
    "disponible" boolean DEFAULT true,
    "tiempo_preparacion" integer,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "stock" integer DEFAULT '0',
    CONSTRAINT "productos_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE INDEX idx_productos_vendedor ON public.productos USING btree (vendedor_id);

CREATE INDEX idx_productos_vendedor_id ON public.productos USING btree (vendedor_id);

CREATE INDEX idx_productos_disponible ON public.productos USING btree (disponible);


DROP TABLE IF EXISTS "repartidores";
CREATE TABLE "public"."repartidores" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "usuario_id" uuid,
    "vehiculo" character varying(50),
    "placa" character varying(20),
    "licencia" character varying(50),
    "calificacion_promedio" numeric(3,2) DEFAULT '0.00',
    "total_calificaciones" integer DEFAULT '0',
    "disponible" boolean DEFAULT false,
    "latitud" numeric(10,8),
    "longitud" numeric(11,8),
    "pedidos_completados" integer DEFAULT '0',
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "cedula" character varying(10),
    "foto" text,
    CONSTRAINT "repartidores_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX repartidores_cedula_key ON public.repartidores USING btree (cedula);

CREATE INDEX idx_repartidores_usuario_id ON public.repartidores USING btree (usuario_id);

CREATE INDEX idx_repartidores_disponible ON public.repartidores USING btree (disponible);


DROP TABLE IF EXISTS "usuarios";
CREATE TABLE "public"."usuarios" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "nombre" character varying(100) NOT NULL,
    "apellido" character varying(100) NOT NULL,
    "email" character varying(150) NOT NULL,
    "telefono" character varying(20),
    "password_hash" character varying(255) NOT NULL,
    "tipo_usuario" character varying(20),
    "foto_perfil" text,
    "activo" boolean DEFAULT true,
    "verificado" boolean DEFAULT false,
    "fecha_registro" timestamp DEFAULT CURRENT_TIMESTAMP,
    "ultima_conexion" timestamp,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "cedula" character varying(10),
    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "usuarios_tipo_usuario_check" CHECK (((tipo_usuario)::text = ANY ((ARRAY['cliente'::character varying, 'vendedor'::character varying, 'repartidor'::character varying])::text[])))
)
WITH (oids = false);

CREATE UNIQUE INDEX usuarios_email_key ON public.usuarios USING btree (email);

CREATE INDEX idx_usuarios_tipo ON public.usuarios USING btree (tipo_usuario);

CREATE UNIQUE INDEX usuarios_cedula_key ON public.usuarios USING btree (cedula);

CREATE INDEX usuarios_email ON public.usuarios USING btree (email);

CREATE INDEX usuarios_tipo_usuario ON public.usuarios USING btree (tipo_usuario);

CREATE INDEX idx_usuarios_email ON public.usuarios USING btree (email);

CREATE INDEX idx_usuarios_tipo_usuario ON public.usuarios USING btree (tipo_usuario);


DROP TABLE IF EXISTS "vendedores";
CREATE TABLE "public"."vendedores" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "usuario_id" uuid,
    "nombre_negocio" character varying(200) NOT NULL,
    "descripcion" text,
    "logo" text,
    "banner" text,
    "categoria" character varying(50),
    "calificacion_promedio" numeric(3,2) DEFAULT '0.00',
    "total_calificaciones" integer DEFAULT '0',
    "direccion_id" uuid,
    "horario_apertura" character varying(10),
    "horario_cierre" character varying(10),
    "dias_atencion" character varying(100),
    "tiempo_preparacion_promedio" integer,
    "costo_delivery" numeric(10,2),
    "radio_cobertura" integer,
    "abierto_ahora" boolean DEFAULT false,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "cedula" character varying(10),
    CONSTRAINT "vendedores_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX vendedores_cedula_key ON public.vendedores USING btree (cedula);

CREATE INDEX idx_vendedores_usuario_id ON public.vendedores USING btree (usuario_id);


ALTER TABLE ONLY "public"."calificaciones" ADD CONSTRAINT "calificaciones_pedido_id_fkey" FOREIGN KEY (pedido_id) REFERENCES pedidos(id) NOT DEFERRABLE;
ALTER TABLE ONLY "public"."calificaciones" ADD CONSTRAINT "calificaciones_repartidor_id_fkey" FOREIGN KEY (repartidor_id) REFERENCES repartidores(id) NOT DEFERRABLE;
ALTER TABLE ONLY "public"."calificaciones" ADD CONSTRAINT "calificaciones_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES usuarios(id) NOT DEFERRABLE;
ALTER TABLE ONLY "public"."calificaciones" ADD CONSTRAINT "calificaciones_vendedor_id_fkey" FOREIGN KEY (vendedor_id) REFERENCES vendedores(id) NOT DEFERRABLE;

ALTER TABLE ONLY "public"."detalle_pedidos" ADD CONSTRAINT "detalle_pedidos_pedido_id_fkey" FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."detalle_pedidos" ADD CONSTRAINT "detalle_pedidos_producto_id_fkey" FOREIGN KEY (producto_id) REFERENCES productos(id) NOT DEFERRABLE;

ALTER TABLE ONLY "public"."direcciones" ADD CONSTRAINT "direcciones_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."notificaciones" ADD CONSTRAINT "notificaciones_pedido_id_fkey" FOREIGN KEY (pedido_id) REFERENCES pedidos(id) NOT DEFERRABLE;
ALTER TABLE ONLY "public"."notificaciones" ADD CONSTRAINT "notificaciones_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."pedidos" ADD CONSTRAINT "pedidos_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES usuarios(id) NOT DEFERRABLE;
ALTER TABLE ONLY "public"."pedidos" ADD CONSTRAINT "pedidos_direccion_entrega_id_fkey" FOREIGN KEY (direccion_entrega_id) REFERENCES direcciones(id) NOT DEFERRABLE;
ALTER TABLE ONLY "public"."pedidos" ADD CONSTRAINT "pedidos_repartidor_id_fkey" FOREIGN KEY (repartidor_id) REFERENCES repartidores(id) NOT DEFERRABLE;
ALTER TABLE ONLY "public"."pedidos" ADD CONSTRAINT "pedidos_vendedor_id_fkey" FOREIGN KEY (vendedor_id) REFERENCES vendedores(id) NOT DEFERRABLE;

ALTER TABLE ONLY "public"."productos" ADD CONSTRAINT "productos_vendedor_id_fkey" FOREIGN KEY (vendedor_id) REFERENCES vendedores(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."repartidores" ADD CONSTRAINT "repartidores_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."vendedores" ADD CONSTRAINT "vendedores_direccion_id_fkey" FOREIGN KEY (direccion_id) REFERENCES direcciones(id) NOT DEFERRABLE;
ALTER TABLE ONLY "public"."vendedores" ADD CONSTRAINT "vendedores_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASC
-- Tabla: usuarios
CREATE TABLE IF NOT EXISTS "public"."usuarios" (
    "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    "nombre" character varying(100) NOT NULL,
    "apellido" character varying(100) NOT NULL,
    "email" character varying(255) UNIQUE NOT NULL,
    "telefono" character varying(20),
    "cedula" character varying(20) UNIQUE,
    "password_hash" character varying(255) NOT NULL,
    "tipo_usuario" character varying(50) NOT NULL DEFAULT 'cliente',
    "foto_perfil" text,
    "activo" boolean NOT NULL DEFAULT true,
    "verificado" boolean NOT NULL DEFAULT false,
    "fecha_registro" timestamp DEFAULT CURRENT_TIMESTAMP,
    "ultima_conexion" timestamp,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP
) WITH (oids = false);

CREATE INDEX IF NOT EXISTS "idx_usuarios_email" ON "public"."usuarios" ("email");
CREATE INDEX IF NOT EXISTS "idx_usuarios_tipo_usuario" ON "public"."usuarios" ("tipo_usuario");

-- Tabla: vendedores
CREATE TABLE IF NOT EXISTS "public"."vendedores" (
    "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    "usuario_id" uuid NOT NULL UNIQUE,
    "nombre_negocio" character varying(200),
    "descripcion" text,
    "logo" text,
    "banner" text,
    "categoria" character varying(50),
    "calificacion_promedio" numeric(3,2) DEFAULT 0.00,
    "total_calificaciones" integer DEFAULT 0,
    "direccion_id" uuid,
    "horario_apertura" character varying(10),
    "horario_cierre" character varying(10),
    "dias_atencion" character varying(100),
    "tiempo_preparacion_promedio" integer,
    "costo_delivery" numeric(10,2) DEFAULT 0.00,
    "radio_cobertura" numeric(10,2),
    "abierto_ahora" boolean DEFAULT true,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id") ON DELETE CASCADE,
    FOREIGN KEY ("direccion_id") REFERENCES "public"."direcciones"("id")
) WITH (oids = false);

CREATE INDEX IF NOT EXISTS "idx_vendedores_usuario_id" ON "public"."vendedores" ("usuario_id");

-- Tabla: repartidores
CREATE TABLE IF NOT EXISTS "public"."repartidores" (
    "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    "usuario_id" uuid NOT NULL UNIQUE,
    "vehiculo" character varying(100) DEFAULT 'No especificado',
    "placa" character varying(20) DEFAULT 'No especificada',
    "licencia" character varying(50) DEFAULT 'No especificada',
    "calificacion_promedio" numeric(3,2) DEFAULT 0.00,
    "total_calificaciones" integer DEFAULT 0,
    "foto" character varying(255),
    "disponible" boolean DEFAULT false,
    "pedidos_completados" integer DEFAULT 0,
    "latitud" numeric(10,8),
    "longitud" numeric(11,8),
    "ultima_ubicacion_actualizacion" timestamp,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id") ON DELETE CASCADE
) WITH (oids = false);

CREATE INDEX IF NOT EXISTS "idx_repartidores_usuario_id" ON "public"."repartidores" ("usuario_id");
CREATE INDEX IF NOT EXISTS "idx_repartidores_disponible" ON "public"."repartidores" ("disponible");

-- Tabla: productos
CREATE TABLE IF NOT EXISTS "public"."productos" (
    "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    "vendedor_id" uuid NOT NULL,
    "nombre" character varying(200) NOT NULL,
    "descripcion" text,
    "precio" numeric(10,2) NOT NULL,
    "imagen" text,
    "categoria" character varying(50),
    "disponible" boolean DEFAULT true,
    "stock" integer DEFAULT 0,
    "tiempo_preparacion" integer,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("vendedor_id") REFERENCES "public"."vendedores"("id") ON DELETE CASCADE
) WITH (oids = false);

CREATE INDEX IF NOT EXISTS "idx_productos_vendedor_id" ON "public"."productos" ("vendedor_id");
CREATE INDEX IF NOT EXISTS "idx_productos_disponible" ON "public"."productos" ("disponible");

-- Tabla: pedidos
CREATE TABLE IF NOT EXISTS "public"."pedidos" (
    "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    "numero_pedido" character varying(20) UNIQUE,
    "cliente_id" uuid NOT NULL,
    "vendedor_id" uuid NOT NULL,
    "repartidor_id" uuid,
    "direccion_entrega_id" uuid,
    "estado" character varying(50) DEFAULT 'pendiente',
    "subtotal" numeric(10,2) NOT NULL,
    "costo_delivery" numeric(10,2) NOT NULL,
    "total" numeric(10,2) NOT NULL,
    "metodo_pago" character varying(50),
    "pagado" boolean DEFAULT false,
    "paypal_order_id" character varying(100),
    "notas_cliente" text,
    "tiempo_estimado" integer,
    "fecha_pedido" timestamp DEFAULT CURRENT_TIMESTAMP,
    "fecha_confirmacion" timestamp,
    "fecha_preparacion" timestamp,
    "fecha_listo" timestamp,
    "fecha_recogida" timestamp,
    "fecha_entrega" timestamp,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("cliente_id") REFERENCES "public"."usuarios"("id"),
    FOREIGN KEY ("vendedor_id") REFERENCES "public"."vendedores"("id"),
    FOREIGN KEY ("repartidor_id") REFERENCES "public"."repartidores"("id"),
    FOREIGN KEY ("direccion_entrega_id") REFERENCES "public"."direcciones"("id")
) WITH (oids = false);

CREATE INDEX IF NOT EXISTS "idx_pedidos_cliente_id" ON "public"."pedidos" ("cliente_id");
CREATE INDEX IF NOT EXISTS "idx_pedidos_vendedor_id" ON "public"."pedidos" ("vendedor_id");
CREATE INDEX IF NOT EXISTS "idx_pedidos_repartidor_id" ON "public"."pedidos" ("repartidor_id");
CREATE INDEX IF NOT EXISTS "idx_pedidos_estado" ON "public"."pedidos" ("estado");

-- Tabla: detalle_pedidos
CREATE TABLE IF NOT EXISTS "public"."detalle_pedidos" (
    "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    "pedido_id" uuid NOT NULL,
    "producto_id" uuid NOT NULL,
    "cantidad" integer NOT NULL,
    "precio_unitario" numeric(10,2) NOT NULL,
    "subtotal" numeric(10,2) NOT NULL,
    "notas" text,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("pedido_id") REFERENCES "public"."pedidos"("id") ON DELETE CASCADE,
    FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id")
) WITH (oids = false);

CREATE INDEX IF NOT EXISTS "idx_detalle_pedidos_pedido_id" ON "public"."detalle_pedidos" ("pedido_id");
CREATE INDEX IF NOT EXISTS "idx_detalle_pedidos_producto_id" ON "public"."detalle_pedidos" ("producto_id");

-- Tabla: password_reset_codes
CREATE TABLE IF NOT EXISTS "public"."password_reset_codes" (
    "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    "usuario_id" uuid NOT NULL,
    "codigo" character varying(10) NOT NULL UNIQUE,
    "expira_en" timestamp NOT NULL,
    "utilizado" boolean DEFAULT false,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id") ON DELETE CASCADE
) WITH (oids = false);

CREATE INDEX IF NOT EXISTS "idx_password_reset_codes_usuario_id" ON "public"."password_reset_codes" ("usuario_id");
CREATE INDEX IF NOT EXISTS "idx_password_reset_codes_codigo" ON "public"."password_reset_codes" ("codigo");

-- Tabla: notificaciones
CREATE TABLE IF NOT EXISTS "public"."notificaciones" (
    "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    "usuario_id" uuid NOT NULL,
    "tipo" character varying(50),
    "titulo" character varying(200),
    "mensaje" text,
    "leida" boolean DEFAULT false,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id") ON DELETE CASCADE
) WITH (oids = false);

CREATE INDEX IF NOT EXISTS "idx_notificaciones_usuario_id" ON "public"."notificaciones" ("usuario_id");

-- Tabla: calificaciones
CREATE TABLE IF NOT EXISTS "public"."calificaciones" (
    "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    "pedido_id" uuid,
    "usuario_id" uuid NOT NULL,
    "vendedor_id" uuid,
    "repartidor_id" uuid,
    "puntuacion" numeric(2,1),
    "comentario" text,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("pedido_id") REFERENCES "public"."pedidos"("id"),
    FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id"),
    FOREIGN KEY ("vendedor_id") REFERENCES "public"."vendedores"("id"),
    FOREIGN KEY ("repartidor_id") REFERENCES "public"."repartidores"("id")
) WITH (oids = false);

CREATE INDEX IF NOT EXISTS "idx_calificaciones_usuario_id" ON "public"."calificaciones" ("usuario_id");
CREATE INDEX IF NOT EXISTS "idx_calificaciones_vendedor_id" ON "public"."calificaciones" ("vendedor_id");
CREATE INDEX IF NOT EXISTS "idx_calificaciones_repartidor_id" ON "public"."calificaciones" ("repartidor_id");

-- Tabla: direcciones
CREATE TABLE IF NOT EXISTS "public"."direcciones" (
    "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    "usuario_id" uuid NOT NULL,
    "nombre" character varying(100),
    "direccion" text NOT NULL,
    "latitud" numeric(10,8) NOT NULL,
    "longitud" numeric(11,8) NOT NULL,
    "es_predeterminada" boolean DEFAULT false,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id") ON DELETE CASCADE
) WITH (oids = false);

CREATE INDEX IF NOT EXISTS "idx_direcciones_usuario_id" ON "public"."direcciones" ("usuario_id");
