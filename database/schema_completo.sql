-- ============================================================
-- HardSwap FIEI — Schema completo PostgreSQL v2.0
-- Compatible con: Supabase (cloud) y PostgreSQL local
-- ============================================================
-- Ejecutar en orden, de arriba hacia abajo.
-- En Supabase: Dashboard → SQL Editor → Pega y ejecuta.
-- En local:    psql -U postgres -d hardswap_fiei -f schema_completo.sql
-- ============================================================

-- ── 0. Extensiones necesarias ──────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";   -- para uuid_generate_v4()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";    -- para gen_random_uuid()

-- ── 1. Tabla de usuarios (public.users) ───────────────────────────────────
--
-- En Supabase: esta tabla es un ESPEJO de auth.users (manejada por Supabase Auth).
-- En local:    esta tabla ES la tabla principal de usuarios (manejo manual).

CREATE TABLE IF NOT EXISTS public.users (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email           TEXT        NOT NULL UNIQUE,
  name            TEXT,
  image           TEXT,                        -- URL o Base64 del avatar
  whatsapp_number TEXT,                        -- Número peruano: 9 dígitos sin prefijo
  email_verified  BOOLEAN     DEFAULT false,   -- true si es cuenta institucional validada
  role            TEXT        NOT NULL DEFAULT 'user'
                              CHECK (role IN ('user', 'admin')),
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.users IS 'Usuarios del marketplace HardSwap FIEI';
COMMENT ON COLUMN public.users.role IS 'Rol del usuario: user = comprador/vendedor, admin = moderador';
COMMENT ON COLUMN public.users.whatsapp_number IS 'Número completo con código de país: 51987654321';

-- Trigger para copiar usuarios de auth.users a public.users (Solo Supabase)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    'user'
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ── 2. Tabla de categorías ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.categories (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT  NOT NULL UNIQUE,
  icon        TEXT,           -- emoji o nombre de ícono
  sort_order  INT   DEFAULT 0 -- para ordenar en la UI
);

COMMENT ON TABLE public.categories IS 'Categorías de componentes electrónicos';

-- Datos iniciales de categorías
INSERT INTO public.categories (name, icon, sort_order) VALUES
  ('Microcontroladores',    '🔲', 1),
  ('Placas de Desarrollo',  '🖥️', 2),
  ('Sensores',              '📡', 3),
  ('Cámaras',               '📷', 4),
  ('Micrófonos',            '🎙️', 5),
  ('Baterías',              '🔋', 6),
  ('RF / Wireless',         '📶', 7),
  ('Herramientas',          '🔧', 8),
  ('Cables y Conectores',   '🔌', 9),
  ('Otros',                 '📦', 10)
ON CONFLICT (name) DO NOTHING;

-- ── 3. Tabla de productos ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.products (
  -- Identificación
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  category_id     UUID        REFERENCES public.categories(id) ON DELETE SET NULL,

  -- Datos básicos
  title           TEXT        NOT NULL CHECK (char_length(title) BETWEEN 3 AND 80),
  description     TEXT        NOT NULL CHECK (char_length(description) BETWEEN 10 AND 500),
  price           INTEGER     NOT NULL CHECK (price > 0),  -- en centavos: S/15.00 = 1500
  status          TEXT        NOT NULL DEFAULT 'AVAILABLE'
                              CHECK (status IN ('AVAILABLE', 'SOLD', 'EXPIRED')),

  -- Imágenes (hasta 3) almacenadas como Base64 en un array
  images_base64   TEXT[]      DEFAULT '{}',

  -- PB-03: Ficha técnica
  model           TEXT,                    -- Ej: "ESP32-WROOM-32"
  condition       SMALLINT    CHECK (condition BETWEEN 1 AND 10),  -- Estado: 1=malo, 10=nuevo
  datasheet_url   TEXT,                    -- Enlace a PDF del datasheet

  -- PB-12/13: Tips y recursos
  tips            TEXT,                    -- Consejos del vendedor
  github_url      TEXT,                    -- Enlace a GitHub o librería

  -- PB-09/10/11: Kits
  type            TEXT        NOT NULL DEFAULT 'PRODUCT'
                              CHECK (type IN ('PRODUCT', 'KIT')),
  course_label    TEXT,                    -- Ej: "Electrónica Digital - 4to Ciclo"

  -- Metadatos temporales
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  expires_at      TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '14 days')
);

COMMENT ON TABLE public.products IS 'Publicaciones del marketplace HardSwap FIEI';
COMMENT ON COLUMN public.products.price IS 'Precio en centavos. S/15.00 se guarda como 1500';
COMMENT ON COLUMN public.products.condition IS 'Estado del componente de 1 (muy malo) a 10 (nuevo)';
COMMENT ON COLUMN public.products.type IS 'PRODUCT = componente individual, KIT = conjunto de componentes';

-- Índices de performance
CREATE INDEX IF NOT EXISTS idx_products_status      ON public.products(status);
CREATE INDEX IF NOT EXISTS idx_products_user_id     ON public.products(user_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_expires_at  ON public.products(expires_at);
CREATE INDEX IF NOT EXISTS idx_products_type        ON public.products(type);
CREATE INDEX IF NOT EXISTS idx_products_created_at  ON public.products(created_at DESC);

-- ── 4. Tabla de componentes de kits (PB-09/10) ───────────────────────────

CREATE TABLE IF NOT EXISTS public.kit_items (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  kit_id          UUID    NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  component_name  TEXT    NOT NULL CHECK (char_length(component_name) > 0),
  quantity        INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  sort_order      INTEGER DEFAULT 0
);

COMMENT ON TABLE public.kit_items IS 'Componentes individuales de un kit de electrónica';
CREATE INDEX IF NOT EXISTS idx_kit_items_kit_id ON public.kit_items(kit_id);

-- ── 5. Tabla de favoritos (PB-06) ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.favorites (
  user_id     UUID        NOT NULL REFERENCES public.users(id)    ON DELETE CASCADE,
  product_id  UUID        NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, product_id)
);

COMMENT ON TABLE public.favorites IS 'Productos guardados como favoritos por cada usuario';
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);

-- ── 6. Tabla de reportes de moderación (PB-14) ───────────────────────────

CREATE TABLE IF NOT EXISTS public.reports (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID        REFERENCES public.users(id) ON DELETE SET NULL,
  product_id  UUID        NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  reason      TEXT        NOT NULL CHECK (char_length(reason) > 0),
  resolved    BOOLEAN     DEFAULT false,
  resolved_by UUID        REFERENCES public.users(id) ON DELETE SET NULL,
  resolved_at TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.reports IS 'Reportes de publicaciones inapropiadas para moderación';
CREATE INDEX IF NOT EXISTS idx_reports_product_id ON public.reports(product_id);
CREATE INDEX IF NOT EXISTS idx_reports_resolved   ON public.reports(resolved) WHERE resolved = false;

-- ── 7. Trigger: actualizar updated_at automáticamente ─────────────────────

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_products_updated_at ON public.products;
CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_users_updated_at ON public.users;
CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── 8. Función para marcar publicaciones vencidas (cron job) ──────────────
--
-- Llamar periódicamente con: SELECT public.expire_old_products();
-- En Supabase: habilitar pg_cron y agregar cron job.
-- En local:    crear un cron job del sistema operativo.

CREATE OR REPLACE FUNCTION public.expire_old_products()
RETURNS INTEGER LANGUAGE plpgsql AS $$
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

-- ── 9. Vista útil: catálogo público ──────────────────────────────────────
--
-- Combina productos + categorías + usuarios. Útil para queries rápidas.

CREATE OR REPLACE VIEW public.v_catalog AS
SELECT
  p.id,
  p.title,
  p.description,
  p.price,
  p.status,
  p.images_base64,
  p.model,
  p.condition,
  p.datasheet_url,
  p.tips,
  p.github_url,
  p.type,
  p.course_label,
  p.created_at,
  p.expires_at,
  c.name   AS category_name,
  c.id     AS category_id,
  u.name   AS seller_name,
  u.whatsapp_number AS seller_whatsapp
FROM public.products p
LEFT JOIN public.categories c ON c.id = p.category_id
LEFT JOIN public.users u      ON u.id = p.user_id
WHERE p.status = 'AVAILABLE'
  AND p.expires_at > now()
ORDER BY p.created_at DESC;

COMMENT ON VIEW public.v_catalog IS 'Vista del catálogo público — solo productos disponibles y vigentes';

-- ── 9.1 Vista actualizable: usuarios editables ────────────────────────────
--
-- Vista de una única tabla que permite operaciones DML directas en perfiles.
CREATE OR REPLACE VIEW public.v_editable_users AS
SELECT id, name, image, whatsapp_number
FROM public.users;

COMMENT ON VIEW public.v_editable_users IS 'Vista actualizable para edición rápida de perfiles de usuario';


-- ── 10. Datos de admin inicial ─────────────────────────────────────────────
--
-- ATENCIÓN: Cambiar el email al correo del administrador real.
-- En Supabase: este usuario debe existir primero en auth.users (debe haber iniciado sesión).
-- En local:    se inserta directamente con contraseña hasheada.

-- Para Supabase (el usuario ya debe haber iniciado sesión al menos 1 vez):
UPDATE public.users
  SET role = 'admin'
  WHERE email = '2023020308@unfv.edu.pe';

-- Para local (inserción directa — solo si el usuario NO existe aún):
-- INSERT INTO public.users (email, name, role, email_verified)
-- VALUES ('2023020308@unfv.edu.pe', 'Admin FIEI', 'admin', true)
-- ON CONFLICT (email) DO UPDATE SET role = 'admin';


-- ============================================================
-- SECCIÓN SOLO PARA SUPABASE — Row Level Security (RLS)
-- ============================================================
-- Si usas PostgreSQL local con tu propio backend, NO necesitas esto.
-- El backend controlará los permisos en la capa de aplicación.
-- ============================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.users     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kit_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports   ENABLE ROW LEVEL SECURITY;

-- ── Políticas: users ──────────────────────────────────────────────────────

DROP POLICY IF EXISTS "users can read all profiles"    ON public.users;
DROP POLICY IF EXISTS "users can update own profile"   ON public.users;

CREATE POLICY "users can read all profiles" ON public.users
  FOR SELECT USING (true);   -- Todos pueden leer nombres y números públicos

CREATE POLICY "users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- ── Políticas: products ───────────────────────────────────────────────────

DROP POLICY IF EXISTS "catalog is public"            ON public.products;
DROP POLICY IF EXISTS "owners can insert products"   ON public.products;
DROP POLICY IF EXISTS "owners can update products"   ON public.products;
DROP POLICY IF EXISTS "owners can delete products"   ON public.products;
DROP POLICY IF EXISTS "admins can do anything"       ON public.products;

CREATE POLICY "catalog is public" ON public.products
  FOR SELECT USING (true);

CREATE POLICY "owners can insert products" ON public.products
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "owners can update products" ON public.products
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "owners can delete products" ON public.products
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "admins can do anything on products" ON public.products
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

-- ── Políticas: favorites ──────────────────────────────────────────────────

DROP POLICY IF EXISTS "users can manage own favorites" ON public.favorites;
CREATE POLICY "users can manage own favorites" ON public.favorites
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── Políticas: kit_items ──────────────────────────────────────────────────

DROP POLICY IF EXISTS "kit_items readable by all"  ON public.kit_items;
DROP POLICY IF EXISTS "owners manage kit items"    ON public.kit_items;

CREATE POLICY "kit_items readable by all" ON public.kit_items
  FOR SELECT USING (true);

CREATE POLICY "owners manage kit items" ON public.kit_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.products p
      WHERE p.id = kit_id AND p.user_id = auth.uid()
    )
  );

-- ── Políticas: reports ────────────────────────────────────────────────────

DROP POLICY IF EXISTS "users create reports"   ON public.reports;
DROP POLICY IF EXISTS "admins read reports"    ON public.reports;
DROP POLICY IF EXISTS "admins update reports"  ON public.reports;

CREATE POLICY "users create reports" ON public.reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "admins read reports" ON public.reports
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "admins update reports" ON public.reports
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );


-- ============================================================
-- ADICIONES AVANZADAS DE BASE DE DATOS (REQUERIDOS BD II)
-- ============================================================

-- ── 1. Stored Procedures en PostgreSQL (Sección 3.5) ──────────────────────

-- Automatización de expiración con control de transacciones y salida
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

-- Inserción con validación y transacción integrada
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
    RAISE EXCEPTION 'El precio debe ser mayor a 0.';
  END IF;
  
  INSERT INTO public.products (user_id, category_id, title, description, price, condition)
  VALUES (p_user_id, p_category_id, p_title, p_description, p_price, p_condition);
  
  COMMIT;
END;
$$;

-- Procedimiento con parámetros de salida (OUT)
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

-- Transferencia segura de productos con rollback de errores
CREATE OR REPLACE PROCEDURE public.sp_safe_transfer_product(
  p_product_id UUID,
  p_current_owner UUID,
  p_new_owner UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.products WHERE id = p_product_id AND user_id = p_current_owner) THEN
    RAISE EXCEPTION 'El producto no pertenece al propietario indicado.';
  END IF;

  UPDATE public.products
  SET user_id = p_new_owner
  WHERE id = p_product_id;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE EXCEPTION 'Error en transferencia: %', SQLERRM;
END;
$$;


-- ── 2. Funciones de usuario adicionales (Sección 3.6) ─────────────────────

-- Función tipo tabla (Table-valued function)
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

-- Función escalar para formato de monedas
CREATE OR REPLACE FUNCTION public.fn_cents_to_soles(p_cents INTEGER)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  RETURN ROUND(p_cents / 100.0, 2);
END;
$$;


-- ── 3. Tabla y Triggers de Auditoría (Sección 3.7.1 y 3.7.3) ──────────────

CREATE TABLE IF NOT EXISTS public.audit_products (
  audit_id SERIAL PRIMARY KEY,
  product_id UUID NOT NULL,
  action TEXT NOT NULL,
  old_title TEXT,
  new_title TEXT,
  old_price INTEGER,
  new_price INTEGER,
  changed_by UUID,
  changed_at TIMESTAMPTZ DEFAULT now()
);

-- Habilitar RLS en tabla de auditoría para lectura sólo de admins
ALTER TABLE public.audit_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "admins read audit" ON public.audit_products;
CREATE POLICY "admins read audit" ON public.audit_products
  FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

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

DROP TRIGGER IF EXISTS trg_audit_products ON public.products;
CREATE TRIGGER trg_audit_products
  AFTER UPDATE OR DELETE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.fn_audit_product_changes();


-- ── 4. Trigger de Validación de Negocio (Sección 3.7.2) ───────────────────

-- Límite de 10 productos activos simultáneos por estudiante
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

DROP TRIGGER IF EXISTS trg_limit_user_products ON public.products;
CREATE TRIGGER trg_limit_user_products
  BEFORE INSERT ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.fn_limit_user_products();


-- ── 5. Endpoints RPC para el Dashboard del Administrador ──────────────────

-- Obtener métricas analíticas (GROUP BY / HAVING / Aggregations)
CREATE OR REPLACE FUNCTION public.get_admin_stats()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_users INTEGER;
  v_active_products INTEGER;
  v_sold_products INTEGER;
  v_categories_stats JSON;
BEGIN
  SELECT COUNT(*) INTO v_total_users FROM public.users;
  SELECT COUNT(*) INTO v_active_products FROM public.products WHERE status = 'AVAILABLE';
  SELECT COUNT(*) INTO v_sold_products FROM public.products WHERE status = 'SOLD';
  
  SELECT json_agg(t) INTO v_categories_stats
  FROM (
    SELECT c.name AS category_name, COUNT(p.id) AS count
    FROM public.products p
    JOIN public.categories c ON p.category_id = c.id
    GROUP BY c.name
  ) t;

  RETURN json_build_object(
    'total_users', v_total_users,
    'active_products', v_active_products,
    'sold_products', v_sold_products,
    'categories_stats', COALESCE(v_categories_stats, '[]'::json)
  );
END;
$$;

-- Ejecución de mantenimiento desde la UI
CREATE OR REPLACE FUNCTION public.run_expire_maintenance()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN public.expire_old_products();
END;
$$;

