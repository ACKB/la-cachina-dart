-- ============================================================
-- HardSwap FIEI — Schema completo PostgreSQL v2.0
-- Compatible con: Supabase (cloud) y PostgreSQL local
-- ============================================================

-- ── 0. Extensiones necesarias ──────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── 1. Tabla de usuarios (public.users) ───────────────────────────────────

CREATE TABLE IF NOT EXISTS public.users (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email           TEXT        NOT NULL UNIQUE,
  name            TEXT,
  image           TEXT,
  whatsapp_number TEXT,
  email_verified  BOOLEAN     DEFAULT false,
  role            TEXT        NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

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
  icon        TEXT,
  sort_order  INT   DEFAULT 0
);

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
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  category_id     UUID        REFERENCES public.categories(id) ON DELETE SET NULL,
  title           TEXT        NOT NULL CHECK (char_length(title) BETWEEN 3 AND 80),
  description     TEXT        NOT NULL CHECK (char_length(description) BETWEEN 10 AND 500),
  price           INTEGER     NOT NULL CHECK (price > 0),
  status          TEXT        NOT NULL DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'SOLD', 'EXPIRED')),
  images_base64   TEXT[]      DEFAULT '{}',
  model           TEXT,
  condition       SMALLINT    CHECK (condition BETWEEN 1 AND 10),
  datasheet_url   TEXT,
  tips            TEXT,
  github_url      TEXT,
  type            TEXT        NOT NULL DEFAULT 'PRODUCT' CHECK (type IN ('PRODUCT', 'KIT')),
  course_label    TEXT,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  expires_at      TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '14 days')
);

CREATE INDEX IF NOT EXISTS idx_products_status      ON public.products(status);
CREATE INDEX IF NOT EXISTS idx_products_user_id     ON public.products(user_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_expires_at  ON public.products(expires_at);

-- ── 4. Tabla de componentes de kits ───────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.kit_items (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  kit_id          UUID    NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  component_name  TEXT    NOT NULL CHECK (char_length(component_name) > 0),
  quantity        INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  sort_order      INTEGER DEFAULT 0
);

-- ── 5. Tabla de favoritos ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.favorites (
  user_id     UUID        NOT NULL REFERENCES public.users(id)    ON DELETE CASCADE,
  product_id  UUID        NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, product_id)
);

-- ── 6. Tabla de reportes de moderación ────────────────────────────────────

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

-- ── 7. Vista útil: catálogo público ──────────────────────────────────────

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


-- ============================================================
-- ADICIONES AVANZADAS DE BASE DE DATOS (REQUERIDOS BD II)
-- ============================================================

-- ── 8. Stored Procedures en PostgreSQL (Sección 3.5) ──────────────────────

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


-- ── 9. Funciones de usuario adicionales (Sección 3.6) ─────────────────────

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


-- ── 10. Tabla y Triggers de Auditoría (Sección 3.7.1 y 3.7.3) ──────────────

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


-- ── 11. Trigger de Validación de Negocio (Sección 3.7.2) ───────────────────

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


-- ── 12. Endpoints RPC para el Dashboard del Administrador ──────────────────

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

