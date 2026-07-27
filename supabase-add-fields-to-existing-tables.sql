-- ============================================================================
-- SQL untuk Menambahkan Field ke Tabel yang Sudah Ada
-- ============================================================================
-- File ini untuk update tabel existing (step_images, menus) dengan field baru
-- Jalankan script ini jika tabel sudah ada sebelumnya
-- ============================================================================

-- ============================================================================
-- 0. CREATE HELPER FUNCTION (jika belum ada)
-- ============================================================================

-- Function untuk auto-update kolom updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 1. UPDATE TABEL STEP_IMAGES (jika sudah ada)
-- ============================================================================

-- Tambahkan kolom baru jika belum ada
ALTER TABLE step_images 
  ADD COLUMN IF NOT EXISTS image_id TEXT,
  ADD COLUMN IF NOT EXISTS app_id TEXT DEFAULT 'd365-dmk-v3',
  ADD COLUMN IF NOT EXISTS step_id TEXT,
  ADD COLUMN IF NOT EXISTS menu_id TEXT,
  ADD COLUMN IF NOT EXISTS image_type TEXT,
  ADD COLUMN IF NOT EXISTS image_data TEXT,
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS file_name TEXT,
  ADD COLUMN IF NOT EXISTS file_size INTEGER,
  ADD COLUMN IF NOT EXISTS mime_type TEXT,
  ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS created_by TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Update existing rows untuk set image_id jika NULL
UPDATE step_images 
SET image_id = 'img_' || id::text 
WHERE image_id IS NULL;

-- Buat unique constraint pada image_id (jika belum ada)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'step_images_image_id_key'
  ) THEN
    ALTER TABLE step_images ADD CONSTRAINT step_images_image_id_key UNIQUE (image_id);
  END IF;
END $$;

-- Tambahkan indexes
CREATE INDEX IF NOT EXISTS step_images_app_id_idx ON step_images(app_id);
CREATE INDEX IF NOT EXISTS step_images_step_id_idx ON step_images(step_id);
CREATE INDEX IF NOT EXISTS step_images_menu_id_idx ON step_images(menu_id);
CREATE INDEX IF NOT EXISTS step_images_image_type_idx ON step_images(image_type);
CREATE INDEX IF NOT EXISTS step_images_display_order_idx ON step_images(display_order);

-- Tambahkan auto-update trigger untuk updated_at
DROP TRIGGER IF EXISTS update_step_images_updated_at ON step_images;
CREATE TRIGGER update_step_images_updated_at
  BEFORE UPDATE ON step_images
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Update RLS policy
ALTER TABLE step_images ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all for step_images" ON step_images;
CREATE POLICY "Allow all for step_images" ON step_images
  FOR ALL USING (true) WITH CHECK (true);

-- ============================================================================
-- 2. UPDATE TABEL STEP_IMAGES_PUBLIC (jika ada)
-- ============================================================================

-- Sama seperti step_images, tapi untuk public access
ALTER TABLE step_images_public 
  ADD COLUMN IF NOT EXISTS image_id TEXT,
  ADD COLUMN IF NOT EXISTS app_id TEXT DEFAULT 'd365-dmk-v3',
  ADD COLUMN IF NOT EXISTS step_id TEXT,
  ADD COLUMN IF NOT EXISTS menu_id TEXT,
  ADD COLUMN IF NOT EXISTS image_type TEXT,
  ADD COLUMN IF NOT EXISTS image_data TEXT,
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS file_name TEXT,
  ADD COLUMN IF NOT EXISTS file_size INTEGER,
  ADD COLUMN IF NOT EXISTS mime_type TEXT,
  ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS created_by TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Update existing rows
UPDATE step_images_public 
SET image_id = 'img_public_' || id::text 
WHERE image_id IS NULL;

-- Unique constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'step_images_public_image_id_key'
  ) THEN
    ALTER TABLE step_images_public ADD CONSTRAINT step_images_public_image_id_key UNIQUE (image_id);
  END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS step_images_public_app_id_idx ON step_images_public(app_id);
CREATE INDEX IF NOT EXISTS step_images_public_step_id_idx ON step_images_public(step_id);
CREATE INDEX IF NOT EXISTS step_images_public_menu_id_idx ON step_images_public(menu_id);
CREATE INDEX IF NOT EXISTS step_images_public_image_type_idx ON step_images_public(image_type);

-- Trigger
DROP TRIGGER IF EXISTS update_step_images_public_updated_at ON step_images_public;
CREATE TRIGGER update_step_images_public_updated_at
  BEFORE UPDATE ON step_images_public
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS policy (public bisa diakses semua orang)
ALTER TABLE step_images_public ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read for step_images_public" ON step_images_public;
CREATE POLICY "Allow public read for step_images_public" ON step_images_public
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow authenticated write for step_images_public" ON step_images_public;
CREATE POLICY "Allow authenticated write for step_images_public" ON step_images_public
  FOR ALL USING (true) WITH CHECK (true);

-- ============================================================================
-- 3. UPDATE TABEL MENUS (jika sudah ada dengan struktur berbeda)
-- ============================================================================

-- Jika tabel menus sudah ada tapi strukturnya berbeda, tambahkan field yang kurang
ALTER TABLE menus 
  ADD COLUMN IF NOT EXISTS menu_id TEXT,
  ADD COLUMN IF NOT EXISTS app_id TEXT DEFAULT 'd365-dmk-v3',
  ADD COLUMN IF NOT EXISTS menu_name TEXT,
  ADD COLUMN IF NOT EXISTS menu_desc TEXT,
  ADD COLUMN IF NOT EXISTS menu_image TEXT,
  ADD COLUMN IF NOT EXISTS cat_key TEXT,
  ADD COLUMN IF NOT EXISTS cat_name TEXT,
  ADD COLUMN IF NOT EXISTS color TEXT,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS created_by TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Buat unique constraint jika belum ada
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'menus_menu_id_key'
  ) THEN
    -- Update NULL menu_id dengan generated ID
    UPDATE menus SET menu_id = 'menu_' || id::text WHERE menu_id IS NULL;
    
    -- Tambahkan unique constraint
    ALTER TABLE menus ADD CONSTRAINT menus_menu_id_key UNIQUE (menu_id);
  END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS menus_app_id_idx ON menus(app_id);
CREATE INDEX IF NOT EXISTS menus_cat_key_idx ON menus(cat_key);
CREATE INDEX IF NOT EXISTS menus_is_active_idx ON menus(is_active);
CREATE INDEX IF NOT EXISTS menus_display_order_idx ON menus(display_order);

-- Trigger
DROP TRIGGER IF EXISTS update_menus_updated_at ON menus;
CREATE TRIGGER update_menus_updated_at
  BEFORE UPDATE ON menus
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE menus ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all for menus" ON menus;
CREATE POLICY "Allow all for menus" ON menus
  FOR ALL USING (true) WITH CHECK (true);

-- ============================================================================
-- 4. VERIFIKASI
-- ============================================================================

-- Query untuk melihat struktur tabel yang sudah diupdate
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name IN ('step_images', 'step_images_public', 'menus')
  AND table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- Log completion
DO $$
BEGIN
  RAISE NOTICE '✅ Field updates completed!';
  RAISE NOTICE '📊 Updated tables: step_images, step_images_public, menus';
  RAISE NOTICE '🔍 Run the verification query above to check all columns';
END $$;

-- ============================================================================
-- CATATAN PENTING
-- ============================================================================
-- 1. Script ini AMAN untuk dijalankan berulang kali (idempotent)
-- 2. Menggunakan "IF NOT EXISTS" dan "IF EXISTS" untuk cek kolom/constraint
-- 3. Tidak akan menghapus data existing
-- 4. Hanya menambahkan field baru yang belum ada
-- 5. Update NULL values dengan default values
-- ============================================================================
