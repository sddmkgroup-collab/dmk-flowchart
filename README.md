# D365 BC DMK Flowchart App — Vercel + Supabase

## 🚀 Quick Deploy ke Vercel

### Step 1: Setup Supabase

1. Login ke [supabase.com](https://supabase.com) → pilih project Anda
2. Buka **SQL Editor** → klik **New Query**
3. Copy-paste seluruh isi file `supabase-setup.sql` → klik **Run**
4. Buka **Settings → API** → catat:
   - `Project URL` (contoh: `https://abcde.supabase.co`)
   - `anon public` key

### Step 2: Konfigurasi File HTML

Buka file `public/index.html`, cari bagian ini (baris ~15):

```html
<script>
  window._SUPABASE_URL      = '';  // ← isi dengan Project URL Anda
  window._SUPABASE_ANON_KEY = '';  // ← isi dengan anon key Anda
</script>
```

Contoh setelah diisi:
```html
<script>
  window._SUPABASE_URL      = 'https://abcdefgh.supabase.co';
  window._SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
</script>
```

### Step 3: Deploy ke Vercel

**Cara A — Vercel CLI (recommended):**
```bash
npm install -g vercel
vercel login
vercel --prod
```

**Cara B — GitHub:**
1. Push folder ini ke GitHub repository
2. Buka [vercel.com](https://vercel.com) → **Add New Project**
3. Import repository → Deploy

### Step 4: Verifikasi

Setelah deploy, buka URL Vercel Anda. Di sidebar bawah akan muncul:
- 🟢 **Tersimpan di Supabase** — koneksi berhasil
- 🟠 **Mode Lokal (localStorage)** — periksa URL/Key Supabase

---

## 📁 Struktur Project

```
d365-dmk-app/
├── public/
│   └── index.html          ← Aplikasi utama (edit di sini)
├── api/
│   └── db.js               ← API handler (opsional, untuk server-side)
├── supabase-setup.sql       ← Script setup database Supabase
├── vercel.json              ← Konfigurasi Vercel
├── package.json
└── README.md
```

## ✨ Fitur Baru v3.1

- **＋ Tambah Menu** di setiap kategori (Finance, Supply Chain, Production, Master Data)
- **Payment Journal** ditambahkan di kategori Finance
- **Supabase integration** — data tersimpan di cloud, bukan hanya browser
- **Auto-fallback** ke localStorage jika Supabase tidak tersedia
- **Status indicator** di sidebar (hijau = cloud, kuning = lokal)

## 🔑 Tips Keamanan

- Untuk production, aktifkan **Row Level Security (RLS)** di Supabase
- Jangan commit file dengan `_SUPABASE_ANON_KEY` yang sudah diisi ke repository publik
- Gunakan Vercel Environment Variables untuk menyimpan kredensial

