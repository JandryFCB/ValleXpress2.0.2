-- Agregar columna stock a tabla productos
ALTER TABLE "public"."productos" ADD COLUMN "stock" INTEGER DEFAULT 0;

-- Verificar estructura actualizada
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'productos' 
ORDER BY ordinal_position;
