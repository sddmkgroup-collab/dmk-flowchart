-- ============================================================================
-- SUPABASE DATABASE SETUP untuk D365 BC User Manual v3
-- ============================================================================
-- File ini berisi SQL untuk setup database Supabase yang lengkap
-- Jalankan script ini di Supabase SQL Editor untuk setup database
-- ============================================================================

-- ============================================================================
-- 1. TABEL APP_DATA (sudah ada, tapi perlu dipastikan strukturnya benar)
-- ============================================================================
-- Tabel ini menyimpan semua data aplikasi dalam format JSON blob
-- Cocok untuk rapid development dan fleksibilitas tinggi

CREATE TABLE IF NOT EXISTS app_data (
  id BIGSERIAL PRIMARY KEY,
  app_id TEXT NOT NULL,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index untuk performa query
CREATE UNIQUE INDEX IF NOT EXISTS app_data_app_id_idx ON app_data(app_id);
CREATE INDEX IF NOT EXISTS app_data_data_idx ON app_data USING GIN(data);

-- Trigger untuk auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_app_data_updated_at ON app_data;
CREATE TRIGGER update_app_data_updated_at
  BEFORE UPDATE ON app_data
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 2. TABEL MENUS (normalized structure untuk custom menus)
-- ============================================================================
-- Tabel ini menyimpan menu custom yang dibuat user
-- Alternative dari menyimpan sebagai __menu_* di JSONB

CREATE TABLE IF NOT EXISTS menus (
  id BIGSERIAL PRIMARY KEY,
  menu_id TEXT NOT NULL UNIQUE,              -- Format: {catKey}_menu_{timestamp}
  app_id TEXT NOT NULL DEFAULT 'd365-dmk-v3',
  
  -- Menu Information
  menu_name TEXT NOT NULL,                    -- Nama menu
  menu_desc TEXT,                             -- Deskripsi menu
  menu_image TEXT,                            -- Base64 atau URL gambar header
  
  -- Category Association
  cat_key TEXT NOT NULL,                      -- finance, scm, production, masterdata, atau custom
  cat_name TEXT NOT NULL,                     -- Nama kategori
  color TEXT NOT NULL,                        -- Warna hex (#xxxxxx)
  
  -- Metadata
  is_active BOOLEAN DEFAULT true,             -- Soft delete
  display_order INTEGER DEFAULT 0,            -- Urutan tampilan
  created_by TEXT,                            -- User ID atau email
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS menus_app_id_idx ON menus(app_id);
CREATE INDEX IF NOT EXISTS menus_cat_key_idx ON menus(cat_key);
CREATE INDEX IF NOT EXISTS menus_is_active_idx ON menus(is_active);
CREATE INDEX IF NOT EXISTS menus_display_order_idx ON menus(display_order);

-- Trigger auto-update
DROP TRIGGER IF EXISTS update_menus_updated_at ON menus;
CREATE TRIGGER update_menus_updated_at
  BEFORE UPDATE ON menus
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 3. TABEL CATEGORIES (untuk custom categories)
-- ============================================================================
-- Tabel ini menyimpan kategori custom yang dibuat user
-- Alternative dari menyimpan sebagai __cat_* di JSONB

CREATE TABLE IF NOT EXISTS categories (
  id BIGSERIAL PRIMARY KEY,
  cat_id TEXT NOT NULL UNIQUE,               -- Format: cat_{timestamp} atau custom
  app_id TEXT NOT NULL DEFAULT 'd365-dmk-v3',
  
  -- Category Information
  cat_name TEXT NOT NULL,                    -- Nama kategori
  cat_desc TEXT,                             -- Deskripsi kategori
  color TEXT NOT NULL,                       -- Warna hex
  guide TEXT,                                -- Panduan singkat
  guide_id TEXT,                             -- ID untuk navigasi
  
  -- Metadata
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS categories_app_id_idx ON categories(app_id);
CREATE INDEX IF NOT EXISTS categories_is_active_idx ON categories(is_active);

-- Trigger
DROP TRIGGER IF EXISTS update_categories_updated_at ON categories;
CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 4. TABEL STEPS (untuk custom steps)
-- ============================================================================
-- Tabel ini menyimpan langkah-langkah custom yang dibuat user

CREATE TABLE IF NOT EXISTS steps (
  id BIGSERIAL PRIMARY KEY,
  step_id TEXT NOT NULL UNIQUE,              -- Format: s{secId}_{timestamp} atau custom
  app_id TEXT NOT NULL DEFAULT 'd365-dmk-v3',
  
  -- Step Information
  sec_id TEXT NOT NULL,                      -- ID section/menu parent
  label TEXT NOT NULL,                       -- Judul langkah
  description TEXT,                          -- Deskripsi detail
  
  -- Images
  main_image TEXT,                           -- Base64 atau URL gambar utama
  extra_images JSONB DEFAULT '[]'::jsonb,    -- Array gambar tambahan
  
  -- Metadata
  is_custom BOOLEAN DEFAULT true,            -- Apakah custom atau built-in
  is_deleted BOOLEAN DEFAULT false,          -- Soft delete
  display_order INTEGER DEFAULT 0,           -- Urutan dalam section
  created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS steps_app_id_idx ON steps(app_id);
CREATE INDEX IF NOT EXISTS steps_sec_id_idx ON steps(sec_id);
CREATE INDEX IF NOT EXISTS steps_is_custom_idx ON steps(is_custom);
CREATE INDEX IF NOT EXISTS steps_is_deleted_idx ON steps(is_deleted);
CREATE INDEX IF NOT EXISTS steps_display_order_idx ON steps(display_order);

-- Trigger
DROP TRIGGER IF EXISTS update_steps_updated_at ON steps;
CREATE TRIGGER update_steps_updated_at
  BEFORE UPDATE ON steps
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 5. TABEL STEP_IMAGES (untuk menyimpan gambar terpisah)
-- ============================================================================
-- Tabel ini untuk menyimpan gambar dengan metadata lengkap
-- Alternatif dari menyimpan base64 di JSONB

CREATE TABLE IF NOT EXISTS step_images (
  id BIGSERIAL PRIMARY KEY,
  image_id TEXT NOT NULL UNIQUE,             -- UUID atau custom ID
  app_id TEXT NOT NULL DEFAULT 'd365-dmk-v3',
  
  -- Association
  step_id TEXT,                               -- ID step yang menggunakan gambar ini
  menu_id TEXT,                               -- ID menu (untuk menu images)
  image_type TEXT NOT NULL,                   -- 'step_main', 'step_extra', 'menu_header'
  
  -- Image Data
  image_data TEXT,                            -- Base64 encoded image
  image_url TEXT,                             -- URL jika disimpan di storage
  file_name TEXT,                             -- Original filename
  file_size INTEGER,                          -- Size in bytes
  mime_type TEXT,                             -- image/png, image/jpeg, etc
  
  -- Metadata
  display_order INTEGER DEFAULT 0,
  created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS step_images_app_id_idx ON step_images(app_id);
CREATE INDEX IF NOT EXISTS step_images_step_id_idx ON step_images(step_id);
CREATE INDEX IF NOT EXISTS step_images_menu_id_idx ON step_images(menu_id);
CREATE INDEX IF NOT EXISTS step_images_image_type_idx ON step_images(image_type);

-- Trigger
DROP TRIGGER IF EXISTS update_step_images_updated_at ON step_images;
CREATE TRIGGER update_step_images_updated_at
  BEFORE UPDATE ON step_images
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 6. TABEL DELETED_MODULES (tracking deleted items)
-- ============================================================================
-- Tabel untuk tracking item yang dihapus (soft delete history)

CREATE TABLE IF NOT EXISTS deleted_modules (
  id BIGSERIAL PRIMARY KEY,
  app_id TEXT NOT NULL DEFAULT 'd365-dmk-v3',
  module_id TEXT NOT NULL,                   -- ID dari item yang dihapus
  module_type TEXT NOT NULL,                 -- 'step', 'menu', 'category'
  deleted_data JSONB,                        -- Backup data yang dihapus
  deleted_by TEXT,
  deleted_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS deleted_modules_app_id_idx ON deleted_modules(app_id);
CREATE INDEX IF NOT EXISTS deleted_modules_module_id_idx ON deleted_modules(module_id);
CREATE INDEX IF NOT EXISTS deleted_modules_module_type_idx ON deleted_modules(module_type);

-- ============================================================================
-- 7. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
-- Enable RLS untuk keamanan, tapi allow semua untuk development
-- PENTING: Sesuaikan policies ini untuk production!

-- APP_DATA
ALTER TABLE app_data ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all for app_data" ON app_data;
CREATE POLICY "Allow all for app_data" ON app_data
  FOR ALL USING (true) WITH CHECK (true);

-- MENUS
ALTER TABLE menus ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all for menus" ON menus;
CREATE POLICY "Allow all for menus" ON menus
  FOR ALL USING (true) WITH CHECK (true);

-- CATEGORIES
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all for categories" ON categories;
CREATE POLICY "Allow all for categories" ON categories
  FOR ALL USING (true) WITH CHECK (true);

-- STEPS
ALTER TABLE steps ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all for steps" ON steps;
CREATE POLICY "Allow all for steps" ON steps
  FOR ALL USING (true) WITH CHECK (true);

-- STEP_IMAGES
ALTER TABLE step_images ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all for step_images" ON step_images;
CREATE POLICY "Allow all for step_images" ON step_images
  FOR ALL USING (true) WITH CHECK (true);

-- DELETED_MODULES
ALTER TABLE deleted_modules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all for deleted_modules" ON deleted_modules;
CREATE POLICY "Allow all for deleted_modules" ON deleted_modules
  FOR ALL USING (true) WITH CHECK (true);

-- ============================================================================
-- 8. HELPER VIEWS (optional - untuk query yang lebih mudah)
-- ============================================================================

-- View untuk melihat semua menus dengan step count
CREATE OR REPLACE VIEW menus_with_step_count AS
SELECT 
  m.*,
  COUNT(s.id) as step_count,
  COUNT(CASE WHEN s.is_deleted = false THEN 1 END) as active_step_count
FROM menus m
LEFT JOIN steps s ON s.sec_id = m.menu_id AND s.app_id = m.app_id
WHERE m.is_active = true
GROUP BY m.id;

-- View untuk melihat semua steps dengan image info
CREATE OR REPLACE VIEW steps_with_images AS
SELECT 
  s.*,
  COUNT(si.id) as image_count,
  json_agg(
    json_build_object(
      'image_id', si.image_id,
      'image_type', si.image_type,
      'image_url', si.image_url,
      'file_name', si.file_name
    ) ORDER BY si.display_order
  ) FILTER (WHERE si.id IS NOT NULL) as images
FROM steps s
LEFT JOIN step_images si ON si.step_id = s.step_id
WHERE s.is_deleted = false
GROUP BY s.id;

-- ============================================================================
-- 9. SAMPLE DATA (optional - untuk testing)
-- ============================================================================

-- Insert sample data jika belum ada
INSERT INTO app_data (app_id, data)
VALUES ('d365-dmk-v3', '{}'::jsonb)
ON CONFLICT (app_id) DO NOTHING;

-- ============================================================================
-- 10. MIGRATION HELPER FUNCTIONS (optional)
-- ============================================================================
-- Function untuk migrasi data dari JSONB blob ke normalized tables

CREATE OR REPLACE FUNCTION migrate_from_jsonb_to_normalized()
RETURNS TEXT AS $$
DECLARE
  app_record RECORD;
  menu_key TEXT;
  menu_data JSONB;
  step_key TEXT;
  step_data JSONB;
  result_text TEXT := '';
  menus_migrated INT := 0;
  steps_migrated INT := 0;
BEGIN
  -- Get app_data record
  SELECT * INTO app_record FROM app_data WHERE app_id = 'd365-dmk-v3' LIMIT 1;
  
  IF NOT FOUND THEN
    RETURN 'No app_data found for d365-dmk-v3';
  END IF;
  
  -- Migrate Menus (keys starting with __menu_)
  FOR menu_key, menu_data IN SELECT * FROM jsonb_each(app_record.data) WHERE key LIKE '__menu_%'
  LOOP
    INSERT INTO menus (
      menu_id, app_id, menu_name, menu_desc, menu_image,
      cat_key, cat_name, color
    ) VALUES (
      menu_data->>'menuId',
      'd365-dmk-v3',
      menu_data->>'menuName',
      menu_data->>'menuDesc',
      menu_data->>'menuImage',
      menu_data->>'catKey',
      menu_data->>'catName',
      menu_data->>'color'
    )
    ON CONFLICT (menu_id) DO UPDATE SET
      menu_name = EXCLUDED.menu_name,
      menu_desc = EXCLUDED.menu_desc,
      menu_image = EXCLUDED.menu_image,
      updated_at = NOW();
    
    menus_migrated := menus_migrated + 1;
  END LOOP;
  
  -- Migrate Custom Steps (has isCustom = true)
  FOR step_key, step_data IN 
    SELECT * FROM jsonb_each(app_record.data) 
    WHERE NOT key LIKE '__menu_%' 
      AND NOT key LIKE '__cat_%'
      AND NOT key LIKE '__deleted_%'
      AND (value->>'isCustom')::boolean = true
  LOOP
    INSERT INTO steps (
      step_id, app_id, sec_id, label, description,
      main_image, extra_images, is_custom
    ) VALUES (
      step_key,
      'd365-dmk-v3',
      step_data->>'secId',
      step_data->>'label',
      step_data->>'desc',
      step_data->>'img',
      COALESCE(step_data->'imgs2', '[]'::jsonb),
      true
    )
    ON CONFLICT (step_id) DO UPDATE SET
      label = EXCLUDED.label,
      description = EXCLUDED.description,
      main_image = EXCLUDED.main_image,
      extra_images = EXCLUDED.extra_images,
      updated_at = NOW();
    
    steps_migrated := steps_migrated + 1;
  END LOOP;
  
  result_text := format('Migration completed: %s menus, %s steps', menus_migrated, steps_migrated);
  RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 11. UTILITY FUNCTIONS
-- ============================================================================

-- Function untuk get menu by category
CREATE OR REPLACE FUNCTION get_menus_by_category(p_cat_key TEXT)
RETURNS TABLE (
  menu_id TEXT,
  menu_name TEXT,
  menu_desc TEXT,
  step_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.menu_id,
    m.menu_name,
    m.menu_desc,
    COUNT(s.id) as step_count
  FROM menus m
  LEFT JOIN steps s ON s.sec_id = m.menu_id AND s.is_deleted = false
  WHERE m.cat_key = p_cat_key AND m.is_active = true
  GROUP BY m.id, m.menu_id, m.menu_name, m.menu_desc
  ORDER BY m.display_order, m.created_at;
END;
$$ LANGUAGE plpgsql;

-- Function untuk get steps by menu
CREATE OR REPLACE FUNCTION get_steps_by_menu(p_menu_id TEXT)
RETURNS TABLE (
  step_id TEXT,
  label TEXT,
  description TEXT,
  main_image TEXT,
  image_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.step_id,
    s.label,
    s.description,
    s.main_image,
    COUNT(si.id) as image_count
  FROM steps s
  LEFT JOIN step_images si ON si.step_id = s.step_id
  WHERE s.sec_id = p_menu_id AND s.is_deleted = false
  GROUP BY s.id, s.step_id, s.label, s.description, s.main_image
  ORDER BY s.display_order, s.created_at;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 12. SELESAI!
-- ============================================================================
-- Database setup selesai. Langkah selanjutnya:
-- 1. Jalankan script ini di Supabase SQL Editor
-- 2. Verifikasi semua tabel sudah dibuat dengan: SELECT * FROM information_schema.tables WHERE table_schema = 'public';
-- 3. Test insert data dengan: INSERT INTO menus (menu_id, menu_name, cat_key, cat_name, color) VALUES ('test_menu', 'Test Menu', 'finance', 'Finance', '#3498db');
-- 4. (Optional) Jalankan migration: SELECT migrate_from_jsonb_to_normalized();
-- 5. Update kode aplikasi untuk menggunakan normalized tables (see: supabase-integration-guide.md)
-- ============================================================================

-- Grant permissions (jika diperlukan)
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- Log completion
DO $$
BEGIN
  RAISE NOTICE '✅ Database setup completed successfully!';
  RAISE NOTICE '📊 Tables created: app_data, menus, categories, steps, step_images, deleted_modules';
  RAISE NOTICE '👁️ Views created: menus_with_step_count, steps_with_images';
  RAISE NOTICE '🔧 Functions created: migrate_from_jsonb_to_normalized, get_menus_by_category, get_steps_by_menu';
  RAISE NOTICE '🔐 RLS enabled with allow-all policies (adjust for production!)';
END $$;
