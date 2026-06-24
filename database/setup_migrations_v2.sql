-- ============================================================
-- HardSwap FIEI — Migraciones v2 (PI.pdf Backlog completo)
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- ============================================================

-- PB-03: Campos técnicos en products
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS model        TEXT,
  ADD COLUMN IF NOT EXISTS condition    SMALLINT CHECK (condition BETWEEN 1 AND 10),
  ADD COLUMN IF NOT EXISTS datasheet_url TEXT,
  ADD COLUMN IF NOT EXISTS tips         TEXT,
  ADD COLUMN IF NOT EXISTS github_url   TEXT,
  ADD COLUMN IF NOT EXISTS type         TEXT DEFAULT 'PRODUCT' CHECK (type IN ('PRODUCT', 'KIT')),
  ADD COLUMN IF NOT EXISTS course_label TEXT;

-- PB-14: Columna role en public.users
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin'));

-- PB-14: Configurar admin (2023020308@unfv.edu.pe)
UPDATE public.users
  SET role = 'admin'
  WHERE email = '2023020308@unfv.edu.pe';

-- PB-06: Tabla de favoritos
CREATE TABLE IF NOT EXISTS public.favorites (
  user_id    UUID REFERENCES public.users(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, product_id)
);
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "users can manage own favorites" ON public.favorites;
CREATE POLICY "users can manage own favorites" ON public.favorites
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- PB-09/10: Tabla de componentes de kits
CREATE TABLE IF NOT EXISTS public.kit_items (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kit_id         UUID REFERENCES public.products(id) ON DELETE CASCADE,
  component_name TEXT    NOT NULL,
  quantity       INTEGER DEFAULT 1
);
ALTER TABLE public.kit_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "kit_items readable by all" ON public.kit_items;
CREATE POLICY "kit_items readable by all" ON public.kit_items FOR SELECT USING (true);
DROP POLICY IF EXISTS "owners manage kit items" ON public.kit_items;
CREATE POLICY "owners manage kit items" ON public.kit_items FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.products p
    WHERE p.id = kit_id AND p.user_id = auth.uid()
  ));

-- PB-14: Tabla de reportes
CREATE TABLE IF NOT EXISTS public.reports (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  product_id  UUID REFERENCES public.products(id) ON DELETE CASCADE,
  reason      TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now(),
  resolved    BOOLEAN DEFAULT false
);
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "users create reports" ON public.reports;
CREATE POLICY "users create reports" ON public.reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);
DROP POLICY IF EXISTS "admins read reports" ON public.reports;
CREATE POLICY "admins read reports" ON public.reports FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
DROP POLICY IF EXISTS "admins update reports" ON public.reports;
CREATE POLICY "admins update reports" ON public.reports FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
