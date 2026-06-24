-- ============================================================
-- HardSwap FIEI — Sistema de Calificación por Estrellas
-- Sección 3.5, 3.6, 3.7 (Procedimientos, Funciones, Triggers)
-- ============================================================

-- ── 1. Tabla de calificaciones de vendedores ─────────────────

CREATE TABLE IF NOT EXISTS public.seller_ratings (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id    UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  buyer_id     UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  product_id   UUID        NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  stars        SMALLINT    NOT NULL CHECK (stars BETWEEN 1 AND 5),
  comment      TEXT        CHECK (char_length(comment) <= 300),
  created_at   TIMESTAMPTZ DEFAULT now(),

  -- Un comprador solo puede calificar una vez por producto
  CONSTRAINT uq_rating_per_product UNIQUE (buyer_id, product_id)
);

COMMENT ON TABLE public.seller_ratings IS
  'Calificaciones de 1 a 5 estrellas que los compradores dan a los vendedores tras una transacción.';
COMMENT ON COLUMN public.seller_ratings.stars IS
  '1 = muy malo, 2 = malo, 3 = regular, 4 = bueno, 5 = excelente';

CREATE INDEX IF NOT EXISTS idx_ratings_seller_id  ON public.seller_ratings(seller_id);
CREATE INDEX IF NOT EXISTS idx_ratings_product_id ON public.seller_ratings(product_id);

-- ── 2. RLS — Solo compradores autenticados pueden calificar ──

ALTER TABLE public.seller_ratings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "buyers can insert ratings"  ON public.seller_ratings;
DROP POLICY IF EXISTS "ratings are public"         ON public.seller_ratings;
DROP POLICY IF EXISTS "buyers can delete own rating" ON public.seller_ratings;

-- Cualquiera puede ver las calificaciones (transparencia del marketplace)
CREATE POLICY "ratings are public" ON public.seller_ratings
  FOR SELECT USING (true);

-- Solo el comprador autenticado puede insertar, firmado con su ID
CREATE POLICY "buyers can insert ratings" ON public.seller_ratings
  FOR INSERT WITH CHECK (auth.uid() = buyer_id);

-- El comprador puede eliminar su propia calificación
CREATE POLICY "buyers can delete own rating" ON public.seller_ratings
  FOR DELETE USING (auth.uid() = buyer_id);


-- ── 3. Trigger: validaciones de negocio al calificar ────────

-- Regla 1: El comprador NO puede calificarse a sí mismo.
-- Regla 2: Solo se puede calificar si el producto ya fue marcado como SOLD.
CREATE OR REPLACE FUNCTION public.fn_validate_rating()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_product_status TEXT;
  v_product_owner  UUID;
BEGIN
  -- Regla 1: No puede calificarse a sí mismo
  IF NEW.buyer_id = NEW.seller_id THEN
    RAISE EXCEPTION 'No puedes calificarte a ti mismo.';
  END IF;

  -- Regla 2: El producto debe estar VENDIDO (transacción completada)
  SELECT status, user_id
    INTO v_product_status, v_product_owner
    FROM public.products
   WHERE id = NEW.product_id;

  IF v_product_status != 'SOLD' THEN
    RAISE EXCEPTION 'Solo puedes calificar una transacción completada (producto marcado como SOLD).';
  END IF;

  -- Regla 3: El seller_id debe coincidir con el dueño real del producto
  IF v_product_owner != NEW.seller_id THEN
    RAISE EXCEPTION 'El vendedor indicado no es el propietario del producto.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_rating ON public.seller_ratings;
CREATE TRIGGER trg_validate_rating
  BEFORE INSERT ON public.seller_ratings
  FOR EACH ROW EXECUTE FUNCTION public.fn_validate_rating();


-- ── 4. Función escalar: calificación promedio de un vendedor ─

CREATE OR REPLACE FUNCTION public.fn_seller_avg_rating(p_seller_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_avg NUMERIC;
BEGIN
  SELECT ROUND(AVG(stars)::NUMERIC, 1)
    INTO v_avg
    FROM public.seller_ratings
   WHERE seller_id = p_seller_id;

  RETURN COALESCE(v_avg, 0);
END;
$$;

COMMENT ON FUNCTION public.fn_seller_avg_rating IS
  'Retorna la calificación promedio (1.0–5.0) de un vendedor. Retorna 0 si no tiene calificaciones.';


-- ── 5. Vista: perfil público de vendedor con estrellas ───────
--    Combina datos del usuario + métricas de calificación.
--    Usada en la card de vendedor del detalle del producto.

CREATE OR REPLACE VIEW public.v_seller_profiles AS
SELECT
  u.id                                          AS seller_id,
  u.name                                        AS seller_name,
  u.whatsapp_number,
  u.email_verified,

  COUNT(DISTINCT sr.id)                         AS total_ratings,
  COALESCE(ROUND(AVG(sr.stars)::NUMERIC, 1), 0) AS avg_stars,

  -- Distribución de estrellas (útil para la UI)
  COUNT(sr.id) FILTER (WHERE sr.stars = 5)      AS stars_5,
  COUNT(sr.id) FILTER (WHERE sr.stars = 4)      AS stars_4,
  COUNT(sr.id) FILTER (WHERE sr.stars = 3)      AS stars_3,
  COUNT(sr.id) FILTER (WHERE sr.stars = 2)      AS stars_2,
  COUNT(sr.id) FILTER (WHERE sr.stars = 1)      AS stars_1,

  -- Nivel del vendedor basado en promedio + volumen (CASE)
  CASE
    WHEN COUNT(DISTINCT sr.id) = 0                        THEN 'Nuevo'
    WHEN ROUND(AVG(sr.stars)::NUMERIC, 1) >= 4.5
         AND COUNT(DISTINCT sr.id) >= 5                   THEN 'Top Vendedor ⭐'
    WHEN ROUND(AVG(sr.stars)::NUMERIC, 1) >= 3.5         THEN 'Confiable'
    WHEN ROUND(AVG(sr.stars)::NUMERIC, 1) >= 2.5         THEN 'Regular'
    ELSE                                                       'En observación'
  END AS seller_level,

  -- Total de productos vendidos (historial)
  COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'SOLD')  AS total_sold

FROM public.users u
LEFT JOIN public.seller_ratings sr ON sr.seller_id = u.id
LEFT JOIN public.products p        ON p.user_id    = u.id
GROUP BY u.id, u.name, u.whatsapp_number, u.email_verified;

COMMENT ON VIEW public.v_seller_profiles IS
  'Perfil público del vendedor: promedio de estrellas, nivel, distribución y total de ventas.';


-- ── 6. Procedimiento: registrar calificación con transacción ─

CREATE OR REPLACE PROCEDURE public.sp_rate_seller(
  p_seller_id  UUID,
  p_buyer_id   UUID,
  p_product_id UUID,
  p_stars      SMALLINT,
  p_comment    TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.seller_ratings (seller_id, buyer_id, product_id, stars, comment)
  VALUES (p_seller_id, p_buyer_id, p_product_id, p_stars, p_comment);

  COMMIT;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Ya calificaste esta transacción anteriormente.';
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE EXCEPTION 'Error al registrar calificación: %', SQLERRM;
END;
$$;


-- ── 7. Consultas de ejemplo para el informe ─────────────────

-- [ADMINISTRADOR] Vendedores con calificación sobresaliente
-- HAVING: solo muestra vendedores con al menos 2 calificaciones
-- y promedio mayor o igual a 4.0
SELECT
  seller_name                    AS vendedor,
  avg_stars                      AS promedio_estrellas,
  total_ratings                  AS total_calificaciones,
  total_sold                     AS productos_vendidos,
  seller_level                   AS nivel
FROM public.v_seller_profiles
WHERE total_ratings > 0
GROUP BY seller_id, seller_name, avg_stars, total_ratings, total_sold, seller_level
HAVING total_ratings >= 2
   AND avg_stars >= 4.0
ORDER BY avg_stars DESC, total_ratings DESC;

-- [USUARIO] Ver la distribución de estrellas de un vendedor específico
SELECT
  avg_stars,
  total_ratings,
  stars_5, stars_4, stars_3, stars_2, stars_1,
  seller_level
FROM public.v_seller_profiles
WHERE seller_id = '00000000-0000-0000-0000-000000000000'; -- reemplazar con UUID real
