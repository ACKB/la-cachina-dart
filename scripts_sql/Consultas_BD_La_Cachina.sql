-- ============================================================
-- Consultas y Operaciones Comunes - HardSwap FIEI
-- ============================================================

-- 1. Consultar todos los productos disponibles (Catálogo)
SELECT * FROM public.v_catalog;

-- 2. Insertar un nuevo usuario
INSERT INTO public.users (id, email, name, whatsapp_number, role)
VALUES (gen_random_uuid(), 'alumno@unfv.edu.pe', 'Juan Perez', '987654321', 'user');

-- 3. Insertar una nueva categoría (si no existe)
INSERT INTO public.categories (name, icon, sort_order) 
VALUES ('Módulos Relé', '🔌', 11)
ON CONFLICT (name) DO NOTHING;

-- 4. Crear un nuevo producto (Componente)
INSERT INTO public.products (user_id, category_id, title, description, price, status, type, condition)
VALUES (
  (SELECT id FROM public.users WHERE email = 'alumno@unfv.edu.pe'),
  (SELECT id FROM public.categories WHERE name = 'Microcontroladores'),
  'ESP32', 'Microcontrolador con WiFi y Bluetooth', 2500, 'AVAILABLE', 'PRODUCT', 10
);

-- 5. Crear un nuevo KIT con sus componentes
WITH new_kit AS (
  INSERT INTO public.products (user_id, category_id, title, description, price, type, course_label)
  VALUES (
    (SELECT id FROM public.users WHERE email = 'alumno@unfv.edu.pe'),
    (SELECT id FROM public.categories WHERE name = 'Otros'),
    'Kit Arduino Básico', 'Kit ideal para empezar en electrónica', 5000, 'KIT', 'Electrónica Digital'
  ) RETURNING id
)
INSERT INTO public.kit_items (kit_id, component_name, quantity)
VALUES 
  ((SELECT id FROM new_kit), 'Arduino Uno R3', 1),
  ((SELECT id FROM new_kit), 'Protoboard', 1),
  ((SELECT id FROM new_kit), 'Cables Jumper', 20);

-- 6. Agregar un producto a favoritos
INSERT INTO public.favorites (user_id, product_id)
VALUES (
  (SELECT id FROM public.users WHERE email = 'alumno@unfv.edu.pe'),
  (SELECT id FROM public.products WHERE title = 'ESP32' LIMIT 1)
);

-- 7. Obtener los favoritos de un usuario con detalle del producto
SELECT p.* 
FROM public.products p
JOIN public.favorites f ON p.id = f.product_id
JOIN public.users u ON f.user_id = u.id
WHERE u.email = 'alumno@unfv.edu.pe';

-- 8. Actualizar el estado de un producto (Vendido)
UPDATE public.products
SET status = 'SOLD'
WHERE title = 'ESP32';

-- 9. Eliminar un producto (Las relaciones en cascada borrarán favoritos y kit_items)
DELETE FROM public.products
WHERE title = 'ESP32';

-- 10. Reportar una publicación
INSERT INTO public.reports (reporter_id, product_id, reason)
VALUES (
  (SELECT id FROM public.users WHERE email = 'alumno@unfv.edu.pe'),
  (SELECT id FROM public.products WHERE title = 'Kit Arduino Básico' LIMIT 1),
  'Contenido inapropiado o fraudulento'
);

-- 11. Ejecutar expiración de productos antiguos (Función Cron Job)
SELECT public.expire_old_products();

-- 12. Consultar métricas del panel de administrador
SELECT 
  (SELECT count(*) FROM public.users) as total_usuarios,
  (SELECT count(*) FROM public.products WHERE status = 'AVAILABLE') as productos_activos,
  (SELECT count(*) FROM public.products WHERE status = 'SOLD') as productos_vendidos,
  (SELECT count(*) FROM public.reports WHERE resolved = false) as reportes_pendientes;

-- ============================================================
-- CONSULTAS AVANZADAS — PANEL DEL ADMINISTRADOR
-- ============================================================

-- 13. [ADMINISTRADOR] Ranking de categorías con mayor demanda activa
--     Uso: El administrador identifica qué categorías tienen más oferta
--     para destacarlas en el banner principal de la app o priorizarlas
--     en el algoritmo de búsqueda. Solo muestra categorías que tienen
--     AL MENOS 1 producto disponible (filtra categorías vacías con HAVING).
SELECT
  c.name                                    AS categoria,
  c.icon                                    AS icono,
  COUNT(p.id)                               AS publicaciones_activas,
  ROUND(AVG(fn_cents_to_soles(p.price)), 2) AS precio_promedio_soles,
  MIN(fn_cents_to_soles(p.price))           AS precio_minimo_soles,
  MAX(fn_cents_to_soles(p.price))           AS precio_maximo_soles
FROM public.categories c
JOIN public.products p ON p.category_id = c.id
WHERE p.status = 'AVAILABLE'
  AND p.expires_at > now()
GROUP BY c.id, c.name, c.icon
HAVING COUNT(p.id) >= 1
ORDER BY publicaciones_activas DESC;

-- 14. [ADMINISTRADOR] Detección de vendedores con alta actividad
--     Uso: El administrador monitorea qué usuarios tienen 3 o más
--     publicaciones activas simultáneas. Útil para identificar
--     vendedores frecuentes, ofrecerles un rol de "vendedor verificado"
--     en futuras versiones, o detectar posibles abusos del sistema.
SELECT
  u.name                     AS vendedor,
  u.email                    AS correo,
  u.whatsapp_number          AS whatsapp,
  COUNT(p.id)                AS productos_activos,
  SUM(fn_cents_to_soles(p.price)) AS valor_total_inventario_soles
FROM public.users u
JOIN public.products p ON p.user_id = u.id
WHERE p.status = 'AVAILABLE'
  AND p.expires_at > now()
GROUP BY u.id, u.name, u.email, u.whatsapp_number
HAVING COUNT(p.id) >= 3
ORDER BY productos_activos DESC;

-- ============================================================
-- CONSULTAS AVANZADAS — VISTA DEL COMPRADOR (USUARIO)
-- ============================================================

-- 15. [USUARIO/COMPRADOR] Catálogo con etiquetas legibles de estado y condición
--     Uso: La app muestra al comprador el estado del producto y la condición
--     del hardware en lenguaje natural (no los códigos internos).
--     CASE traduce los valores técnicos a texto comprensible para el estudiante
--     sin necesidad de lógica extra en Flutter.
SELECT
  p.title                                   AS producto,
  c.name                                    AS categoria,
  fn_cents_to_soles(p.price)                AS precio_soles,
  u.name                                    AS vendedor,
  u.whatsapp_number                         AS contacto_whatsapp,

  CASE p.status
    WHEN 'AVAILABLE' THEN '✅ Disponible'
    WHEN 'SOLD'      THEN '🔴 Vendido'
    WHEN 'EXPIRED'   THEN '⏰ Publicación vencida'
    ELSE                  '❓ Estado desconocido'
  END AS estado,

  CASE
    WHEN p.condition = 10              THEN '🌟 Nuevo / Sin uso'
    WHEN p.condition BETWEEN 8 AND 9  THEN '✅ Como nuevo'
    WHEN p.condition BETWEEN 5 AND 7  THEN '👍 Buen estado'
    WHEN p.condition BETWEEN 3 AND 4  THEN '⚠️  Uso intensivo'
    WHEN p.condition BETWEEN 1 AND 2  THEN '🔧 Para reparar / Piezas'
    ELSE                                   '❓ Sin calificar'
  END AS condicion_legible,

  CASE p.type
    WHEN 'PRODUCT' THEN '🔩 Componente individual'
    WHEN 'KIT'     THEN '📦 Kit educativo'
    ELSE                '❓ Tipo no definido'
  END AS tipo_publicacion

FROM public.products p
JOIN public.categories c ON c.id = p.category_id
JOIN public.users u       ON u.id = p.user_id
WHERE p.status = 'AVAILABLE'
  AND p.expires_at > now()
ORDER BY p.created_at DESC;

-- 16. [USUARIO/VENDEDOR] Resumen de rendimiento del inventario propio
--     Uso: El vendedor ve desde su dashboard cuántos productos tiene
--     activos, cuántos ha vendido y cuánto ha generado en ventas.
--     Usa CTE para separar la lógica de cálculo de la presentación final.
WITH metricas_vendedor AS (
  SELECT
    u.id                                      AS user_id,
    u.name                                    AS nombre,
    u.email                                   AS correo,
    COUNT(p.id) FILTER (WHERE p.status = 'AVAILABLE') AS activos,
    COUNT(p.id) FILTER (WHERE p.status = 'SOLD')      AS vendidos,
    COUNT(p.id) FILTER (WHERE p.status = 'EXPIRED')   AS expirados,
    COALESCE(SUM(p.price) FILTER (WHERE p.status = 'SOLD'), 0) AS total_vendido_centavos
  FROM public.users u
  LEFT JOIN public.products p ON p.user_id = u.id
  WHERE u.email = 'alumno@unfv.edu.pe'   -- Reemplazar con el email del usuario actual
  GROUP BY u.id, u.name, u.email
)
SELECT
  nombre,
  correo,
  activos                                      AS publicaciones_activas,
  vendidos                                     AS componentes_vendidos,
  expirados                                    AS publicaciones_expiradas,
  fn_cents_to_soles(total_vendido_centavos)    AS total_recaudado_soles,
  CASE
    WHEN vendidos = 0 THEN '🆕 Vendedor nuevo — sin ventas aún'
    WHEN vendidos BETWEEN 1 AND 4 THEN '📈 Vendedor activo'
    WHEN vendidos >= 5 THEN '🏆 Vendedor frecuente'
  END AS nivel_vendedor
FROM metricas_vendedor;

-- ============================================================
-- SECCIÓN 17: MODIFICACIÓN DE TABLAS (ALTER TABLE)
-- Punto 2.5 del PDF: "Creación y modificación de tablas"
-- ============================================================

-- 17a. Agregar columna de renovaciones a products
--      (simula una evolución del esquema en producción)
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS renewal_count INTEGER NOT NULL DEFAULT 0;

COMMENT ON COLUMN public.products.renewal_count
  IS 'Número de veces que el vendedor ha renovado la publicación después de expirar';

-- 17b. Agregar columna de verificación de calidad al perfil del vendedor
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS verified_seller BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.users.verified_seller
  IS 'true si el administrador ha verificado manualmente al vendedor como confiable';

-- 17c. Modificar una restricción existente: extender el límite de caracteres
--      del número de WhatsApp (de texto libre a máximo 20 caracteres)
ALTER TABLE public.users
  ADD CONSTRAINT chk_whatsapp_format
  CHECK (whatsapp_number IS NULL OR char_length(whatsapp_number) BETWEEN 9 AND 20);

-- ============================================================
-- SECCIÓN 18: ÍNDICES AGRUPADOS Y PLAN DE EJECUCIÓN
-- Punto 3.4 del PDF: "Índices clustered, nonclustered, planes de ejecución"
-- ============================================================

-- 18a. Índices no agrupados (B-Tree) — los más frecuentes del sistema
CREATE INDEX IF NOT EXISTS idx_products_status      ON public.products(status);
CREATE INDEX IF NOT EXISTS idx_products_user_id     ON public.products(user_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_expires_at  ON public.products(expires_at);
CREATE INDEX IF NOT EXISTS idx_products_created_at  ON public.products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ratings_seller_id    ON public.seller_ratings(seller_id);

-- Índice parcial (avanzado): solo reportes pendientes de resolución
CREATE INDEX IF NOT EXISTS idx_reports_unresolved ON public.reports(resolved)
  WHERE resolved = false;

-- 18b. CLUSTER — equivalente al Clustered Index de SQL Server
--      Reordena físicamente las filas de products según fecha de creación
--      para que las consultas del catálogo (ORDER BY created_at DESC) sean
--      extremadamente eficientes al leer páginas contiguas del disco.
CLUSTER public.products USING idx_products_created_at;

-- 18c. EXPLAIN ANALYZE — Plan de ejecución de la consulta más crítica
--      Muestra si el optimizador usa Index Scan (con índices) o Seq Scan (sin ellos)
--      y el costo estimado vs real en milisegundos.
EXPLAIN ANALYZE
SELECT
  p.title,
  c.name   AS categoria,
  u.name   AS vendedor,
  p.price,
  p.condition,
  p.expires_at
FROM public.products p
JOIN public.categories c ON c.id = p.category_id
JOIN public.users u       ON u.id = p.user_id
WHERE p.status = 'AVAILABLE'
  AND p.expires_at > now()
ORDER BY p.created_at DESC
LIMIT 20;

-- Resultado esperado con índices activos:
--   -> Index Scan Backward using idx_products_created_at
--   -> Index Cond: (status = 'AVAILABLE') AND (expires_at > now())
--   -> Costo estimado: 0.15..0.85 ms   (vs ~8-15 ms sin índices = Seq Scan)

-- Plan de ejecución para búsqueda de calificaciones de un vendedor:
EXPLAIN ANALYZE
SELECT seller_id, ROUND(AVG(stars)::NUMERIC, 1) AS promedio, COUNT(*) AS total
FROM public.seller_ratings
WHERE seller_id = (SELECT id FROM public.users LIMIT 1)
GROUP BY seller_id;
