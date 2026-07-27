# 🎯 Solusi Database Supabase - Quick Start

## 📦 File yang Telah Dibuat

Saya telah membuatkan **3 file** untuk setup database Supabase Anda:

### 1. **`supabase-database-setup.sql`** ⭐ LENGKAP
**Isi**: Setup database LENGKAP dari nol
- ✅ 6 Tabel baru (app_data, menus, categories, steps, step_images, deleted_modules)
- ✅ Indexes untuk performa
- ✅ Auto-update triggers
- ✅ RLS (Row Level Security) policies
- ✅ Helper functions untuk query
- ✅ Migration function dari JSONB ke normalized tables

**Kapan pakai**: Jika Anda ingin setup database dari awal atau rebuild semua tabel

---

### 2. **`supabase-add-fields-to-existing-tables.sql`** 🔧 QUICK FIX
**Isi**: Menambahkan field ke tabel yang SUDAH ADA
- ✅ Update `step_images` dengan field baru
- ✅ Update `step_images_public` dengan field baru
- ✅ Update `menus` jika sudah ada
- ✅ AMAN dijalankan berulang kali (tidak akan duplicate/error)

**Kapan pakai**: Jika tabel `step_images` dan `menus` sudah ada, tapi kurang field

---

### 3. **`SUPABASE-DATABASE-GUIDE.md`** 📚 DOKUMENTASI
**Isi**: Panduan lengkap dan penjelasan
- ✅ Struktur setiap tabel dengan detail field
- ✅ Penjelasan fungsi masing-masing kolom
- ✅ Contoh query SQL
- ✅ Strategi implementasi (JSONB vs Normalized)
- ✅ Contoh kode untuk dual-write
- ✅ Troubleshooting guide

**Kapan baca**: Untuk memahami struktur database dan cara implementasi

---

## 🚀 Langkah Setup CEPAT (5 Menit)

### **Skenario A: Tabel Belum Ada / Setup Baru**

1. **Buka Supabase Dashboard**
   - Login ke https://supabase.com
   - Pilih project Anda

2. **Buka SQL Editor**
   - Klik **SQL Editor** di sidebar kiri
   - Klik **New Query**

3. **Jalankan SQL Setup**
   - Buka file `supabase-database-setup.sql`
   - Copy **SELURUH ISI FILE**
   - Paste ke SQL Editor
   - Klik **Run** (atau Ctrl+Enter)
   - ⏳ Tunggu ~10 detik sampai selesai

4. **Verifikasi**
   ```sql
   -- Cek tabel yang dibuat
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   ORDER BY table_name;
   ```
   Harusnya muncul minimal: `app_data`, `menus`, `steps`, dll

5. **Test Insert**
   ```sql
   -- Test insert ke app_data
   INSERT INTO app_data (app_id, data) 
   VALUES ('d365-dmk-v3', '{}'::jsonb);
   
   -- Verify
   SELECT * FROM app_data;
   ```

6. **✅ Selesai!** Refresh aplikasi dan coba tambah menu/step

---

### **Skenario B: Tabel Sudah Ada (step_images, menus)**

1. **Buka Supabase SQL Editor**

2. **Jalankan Update Script**
   - Buka file `supabase-add-fields-to-existing-tables.sql`
   - Copy SELURUH ISI
   - Paste ke SQL Editor
   - Klik **Run**

3. **Verifikasi Field Baru**
   ```sql
   -- Cek kolom di step_images
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'step_images';
   ```

4. **Pastikan `app_data` Ada**
   - Jika belum ada, jalankan juga section 1 dari `supabase-database-setup.sql`
   - Hanya copy dari baris 1-50 (CREATE TABLE app_data sampai RLS policy)

5. **✅ Selesai!**

---

## 📊 Struktur Database yang Akan Dibuat

| Tabel | Field Utama | Fungsi |
|-------|-------------|--------|
| **app_data** | `id`, `app_id`, `data:jsonb`, `created_at`, `updated_at` | Simpan semua data sebagai JSON (current) |
| **menus** | `id`, `menu_id`, `menu_name`, `menu_desc`, `cat_key`, `color`, `menu_image` | Custom menus yang dibuat user |
| **categories** | `id`, `cat_id`, `cat_name`, `color`, `guide` | Custom categories |
| **steps** | `id`, `step_id`, `sec_id`, `label`, `description`, `main_image`, `extra_images` | Custom steps/langkah |
| **step_images** | `id`, `image_id`, `step_id`, `menu_id`, `image_data`, `image_url`, `file_name` | Gambar dengan metadata |
| **deleted_modules** | `id`, `module_id`, `module_type`, `deleted_data`, `deleted_at` | History item yang dihapus |

---

## 💡 Rekomendasi Field untuk Tabel Existing

### **Tabel `step_images` (yang sudah ada)**
**Tambahkan field ini**:
- ✅ `image_id` (TEXT) - Unique identifier
- ✅ `step_id` (TEXT) - Link ke step mana gambar ini
- ✅ `menu_id` (TEXT) - Link ke menu mana gambar ini
- ✅ `image_type` (TEXT) - Jenis: 'step_main', 'step_extra', 'menu_header'
- ✅ `file_name` (TEXT) - Nama file original
- ✅ `file_size` (INTEGER) - Ukuran file dalam bytes
- ✅ `mime_type` (TEXT) - image/png, image/jpeg, dll
- ✅ `display_order` (INTEGER) - Urutan tampilan gambar

### **Tabel `menus` (yang sudah ada)**
**Tambahkan field ini**:
- ✅ `menu_id` (TEXT) - Unique identifier
- ✅ `menu_name` (TEXT) - Nama menu
- ✅ `menu_desc` (TEXT) - Deskripsi
- ✅ `cat_key` (TEXT) - Category key (finance, scm, production, dll)
- ✅ `cat_name` (TEXT) - Nama kategori
- ✅ `color` (TEXT) - Warna hex (#xxxxxx)
- ✅ `is_active` (BOOLEAN) - Status aktif (untuk soft delete)
- ✅ `display_order` (INTEGER) - Urutan tampilan

### **Tabel `app_data` (yang sudah ada)**
**Field saat ini sudah CUKUP**, tidak perlu tambahan!

### **Tabel `step_images_public`**
**Tambahkan field yang sama** dengan `step_images` di atas

---

## 🎯 Pilih Strategi Implementasi

### **Opsi 1: Tetap Pakai JSONB (Quick Fix)** ✅ TERCEPAT

**Langkah**:
1. Jalankan **HANYA section 1** dari `supabase-database-setup.sql` (CREATE TABLE app_data)
2. Pastikan RLS policy untuk `app_data` di-enable
3. **TIDAK PERLU ubah kode aplikasi**
4. Data tetap tersimpan sebagai JSON di kolom `data`

**Kelebihan**:
- ✅ Tidak perlu ubah kode
- ✅ Setup 2 menit
- ✅ Langsung bisa dipakai

**Kekurangan**:
- ❌ Query kompleks lebih lambat
- ❌ Sulit untuk reporting

---

### **Opsi 2: Pakai Normalized Tables (Best Practice)** ⭐ RECOMMENDED LONG TERM

**Langkah**:
1. Jalankan **SEMUA** `supabase-database-setup.sql`
2. Update kode aplikasi untuk dual-write (simpan ke JSONB + normalized tables)
3. Benefit: Performa query cepat, data terstruktur, mudah analytics

**Kelebihan**:
- ✅ Performa sangat cepat
- ✅ Data terstruktur dengan baik
- ✅ Foreign key constraints
- ✅ Mudah untuk reporting/analytics

**Kekurangan**:
- ❌ Perlu update kode aplikasi (lihat contoh di GUIDE.md)
- ❌ Setup 30 menit

---

## 🐛 Troubleshooting

### **Error: "relation app_data does not exist"**
**Solusi**: Jalankan section 1 dari `supabase-database-setup.sql`

### **Error: HTTP 500 saat save**
**Solusi**: 
1. Cek RLS policy: Pastikan ada policy "Allow all"
2. Re-run SQL setup
3. Ketik `resetSupabaseSync()` di browser console

### **Field tidak muncul di tabel**
**Solusi**: Jalankan `supabase-add-fields-to-existing-tables.sql`

### **Data tidak masuk ke Supabase**
**Solusi**:
1. Buka browser console (F12)
2. Lihat error logs
3. Pastikan `_SUPABASE_URL` dan `_SUPABASE_ANON_KEY` terisi
4. Cek di console: `console.log(SUPABASE_URL, SUPABASE_ANON_KEY)`

---

## ✅ Checklist Setelah Setup

- [ ] Tabel `app_data` sudah dibuat di Supabase
- [ ] RLS policy enabled dengan "Allow all"
- [ ] Test insert data sukses
- [ ] Refresh aplikasi, buka browser console (F12)
- [ ] Coba tambah menu baru → cek console log → cek Supabase Table Editor
- [ ] Coba tambah step baru → cek console log → cek Supabase Table Editor
- [ ] Jika ada error, screenshot console dan cek Supabase logs

---

## 📞 Next Steps

1. **Pilih strategi** (JSONB atau Normalized)
2. **Jalankan SQL** yang sesuai
3. **Test** dengan data dummy
4. **Monitor** logs di browser console
5. **Adjust** jika ada error

**Jika masih ada HTTP 500**, buka console browser dan screenshot error untuk analisis lebih lanjut!

---

## 📚 File Reference

| File | Kapan Pakai |
|------|-------------|
| `supabase-database-setup.sql` | Setup database LENGKAP dari nol |
| `supabase-add-fields-to-existing-tables.sql` | Update tabel yang sudah ada |
| `SUPABASE-DATABASE-GUIDE.md` | Baca untuk dokumentasi lengkap |

**Bingung?** Baca `SUPABASE-DATABASE-GUIDE.md` untuk penjelasan detail!
