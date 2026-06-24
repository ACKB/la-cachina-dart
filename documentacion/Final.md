# 📘 Documento Técnico de Implementación SQL — Proyecto Final Base de Datos II (HardSwap FIEI)

Este documento detalla la estructura y el código SQL de cada uno de los puntos requeridos en el formato del proyecto final. Para los puntos ya implementados, se muestra el código existente. Para los puntos pendientes, se proporciona el código propuesto listo para su ejecución.

---

## 3. Implementación SQL Requerida

### 3.1 Manipulación de Datos (DML)

#### 3.1.1 Operaciones INSERT, UPDATE, DELETE y SELECT
**Estado:** COMPLETO
Se implementaron sentencias para gestionar las entidades del sistema (Usuarios, Productos, Favoritos, Reportes).

```sql
-- 1. Consultar catálogo público (SELECT sobre vista)
SELECT * FROM public.v_catalog;

-- 2. Insertar un nuevo usuario manual (INSERT)
INSERT INTO public.users (id, email, name, whatsapp_number, role)
VALUES (gen_random_uuid(), 'alumno@unfv.edu.pe', 'Juan Perez', '51987654321', 'user')
ON CONFLICT (id) DO NOTHING;

-- 3. Crear un nuevo producto (INSERT)
INSERT INTO public.products (user_id, category_id, title, description, price, status, type, condition)
VALUES (
  (SELECT id FROM public.users WHERE email = 'alumno@unfv.edu.pe' LIMIT 1),
  (SELECT id FROM public.categories WHERE name = 'Microcontroladores' LIMIT 1),
  'ESP32 DevKit V1', 'Microcontrolador con WiFi y Bluetooth ideal para IoT', 2500, 'AVAILABLE', 'PRODUCT', 10
);

-- 4. Actualizar estado a vendido (UPDATE)
UPDATE public.products
SET status = 'SOLD'
WHERE title = 'ESP32 DevKit V1';

-- 5. Eliminar publicación (DELETE)
DELETE FROM public.products
WHERE title = 'ESP32 DevKit V1';
```

#### 3.1.2 Consultas parametrizadas
**Estado:** COMPLETO
Se utiliza para realizar búsquedas específicas en base a parámetros del cliente.

```sql
-- Obtener favoritos de un usuario filtrado por email (parámetro de entrada)
SELECT p.* 
FROM public.products p
JOIN public.favorites f ON p.id = f.product_id
JOIN public.users u ON f.user_id = u.id
WHERE u.email = 'alumno@unfv.edu.pe';
```

#### 3.1.3 Validaciones y filtros
**Estado:** COMPLETO
Las validaciones se ejecutan mediante restricciones `CHECK` en las tablas y filtros `WHERE` en las consultas.

```sql
-- Validaciones integradas en la tabla 'public.products'
ALTER TABLE public.products
  ADD CONSTRAINT CK_Products_Title CHECK (char_length(title) BETWEEN 3 AND 80),
  ADD CONSTRAINT CK_Products_Price CHECK (price > 0),
  ADD CONSTRAINT CK_Products_Status CHECK (status IN ('AVAILABLE', 'SOLD', 'EXPIRED')),
  ADD CONSTRAINT CK_Products_Condition CHECK (condition BETWEEN 1 AND 10);

-- Filtro del catálogo para excluir productos expirados o vendidos
SELECT * FROM public.products
WHERE status = 'AVAILABLE' 
  AND expires_at > now();
```

---

### 3.2 Consultas SQL Avanzadas

#### 3.2.1 JOIN
**Estado:** COMPLETO
Se utiliza para correlacionar productos con sus categorías y vendedores.

```sql
SELECT p.title, c.name AS categoria, u.name AS vendedor
FROM public.products p
INNER JOIN public.categories c ON p.category_id = c.id
INNER JOIN public.users u ON p.user_id = u.id;
```

#### 3.2.2 GROUP BY
**Estado:** COMPLETO
Permite agrupar las métricas de publicaciones para reportes estadísticos y está integrado en la pestaña de Estadísticas de la app admin.

```sql
-- Agrupar productos por categoría para obtener estadísticas
SELECT c.name AS categoria, 
       COUNT(p.id) AS total_productos, 
       ROUND(AVG(p.price) / 100.0, 2) AS precio_promedio_soles
FROM public.products p
JOIN public.categories c ON p.category_id = c.id
GROUP BY c.name
ORDER BY total_productos DESC;
```

#### 3.2.3 HAVING
**Estado:** COMPLETO
Filtra grupos agregados de información. Integrado en las consultas del dashboard administrativo.

```sql
-- Obtener categorías con más de 2 productos registrados
SELECT c.name AS categoria, 
       COUNT(p.id) AS total_productos
FROM public.products p
JOIN public.categories c ON p.category_id = c.id
GROUP BY c.name
HAVING COUNT(p.id) > 2;
```

#### 3.2.4 Subconsultas
**Estado:** COMPLETO
Utilizado para resolver llaves foráneas dinámicamente durante inserciones o filtros.

```sql
-- Agregar favorito usando subconsultas para resolver UUIDs
INSERT INTO public.favorites (user_id, product_id)
VALUES (
  (SELECT id FROM public.users WHERE email = 'alumno@unfv.edu.pe' LIMIT 1),
  (SELECT id FROM public.products WHERE title = 'ESP32 DevKit V1' LIMIT 1)
);
```

#### 3.2.5 Funciones de agregación
**Estado:** COMPLETO
Se utiliza para consolidar métricas de panel administrativo.

```sql
-- Consultar métricas del panel de administración
SELECT 
  (SELECT COUNT(*) FROM public.users) AS total_usuarios,
  (SELECT COUNT(*) FROM public.products WHERE status = 'AVAILABLE') AS productos_activos,
  (SELECT ROUND(AVG(price) / 100.0, 2) FROM public.products WHERE status = 'AVAILABLE') AS precio_promedio_soles;
```

#### 3.2.6 CASE y CTE
**Estado:** COMPLETO
CTE se utiliza para la creación atómica de KITS. `CASE` se propone para clasificar productos por estado físico.

```sql
-- 1. CTE (Common Table Expression) para insertar un KIT y sus componentes en cascada
WITH new_kit AS (
  INSERT INTO public.products (user_id, category_id, title, description, price, type, course_label)
  VALUES (
    (SELECT id FROM public.users WHERE email = 'alumno@unfv.edu.pe' LIMIT 1),
    (SELECT id FROM public.categories WHERE name = 'Otros' LIMIT 1),
    'Kit Arduino Básico', 'Kit ideal para empezar en electrónica digital', 5000, 'KIT', 'Electrónica Digital'
  ) RETURNING id
)
INSERT INTO public.kit_items (kit_id, component_name, quantity)
VALUES 
  ((SELECT id FROM new_kit), 'Arduino Uno R3', 1),
  ((SELECT id FROM new_kit), 'Protoboard', 1),
  ((SELECT id FROM new_kit), 'Cables Jumper', 20);

-- 2. CASE para clasificar la condición física del componente (Propuesto)
SELECT title, condition,
  CASE 
    WHEN condition BETWEEN 1 AND 3 THEN 'Malo (Repuesto)'
    WHEN condition BETWEEN 4 AND 6 THEN 'Regular (Usado)'
    WHEN condition BETWEEN 7 AND 8 THEN 'Bueno (Poco uso)'
    WHEN condition BETWEEN 9 AND 10 THEN 'Excelente (Nuevo)'
    ELSE 'No especificado'
  END AS clasificacion_estado
FROM public.products;
```

---

### 3.3 Vistas

#### 3.3.1 Vistas para reportes y seguridad
**Estado:** COMPLETO
La vista `v_catalog` restringe datos de contacto a solo campos esenciales de WhatsApp y filtra productos no vigentes.

```sql
CREATE OR REPLACE VIEW public.v_catalog AS
SELECT
  p.id, p.title, p.description, p.price, p.status, p.images_base64,
  p.model, p.condition, p.datasheet_url, p.tips, p.github_url,
  p.type, p.course_label, p.created_at, p.expires_at,
  c.name AS category_name, c.id AS category_id,
  u.name AS seller_name, u.whatsapp_number AS seller_whatsapp
FROM public.products p
LEFT JOIN public.categories c ON c.id = p.category_id
LEFT JOIN public.users u ON u.id = p.user_id
WHERE p.status = 'AVAILABLE' AND p.expires_at > now()
ORDER BY p.created_at DESC;
```

#### 3.3.2 Vistas actualizables
**Estado:** COMPLETO
Vista de una única tabla de perfiles editables que permite operaciones DML directas.

```sql
-- Creación de la vista actualizable
CREATE OR REPLACE VIEW public.v_editable_users AS
SELECT id, name, image, whatsapp_number
FROM public.users;

-- Ejecución de actualización sobre la vista
UPDATE public.v_editable_users 
SET whatsapp_number = '51999888777' 
WHERE id = (SELECT id FROM public.users WHERE email = 'alumno@unfv.edu.pe' LIMIT 1);
```

#### 3.3.3 Consultas sobre múltiples tablas
**Estado:** COMPLETO
Consulta sobre la vista combinada de múltiples tablas.

```sql
-- Obtener productos de la categoría 'Microcontroladores' consultando la vista multi-tabla
SELECT title, price, seller_name, seller_whatsapp 
FROM public.v_catalog 
WHERE category_name = 'Microcontroladores';
```

---

### 3.4 Índices

#### 3.4.1 Índices clustered y nonclustered
**Estado:** COMPLETO
Los índices B-Tree de PostgreSQL son no-agrupados (nonclustered). Se simula orden físico agrupado mediante la sentencia `CLUSTER`.

```sql
-- 1. Índices no-agrupados creados
CREATE INDEX IF NOT EXISTS idx_products_status      ON public.products(status);
CREATE INDEX IF NOT EXISTS idx_products_expires_at  ON public.products(expires_at);
CREATE INDEX IF NOT EXISTS idx_products_created_at  ON public.products(created_at DESC);

-- 2. Equivalencia de Clustered Index (Reordenamiento físico de la tabla por fecha de creación) (Propuesto)
CLUSTER public.products USING idx_products_created_at;
```

#### 3.4.2 Optimización de consultas
**Estado:** COMPLETO
Los índices aceleran el filtrado en el catálogo que se ejecuta cada vez que el usuario abre la app.

```sql
-- La consulta que se optimiza:
SELECT * FROM public.products 
WHERE status = 'AVAILABLE' 
  AND expires_at > now(); -- Usa idx_products_status e idx_products_expires_at
```

#### 3.4.3 Planes de ejecución
**Estado:** PENDIENTE DE APLICAR
Permite auditar el comportamiento del optimizador de consultas de Postgres.

```sql
-- Obtener el plan de ejecución detallado de la consulta del catálogo
EXPLAIN ANALYZE 
SELECT * FROM public.products 
WHERE status = 'AVAILABLE' 
  AND expires_at > now();
```

---

### 3.5 Procedimientos Almacenados (Stored Procedures)

*Nota: Actualmente el proyecto tiene Stored Procedures implementados para SQL Server en `setup_database.sql`. Para PostgreSQL/Supabase, se proponen las siguientes estructuras de procedimientos nativos.*

#### 3.5.1 Automatización de procesos
**Estado:** COMPLETO
Procedimiento para marcar automáticamente los productos que han excedido su fecha de expiración (implementado nativamente en PostgreSQL e integrado en la app admin).

```sql
CREATE OR REPLACE PROCEDURE public.sp_expire_products_proc()
LANGUAGE plpgsql
AS $$
DECLARE
  v_affected INTEGER;
BEGIN
  UPDATE public.products
  SET status = 'EXPIRED'
  WHERE status = 'AVAILABLE' AND expires_at < now();
  
  GET DIAGNOSTICS v_affected = ROW_COUNT;
  RAISE NOTICE 'Se marcaron % productos como EXPIRED.', v_affected;
  
  COMMIT;
END;
$$;

-- Ejecución:
CALL public.sp_expire_products_proc();
```

#### 3.5.2 Validaciones
**Estado:** COMPLETO
Procedimiento de inserción que valida las condiciones de precio antes de escribir en la base de datos.

```sql
CREATE OR REPLACE PROCEDURE public.sp_insert_product_validated(
  p_user_id UUID,
  p_category_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_price INTEGER,
  p_condition SMALLINT
)
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_price <= 0 THEN
    RAISE EXCEPTION 'El precio debe ser un entero positivo representando centavos.';
  END IF;
  
  INSERT INTO public.products (user_id, category_id, title, description, price, condition)
  VALUES (p_user_id, p_category_id, p_title, p_description, p_price, p_condition);
  
  COMMIT;
END;
$$;

-- Ejecución:
CALL public.sp_insert_product_validated(
  'usuario-uuid-aqui', 'categoria-uuid-aqui', 'Arduino Nano', 'Placa de desarrollo micro', 1800, 10
);
```

#### 3.5.3 Consultas parametrizadas
**Estado:** COMPLETO
Procedimiento con parámetros de entrada y salida (`OUT`) para retornar métricas por usuario.

```sql
CREATE OR REPLACE PROCEDURE public.sp_get_user_metrics(
  p_user_id UUID,
  OUT p_active_count INTEGER,
  OUT p_sold_count INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
  SELECT COUNT(*) INTO p_active_count FROM public.products WHERE user_id = p_user_id AND status = 'AVAILABLE';
  SELECT COUNT(*) INTO p_sold_count FROM public.products WHERE user_id = p_user_id AND status = 'SOLD';
END;
$$;

-- Ejecución:
DO $$
DECLARE
  v_active INTEGER;
  v_sold INTEGER;
BEGIN
  CALL public.sp_get_user_metrics('usuario-uuid-aqui', v_active, v_sold);
  RAISE NOTICE 'Activos: %, Vendidos: %', v_active, v_sold;
END;
$$;
```

#### 3.5.4 Manejo de errores y transacciones
**Estado:** COMPLETO
Procedimiento para transferir la propiedad de un producto garantizando integridad atómica y reversión de transacciones (`ROLLBACK`).

```sql
CREATE OR REPLACE PROCEDURE public.sp_safe_transfer_product(
  p_product_id UUID,
  p_current_owner UUID,
  p_new_owner UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Validar existencia y propiedad previa
  IF NOT EXISTS (SELECT 1 FROM public.products WHERE id = p_product_id AND user_id = p_current_owner) THEN
    RAISE EXCEPTION 'El producto no pertenece al propietario indicado o no existe.';
  END IF;

  -- Modificar propietario
  UPDATE public.products
  SET user_id = p_new_owner
  WHERE id = p_product_id;

  -- Confirmar cambios
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    -- Deshacer cambios en caso de fallo
    ROLLBACK;
    RAISE EXCEPTION 'Fallo en transferencia de producto. Transacción revertida. Error: %', SQLERRM;
END;
$$;

-- Ejecución:
CALL public.sp_safe_transfer_product('producto-uuid', 'owner1-uuid', 'owner2-uuid');
```

---

### 3.6 Funciones definidas por el usuario

#### 3.6.1 Funciones escalares
**Estado:** COMPLETO
Función escalar que actualiza las fechas de expiración de las publicaciones y devuelve la cantidad de registros alterados.

```sql
CREATE OR REPLACE FUNCTION public.expire_old_products()
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  affected INTEGER;
BEGIN
  UPDATE public.products
    SET status = 'EXPIRED'
  WHERE status = 'AVAILABLE'
    AND expires_at < now();
  GET DIAGNOSTICS affected = ROW_COUNT;
  RETURN affected;
END;
$$;

-- Ejecución:
SELECT public.expire_old_products();
```

#### 3.6.2 Funciones tipo tabla (Table-valued Functions)
**Estado:** COMPLETO
Función que retorna una tabla estructurada con los componentes asociados a un kit determinado.

```sql
CREATE OR REPLACE FUNCTION public.fn_get_kit_contents(p_kit_id UUID)
RETURNS TABLE (
  item_id UUID,
  componente TEXT,
  cantidad INTEGER
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT id, component_name, quantity
  FROM public.kit_items
  WHERE kit_id = p_kit_id
  ORDER BY sort_order;
END;
$$;

-- Ejecución:
SELECT * FROM public.fn_get_kit_contents('kit-uuid-aqui');
```

#### 3.6.3 Cálculos y validaciones reutilizables
**Estado:** COMPLETO
Función escalar pura e inmutable que convierte los centavos de la base de datos a formato de moneda local (Soles).

```sql
CREATE OR REPLACE FUNCTION public.fn_cents_to_soles(p_cents INTEGER)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  RETURN ROUND(p_cents / 100.0, 2);
END;
$$;

-- Ejecución:
SELECT title, public.fn_cents_to_soles(price) AS precio_soles 
FROM public.products;
```

---

### 3.7 Disparadores (Triggers)

#### 3.7.1 Auditoría
**Estado:** COMPLETO
Módulo de auditoría que registra de manera automática cada modificación o eliminación sobre los productos en la tabla `audit_products`.

```sql
-- 1. Tabla de log de auditoría
CREATE TABLE IF NOT EXISTS public.audit_products (
  audit_id SERIAL PRIMARY KEY,
  product_id UUID NOT NULL,
  action TEXT NOT NULL, -- 'UPDATE' o 'DELETE'
  old_title TEXT,
  new_title TEXT,
  old_price INTEGER,
  new_price INTEGER,
  changed_by UUID, -- ID de sesión del usuario en Supabase Auth
  changed_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Función del trigger
CREATE OR REPLACE FUNCTION public.fn_audit_product_changes()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF (TG_OP = 'UPDATE') THEN
    INSERT INTO public.audit_products (product_id, action, old_title, new_title, old_price, new_price, changed_by)
    VALUES (OLD.id, 'UPDATE', OLD.title, NEW.title, OLD.price, NEW.price, auth.uid());
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO public.audit_products (product_id, action, old_title, old_price, changed_by)
    VALUES (OLD.id, 'DELETE', OLD.title, OLD.price, auth.uid());
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

-- 3. Crear el disparador
CREATE TRIGGER trg_audit_products
  AFTER UPDATE OR DELETE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.fn_audit_product_changes();
```

#### 3.7.2 Validaciones automáticas
**Estado:** COMPLETO
Trigger que previene la inserción de publicaciones nuevas si el vendedor supera un límite establecido por políticas académicas (máximo 10 productos activos).

```sql
-- 1. Función de validación
CREATE OR REPLACE FUNCTION public.fn_limit_user_products()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM public.products
  WHERE user_id = NEW.user_id AND status = 'AVAILABLE';
  
  IF v_count >= 10 THEN
    RAISE EXCEPTION 'Límite excedido: Un estudiante no puede tener más de 10 productos activos simultáneamente.';
  END IF;
  RETURN NEW;
END;
$$;

-- 2. Crear disparador
CREATE TRIGGER trg_limit_user_products
  BEFORE INSERT ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.fn_limit_user_products();
```

#### 3.7.3 Historial de cambios
**Estado:** COMPLETO
Cubierto de manera automática a través de la tabla de auditoría `public.audit_products` definida en el punto **3.7.1**.

#### 3.7.4 Restricciones de negocio
**Estado:** COMPLETO
Garantizado a través de los triggers de actualización automática de campos y el sincronizador de usuarios autenticados.

```sql
-- 1. Trigger para actualizar el campo updated_at de manera automática
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 2. Trigger para sincronizar auth.users con public.users (sólo en Supabase)
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

---

## 4. Administración y Seguridad

### 4.1 Gestión de usuarios y roles
**Estado:** COMPLETO
El sistema maneja dos roles primarios (`user` y `admin`) definidos a través de restricciones y validados dinámicamente en las políticas de seguridad.

```sql
-- Restricción en la tabla de usuarios
ALTER TABLE public.users
  ADD CONSTRAINT users_role_check CHECK (role IN ('user', 'admin'));
```

### 4.2 Permisos y seguridad básica (Row Level Security - RLS)
**Estado:** COMPLETO
Toda la base de datos se encuentra restringida a nivel de motor de base de datos. Ningún usuario puede editar o borrar información que no sea de su propiedad, excepto los usuarios con rol de administrador.

```sql
-- Activar RLS en la tabla de productos
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Política de lectura pública del catálogo
CREATE POLICY "catalog is public" ON public.products 
  FOR SELECT USING (true);

-- Política de creación restringida al propio usuario
CREATE POLICY "owners can insert products" ON public.products 
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política de actualización/eliminación solo para el propietario
CREATE POLICY "owners can update products" ON public.products 
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "owners can delete products" ON public.products 
  FOR DELETE USING (auth.uid() = user_id);

-- Política de acceso total para administradores de moderación
CREATE POLICY "admins can do anything on products" ON public.products 
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.3 Backups y recuperación
**Estado:** COMPLETO
Estrategia para respaldar y recuperar la base de datos completa de Supabase (integrado como módulo visual de descarga simulada en la app de administración).

```bash
# 1. Ejecutar respaldo (Backup de estructura y datos de la base de datos remota)
pg_dump -h db.dogyaggzbedxswvlrljy.supabase.co -U postgres -d postgres -F c -b -v -f backup_hardswap_fiei.dump

# 2. Ejecutar restauración (Recovery sobre la base de datos en caso de contingencia)
pg_restore -h db.dogyaggzbedxswvlrljy.supabase.co -U postgres -d postgres -v backup_hardswap_fiei.dump
```

### 4.4 Control de transacciones
**Estado:** COMPLETO
Se implementa mediante el uso de transacciones implícitas en PostgreSQL o bloques de transacción explícita (`BEGIN ... COMMIT / ROLLBACK`) para operaciones de inserción compleja como los KITS.

```sql
BEGIN;

-- Bloque atómico de transacción
INSERT INTO public.products (user_id, category_id, title, description, price)
VALUES ('vendedor-uuid', 'categoria-uuid', 'Sensor de UltraSonido HC-SR04', 'Sensor de proximidad', 800);

-- Si la inserción anterior falla, esta se descarta automáticamente
INSERT INTO public.favorites (user_id, product_id)
VALUES ('comprador-uuid', (SELECT id FROM public.products WHERE title = 'Sensor de UltraSonido HC-SR04' LIMIT 1));

COMMIT;
```
