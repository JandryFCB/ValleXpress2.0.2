# 📦 Base de Datos - ValleXpress

## 📋 Contenido

- `schema.sql` - Estructura completa de la BD (sin datos)
- `init.sql` - Script original (se puede reemplazar con schema.sql)
- Otros scripts de migración

## 🚀 Cómo crear la BD desde cero

### Opción 1: Usando PostgreSQL CLI

```bash
# Conectar a PostgreSQL
psql -U postgres

# Crear base de datos
CREATE DATABASE vallexpress_db;

# Conectar a la BD
\c vallexpress_db

# Ejecutar el schema
\i database/schema.sql
```

### Opción 2: Usando Adminer (Interfaz gráfica)

1. Abre Adminer en tu navegador
2. Selecciona la BD: `vallexpress_db`
3. Ve a "Comando SQL"
4. Copia y pega el contenido de `schema.sql`
5. Presiona "Ejecutar"

### Opción 3: Usando Docker (recomendado)

```bash
# Dentro del contenedor
docker exec -i vallexpress_postgres psql -U postgres -d vallexpress_db < database/schema.sql
```

## 📝 Tablas incluidas

- ✅ `usuarios` - Usuarios del sistema
- ✅ `vendedores` - Perfil de vendedores
- ✅ `repartidores` - Perfil de repartidores
- ✅ `productos` - Productos de vendedores
- ✅ `pedidos` - Pedidos de clientes
- ✅ `detalle_pedidos` - Items de cada pedido
- ✅ `password_reset_codes` - Recuperación de contraseña
- ✅ `notificaciones` - Sistema de notificaciones
- ✅ `calificaciones` - Sistema de ratings
- ✅ `direcciones` - Direcciones de usuarios

## ⚙️ Características del schema

- ✅ Todas las relaciones (FK) incluidas
- ✅ Índices para optimización
- ✅ UUIDs como PK
- ✅ Timestamps automáticos
- ✅ Sin datos (solo estructura)

## 🔄 Migraciones

Si necesitas agregar columnas nuevas:

1. Crea un archivo: `database/migration_YYYYMMDD_descripcion.sql`
2. Ejemplo: `database/migration_20260122_add_stock_column.sql`
3. Contiene: `ALTER TABLE productos ADD COLUMN stock INTEGER DEFAULT 0;`
4. Documenta en este README

## 📌 Notas importantes

- Cada desarrollador debe ejecutar `schema.sql` al clonar el repo
- Los datos de prueba se crean manualmente o con scripts separados
- La BD NO debe incluir datos personales en el repo
- Solo cambios de estructura van en `/database/`

---

**Última actualización:** 22/01/2026
