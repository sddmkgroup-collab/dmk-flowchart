# 📊 Panduan Database Supabase untuk D365 BC User Manual v3

## 🎯 Ringkasan Solusi

Saat ini aplikasi Anda menggunakan **"JSONB Blob Pattern"** di tabel `app_data`, di mana semua data (menus, steps, categories) disimpan sebagai satu object JSON besar. 

**Solusi yang kami tawarkan**: **Hybrid Approach**
- ✅ **Tetap gunakan `app_data`** untuk kompatibilitas dengan kode yang ada
- ✅ **Tambahkan normalized tables** (`menus`, `steps`, `categories`) untuk performa dan query yang lebih baik
- ✅ **Dual-write strategy**: Simpan ke kedua lokasi untuk fleksibilitas maksimal

---

## 📋 Struktur Database Lengkap

### **Tabel 1: `app_data` (Primary - sudah ada)**

**Fungsi**: Menyimpan semua data sebagai JSONB blob (current implementation)

| Field | Type | Keterangan |
|-------|------|-----------|
| `id` | BIGSERIAL | Primary key |
| `app_id` | TEXT | Identifier aplikasi (default: `d365-dmk-v3`) |
| `data` | JSONB | Object JSON berisi semua data |
| `created_at` | TIMESTAMPTZ | Timestamp pembuatan |
| `updated_at` | TIMESTAMPTZ | Timestamp update terakhir (auto-update) |

**Index**:
- Unique index pada `app_id`
- GIN index pada `data` untuk fast JSONB queries

**Data Structure dalam JSONB**:
```json
{
  "__menu_finance_menu_1234567890": {
    "catKey": "finance",
    "catName": "Finance",
    "color": "#3498db",
    "menuName": "Purchase Order Process",
    "menuDesc": "Cara membuat PO",
    "menuId": "finance_menu_1234567890",
    "menuImage": "data:image/png;base64,..."
  },
  "__cat_custom_5678": {
    "name": "Custom Category",
    "color": "#e74c3c",
    "guide": "Panduan custom",
    "desc": "Deskripsi category",
    "guideId": "custom_5678"
  },
  "sfinance_menu_1234567890_9999": {
    "label": "Step 1: Buat PO",
    "desc": "Klik tombol New",
    "isCustom": true,
    "secId": "finance_menu_1234567890",
    "img": "data:image/png;base64,..  .",
    "imgs2": ["data:image/png;base64,..."]
  },
  "__deleted_module_finance_old": true
}
```

---

### **Tabel 2: `menus` (New - Normalized)**

**Fungsi**: Menyimpan custom menus dengan struktur relational

| Field | Type | Nullable | Default | Keterangan |
|-------|------|----------|---------|-----------|
| `id` | BIGSERIAL | No | Auto | Primary key |
| `menu_id` | TEXT | No | - | Unique ID (format: `{catKey}_menu_{timestamp}`) |
| `app_id` | TEXT | No | `d365-dmk-v3` | Application identifier |
| `menu_name` | TEXT | No | - | Nama menu yang ditampilkan |
| `menu_desc` | TEXT | Yes | NULL | Deskripsi menu |
| `menu_image` | TEXT | Yes | NULL | Base64 image atau URL |
| `cat_key` | TEXT | No | - | Category key (finance/scm/production/masterdata/custom) |
| `cat_name` | TEXT | No | - | Nama kategori |
| `color` | TEXT | No | - | Hex color code (#xxxxxx) |
| `is_active` | BOOLEAN | No | true | Status aktif (soft delete) |
| `display_order` | INTEGER | No | 0 | Urutan tampilan |
| `created_by` | TEXT | Yes | NULL | User ID/email pembuat |
| `created_at` | TIMESTAMPTZ | No | NOW() | Timestamp pembuatan |
| `updated_at` | TIMESTAMPTZ | No | NOW() | Auto-update timestamp |

**Indexes**:
- Unique pada `menu_id`
- Index pada `app_id`, `cat_key`, `is_active`, `display_order`

**Contoh Data**:
```sql
INSERT INTO menus (menu_id, menu_name, menu_desc, cat_key, cat_name, color)
VALUES (
  'finance_menu_1721836800000',
  'Purchase Order Process',
  'Panduan lengkap membuat dan mengelola Purchase Order',
  'finance',
  'Finance',
  '#3498db'
);
```

---

### **Tabel 3: `categories` (New - Normalized)**

**Fungsi**: Menyimpan custom categories yang dibuat user

| Field | Type | Nullable | Default | Keterangan |
|-------|------|----------|---------|-----------|
| `id` | BIGSERIAL | No | Auto | Primary key |
| `cat_id` | TEXT | No | - | Unique ID (format: `cat_{timestamp}`) |
| `app_id` | TEXT | No | `d365-dmk-v3` | Application identifier |
| `cat_name` | TEXT | No | - | Nama kategori |
| `cat_desc` | TEXT | Yes | NULL | Deskripsi kategori |
| `color` | TEXT | No | - | Hex color code |
| `guide` | TEXT | Yes | NULL | Panduan singkat |
| `guide_id` | TEXT | Yes | NULL | ID untuk navigasi |
| `is_active` | BOOLEAN | No | true | Status aktif |
| `display_order` | INTEGER | No | 0 | Urutan tampilan |
| `created_by` | TEXT | Yes | NULL | User ID/email pembuat |
| `created_at` | TIMESTAMPTZ | No | NOW() | Timestamp pembuatan |
| `updated_at` | TIMESTAMPTZ | No | NOW() | Auto-update timestamp |

**Indexes**:
- Unique pada `cat_id`
- Index pada `app_id`, `is_active`

---

### **Tabel 4: `steps` (New - Normalized)**

**Fungsi**: Menyimpan langkah-langkah (steps) custom

| Field | Type | Nullable | Default | Keterangan |
|-------|------|----------|---------|-----------|
| `id` | BIGSERIAL | No | Auto | Primary key |
| `step_id` | TEXT | No | - | Unique ID (format: `s{secId}_{timestamp}`) |
| `app_id` | TEXT | No | `d365-dmk-v3` | Application identifier |
| `sec_id` | TEXT | No | - | Parent menu/section ID |
| `label` | TEXT | No | - | Judul langkah |
| `description` | TEXT | Yes | NULL | Deskripsi detail |
| `main_image` | TEXT | Yes | NULL | Base64 gambar utama |
| `extra_images` | JSONB | No | `[]` | Array gambar tambahan |
| `is_custom` | BOOLEAN | No | true | Flag custom vs built-in |
| `is_deleted` | BOOLEAN | No | false | Soft delete flag |
| `display_order` | INTEGER | No | 0 | Urutan dalam section |
| `created_by` | TEXT | Yes | NULL | User ID/email pembuat |
| `created_at` | TIMESTAMPTZ | No | NOW() | Timestamp pembuatan |
| `updated_at` | TIMESTAMPTZ | No | NOW() | Auto-update timestamp |

**Indexes**:
- Unique pada `step_id`
- Index pada `app_id`, `sec_id`, `is_custom`, `is_deleted`, `display_order`

**Contoh Data**:
```sql
INSERT INTO steps (step_id, sec_id, label, description, main_image)
VALUES (
  'sfinance_menu_1721836800000_1',
  'finance_menu_1721836800000',
  'Step 1: Buka Purchase Order',
  'Dari menu utama, klik Purchasing → Purchase Orders',
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUg...'
);
```

---

### **Tabel 5: `step_images` (Enhanced)**

**Fungsi**: Menyimpan gambar dengan metadata lengkap

| Field | Type | Nullable | Default | Keterangan |
|-------|------|----------|---------|-----------|
| `id` | BIGSERIAL | No | Auto | Primary key |
| `image_id` | TEXT | No | - | Unique ID (UUID) |
| `app_id` | TEXT | No | `d365-dmk-v3` | Application identifier |
| `step_id` | TEXT | Yes | NULL | Foreign key ke `steps.step_id` |
| `menu_id` | TEXT | Yes | NULL | Foreign key ke `menus.menu_id` |
| `image_type` | TEXT | No | - | Type: `step_main`, `step_extra`, `menu_header` |
| `image_data` | TEXT | Yes | NULL | Base64 encoded image |
| `image_url` | TEXT | Yes | NULL | URL jika pakai Supabase Storage |
| `file_name` | TEXT | Yes | NULL | Original filename |
| `file_size` | INTEGER | Yes | NULL | Size in bytes |
| `mime_type` | TEXT | Yes | NULL | MIME type (image/png, image/jpeg) |
| `display_order` | INTEGER | No | 0 | Urutan gambar |
| `created_by` | TEXT | Yes | NULL | User ID/email pembuat |
| `created_at` | TIMESTAMPTZ | No | NOW() | Timestamp pembuatan |
| `updated_at` | TIMESTAMPTZ | No | NOW() | Auto-update timestamp |

**Indexes**:
- Unique pada `image_id`
- Index pada `app_id`, `step_id`, `menu_id`, `image_type`

---

### **Tabel 6: `deleted_modules` (New - Audit Trail)**

**Fungsi**: Tracking items yang dihapus (soft delete history)

| Field | Type | Nullable | Default | Keterangan |
|-------|------|----------|---------|-----------|
| `id` | BIGSERIAL | No | Auto | Primary key |
| `app_id` | TEXT | No | `d365-dmk-v3` | Application identifier |
| `module_id` | TEXT | No | - | ID item yang dihapus |
| `module_type` | TEXT | No | - | Type: `step`, `menu`, `category` |
| `deleted_data` | JSONB | Yes | NULL | Backup data sebelum dihapus |
| `deleted_by` | TEXT | Yes | NULL | User ID/email yang menghapus |
| `deleted_at` | TIMESTAMPTZ | No | NOW() | Timestamp penghapusan |

**Indexes**:
- Index pada `app_id`, `module_id`, `module_type`

---

## 🚀 Cara Setup Database

### **Step 1: Jalankan SQL Script**

1. Buka **Supabase Dashboard** → pilih project Anda
2. Klik **SQL Editor** di sidebar kiri
3. Klik **New Query**
4. Copy seluruh isi file `supabase-database-setup.sql`
5. Paste ke SQL Editor
6. Klik **Run** (atau tekan Ctrl+Enter)
7. Tunggu sampai selesai (akan muncul notifikasi sukses)

### **Step 2: Verifikasi Tabel**

Jalankan query ini untuk memastikan semua tabel sudah dibuat:

```sql
SELECT 
  table_name, 
  table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
  AND table_name IN ('app_data', 'menus', 'categories', 'steps', 'step_images', 'deleted_modules')
ORDER BY table_name;
```

Harusnya muncul 6 tabel.

### **Step 3: Test Insert Data**

```sql
-- Test insert menu
INSERT INTO menus (menu_id, menu_name, cat_key, cat_name, color)
VALUES ('test_menu_001', 'Test Menu', 'finance', 'Finance', '#3498db');

-- Test insert step
INSERT INTO steps (step_id, sec_id, label, description)
VALUES ('stest_menu_001_1', 'test_menu_001', 'Test Step', 'This is a test step');

-- Verify
SELECT * FROM menus WHERE menu_id = 'test_menu_001';
SELECT * FROM steps WHERE step_id = 'stest_menu_001_1';
```

### **Step 4: (Optional) Migrasi Data Existing**

Jika Anda sudah punya data di `app_data.data` (JSONB), jalankan function migration:

```sql
SELECT migrate_from_jsonb_to_normalized();
```

Function ini akan:
- Membaca semua `__menu_*` dari JSONB dan insert ke tabel `menus`
- Membaca semua custom steps (yang punya `isCustom: true`) dan insert ke tabel `steps`
- Men-skip data yang sudah ada (ON CONFLICT)

---

## 💡 Strategi Implementasi

### **Pilihan 1: Tetap Pakai JSONB (Quick Fix) ✅ RECOMMENDED**

**Kelebihan**:
- ✅ Tidak perlu ubah kode aplikasi
- ✅ Setup cepat (tinggal jalankan SQL untuk `app_data` saja)
- ✅ Kompatibel dengan kode yang ada

**Kekurangan**:
- ❌ Query kompleks lebih lambat
- ❌ Sulit untuk reporting/analytics
- ❌ Tidak ada foreign key constraint

**Yang perlu dilakukan**:
```sql
-- Cukup jalankan section 1 dari supabase-database-setup.sql
CREATE TABLE IF NOT EXISTS app_data (
  id BIGSERIAL PRIMARY KEY,
  app_id TEXT NOT NULL,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Plus RLS policies dan indexes
```

**Kode aplikasi tetap sama**, tidak perlu perubahan!

---

### **Pilihan 2: Hybrid Approach (Best Practice) ⭐ LONG TERM**

**Kelebihan**:
- ✅ Performa query sangat cepat
- ✅ Data terstruktur dengan baik
- ✅ Mudah untuk analytics dan reporting
- ✅ Foreign key constraints
- ✅ Tetap ada backup di JSONB

**Kekurangan**:
- ❌ Perlu update kode aplikasi
- ❌ Dual-write (simpan ke 2 tempat)

**Yang perlu dilakukan**:
1. Jalankan **semua** SQL di `supabase-database-setup.sql`
2. Update kode aplikasi untuk dual-write

---

## 🔧 Contoh Kode untuk Dual-Write Strategy

### **Sebelum (JSONB Only)**:

```javascript
async function confirmAddMenu() {
  const saved = getSaved();
  const menuId = catKey + '_menu_' + Date.now();
  
  // Simpan ke JSONB
  saved['__menu_' + menuId] = {
    catKey, catName, color, menuName, menuDesc, menuId, menuImage
  };
  
  await saveToDB(saved);
}
```

### **Sesudah (Dual-Write)**:

```javascript
async function confirmAddMenu() {
  const saved = getSaved();
  const menuId = catKey + '_menu_' + Date.now();
  
  // 1. Simpan ke JSONB (backward compatibility)
  saved['__menu_' + menuId] = {
    catKey, catName, color, menuName, menuDesc, menuId, menuImage
  };
  await saveToDB(saved);
  
  // 2. Simpan ke normalized table (new way)
  await saveMenuToNormalizedTable({
    menuId, menuName, menuDesc, menuImage,
    catKey, catName, color
  });
}

async function saveMenuToNormalizedTable(menuData) {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) return;
  
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/menus`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
      },
      body: JSON.stringify({
        menu_id: menuData.menuId,
        menu_name: menuData.menuName,
        menu_desc: menuData.menuDesc,
        menu_image: menuData.menuImage,
        cat_key: menuData.catKey,
        cat_name: menuData.catName,
        color: menuData.color
      })
    });
    
    if (!res.ok) {
      console.warn('Failed to save to normalized table:', res.status);
    } else {
      console.log('✅ Menu saved to normalized table');
    }
  } catch (err) {
    console.error('Error saving to normalized table:', err);
  }
}
```

---

## 📊 Query Examples (Normalized Tables)

### **Get All Menus by Category**:
```sql
SELECT * FROM menus 
WHERE cat_key = 'finance' 
  AND is_active = true 
ORDER BY display_order, created_at;
```

### **Get Steps for a Menu**:
```sql
SELECT * FROM steps 
WHERE sec_id = 'finance_menu_1721836800000' 
  AND is_deleted = false 
ORDER BY display_order, created_at;
```

### **Get Menu with Step Count**:
```sql
SELECT 
  m.*,
  COUNT(s.id) as step_count
FROM menus m
LEFT JOIN steps s ON s.sec_id = m.menu_id AND s.is_deleted = false
WHERE m.menu_id = 'finance_menu_1721836800000'
GROUP BY m.id;
```

### **Search Steps by Label**:
```sql
SELECT 
  s.*,
  m.menu_name,
  m.cat_name
FROM steps s
LEFT JOIN menus m ON m.menu_id = s.sec_id
WHERE s.label ILIKE '%purchase order%'
  AND s.is_deleted = false
ORDER BY s.created_at DESC;
```

---

## 🎯 Rekomendasi Field untuk Database Anda

Berdasarkan analisis aplikasi, berikut field yang **perlu ditambahkan**:

### **Tabel `app_data` (sudah ada)** ✅
**Status**: Sudah lengkap, tidak perlu tambahan field

### **Tabel `menus` (belum ada)** ⭐
**Perlu dibuat** dengan field:
- ✅ `menu_id`, `menu_name`, `menu_desc`, `menu_image`
- ✅ `cat_key`, `cat_name`, `color`
- ✅ `is_active`, `display_order`
- ✅ `created_at`, `updated_at`

### **Tabel `categories` (belum ada)** ⭐
**Perlu dibuat** dengan field:
- ✅ `cat_id`, `cat_name`, `cat_desc`
- ✅ `color`, `guide`, `guide_id`
- ✅ `is_active`, `display_order`

### **Tabel `steps` (belum ada)** ⭐
**Perlu dibuat** dengan field:
- ✅ `step_id`, `sec_id`, `label`, `description`
- ✅ `main_image`, `extra_images` (JSONB array)
- ✅ `is_custom`, `is_deleted`, `display_order`

### **Tabel `step_images` (sudah ada)** 🔧
**Perlu ditambahkan field**:
- ➕ `image_type` (TEXT) - untuk membedakan jenis gambar
- ➕ `step_id` (TEXT) - foreign key ke steps
- ➕ `menu_id` (TEXT) - foreign key ke menus
- ➕ `file_name` (TEXT) - nama file asli
- ➕ `file_size` (INTEGER) - ukuran file
- ➕ `mime_type` (TEXT) - tipe file
- ➕ `display_order` (INTEGER) - urutan gambar

```sql
-- Jika tabel step_images sudah ada, tambahkan field baru:
ALTER TABLE step_images 
  ADD COLUMN IF NOT EXISTS image_type TEXT,
  ADD COLUMN IF NOT EXISTS step_id TEXT,
  ADD COLUMN IF NOT EXISTS menu_id TEXT,
  ADD COLUMN IF NOT EXISTS file_name TEXT,
  ADD COLUMN IF NOT EXISTS file_size INTEGER,
  ADD COLUMN IF NOT EXISTS mime_type TEXT,
  ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;

-- Tambahkan indexes
CREATE INDEX IF NOT EXISTS step_images_step_id_idx ON step_images(step_id);
CREATE INDEX IF NOT EXISTS step_images_menu_id_idx ON step_images(menu_id);
CREATE INDEX IF NOT EXISTS step_images_type_idx ON step_images(image_type);
```

### **Tabel `step_images_public` (sudah ada)** ℹ️
**Status**: Kemungkinan untuk public access, bisa dipakai untuk:
- Gambar yang bisa diakses tanpa authentication
- URL sharing untuk eksternal
- CDN integration

**Rekomendasi**: Tambahkan field yang sama dengan `step_images`

---

## 🔒 Row Level Security (RLS) Policies

SQL setup sudah include RLS dengan policy "Allow All" untuk development.

**⚠️ PENTING untuk Production**:

```sql
-- Ubah policy untuk production (contoh: user hanya bisa edit data sendiri)

-- Hapus policy "Allow All"
DROP POLICY "Allow all for menus" ON menus;

-- Buat policy baru berdasarkan user
CREATE POLICY "Users can view all menus" ON menus
  FOR SELECT USING (true);

CREATE POLICY "Users can insert own menus" ON menus
  FOR INSERT WITH CHECK (auth.uid()::text = created_by);

CREATE POLICY "Users can update own menus" ON menus
  FOR UPDATE USING (auth.uid()::text = created_by);

CREATE POLICY "Users can delete own menus" ON menus
  FOR DELETE USING (auth.uid()::text = created_by);
```

---

## ✅ Checklist Setup

### **Quick Setup (Tetap Pakai JSONB)** - 5 menit
- [ ] Jalankan section 1-7 dari `supabase-database-setup.sql` (hanya `app_data`)
- [ ] Verifikasi tabel `app_data` sudah dibuat
- [ ] Test insert data ke `app_data`
- [ ] Refresh aplikasi, coba tambah menu/step
- [ ] Cek di Supabase Table Editor apakah data masuk

### **Full Setup (Normalized Tables)** - 30 menit
- [ ] Jalankan **semua** `supabase-database-setup.sql`
- [ ] Verifikasi 6 tabel sudah dibuat
- [ ] (Optional) Jalankan `SELECT migrate_from_jsonb_to_normalized();`
- [ ] Test query di SQL Editor
- [ ] Update kode aplikasi untuk dual-write (lihat contoh di atas)
- [ ] Test end-to-end: tambah menu → cek di tabel `menus`
- [ ] Test end-to-end: tambah step → cek di tabel `steps`

---

## 🆘 Troubleshooting

### **Error: "relation app_data does not exist"**
**Solusi**: Jalankan SQL setup untuk membuat tabel

### **Error: HTTP 500 saat save**
**Penyebab**: Tabel belum dibuat atau RLS terlalu ketat
**Solusi**: 
1. Cek tabel ada: `SELECT * FROM app_data;`
2. Cek RLS: `SELECT * FROM pg_policies WHERE tablename = 'app_data';`
3. Re-run SQL setup

### **Error: "duplicate key value violates unique constraint"**
**Penyebab**: Insert data dengan ID yang sudah ada
**Solusi**: Gunakan `ON CONFLICT` clause
```sql
INSERT INTO menus (...) VALUES (...)
ON CONFLICT (menu_id) DO UPDATE SET updated_at = NOW();
```

### **Data tidak muncul setelah refresh**
**Penyebab**: Data hanya tersimpan di localStorage, tidak ke Supabase
**Solusi**: 
1. Buka console browser (F12)
2. Cek log untuk error Supabase
3. Ketik `resetSupabaseSync()` jika sync disabled
4. Refresh halaman

---

## 📚 Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL JSON Functions](https://www.postgresql.org/docs/current/functions-json.html)
- [Supabase RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgREST API Documentation](https://postgrest.org/en/stable/)

---

## 🎉 Selesai!

Anda sekarang punya:
- ✅ Database schema yang lengkap dan terstruktur
- ✅ Backward compatibility dengan kode yang ada
- ✅ Persiapan untuk scaling dan performa tinggi
- ✅ Audit trail untuk tracking changes

**Next Steps**:
1. Jalankan SQL setup
2. Test dengan data dummy
3. (Optional) Implement dual-write di aplikasi
4. Monitor performa dan adjust sesuai kebutuhan

**Questions?** Check error logs di browser console dan Supabase logs!
