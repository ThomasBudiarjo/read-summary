# Read Summary

Situs ringkasan buku berbahasa Indonesia, dibuat dengan Hugo dan tema Hextra.

## Prasyarat

- Git
- Go 1.21 atau lebih baru
- Hugo Extended 0.168.0 (minimal 0.146.0)

Setelah repositori di-clone, unduh tema dan modul:

```bash
hugo mod download
```

## Menjalankan dan membangun situs

Pratinjau lokal, termasuk konten berstatus draf:

```bash
hugo server -D
```

Buat hasil produksi di `public/`:

```bash
hugo --gc --minify
```

Jalankan pemeriksaan lengkap situs:

```bash
bash scripts/check-site.sh
```

## Menambah buku dan bab

Gunakan slug huruf kecil dengan tanda hubung. Buat halaman buku terlebih dahulu:

```bash
hugo new content --kind buku buku/nama-buku/_index.md
```

Kemudian buat ringkasan bab di direktori buku tersebut:

```bash
hugo new content --kind bab buku/nama-buku/bab-1-nama-bab.md
```

Sunting file yang dihasilkan di `content/buku/nama-buku/`. Ganti seluruh teks petunjuk pada templat.

- `weight` menentukan urutan menaik. Atur `weight` buku di antara buku lain dan `weight` setiap bab menjadi `1`, `2`, `3`, dan seterusnya.
- Buku baru membuka daftar bab di sidebar melalui `sidebar.open: true`.
- Bab baru dibuat dengan `draft: true`. Pratinjau dengan `hugo server -D`, lalu ubah menjadi `draft: false` ketika siap diterbitkan.

## Deployment ke GitHub Pages

Satu kali saja, buka **Settings → Pages → Build and deployment**, lalu pilih **GitHub Actions** sebagai **Source**. Setelah itu:

1. Commit perubahan konten dan push ke branch `main`.
2. Workflow GitHub Pages membangun dan menerbitkan situs secara otomatis.
3. Periksa hasilnya di `https://thomasbudiarjo.github.io/read-summary/`.

Sebelum push, jalankan `bash scripts/check-site.sh` agar build dan navigasi tervalidasi.

## Gambar buku

Grafik yang sudah selesai disimpan sebagai PNG di `static/images/buku/<slug>/`, lalu ditampilkan dengan shortcode `bookfigure`:

```markdown
{{</* bookfigure src="images/buku/nama-buku/hlm-6.png" alt="Deskripsi singkat dalam bahasa Indonesia." source="Nama sumber" page="6" */>}}
```

Shortcode membuat gambar selebar konten, dengan sudut membulat dan kartu putih agar tetap terbaca di mode gelap. `alt` menjelaskan isi gambar. Keterangan di bawahnya memakai `source` dan nomor halaman cetak pada `page`.

Tabel angka asli tetap di bawah gambar, di dalam blok tertutup:

```markdown
{{</* details title="Data sumber grafik (hlm. 6)" closed="true" */>}}
| Kolom | Nilai |
|---|---|
| Contoh | 1 |
{{</* /details */>}}
```

Gambar yang sumbu, koordinat, atau labelnya tidak terbaca tidak ditampilkan. Catatan `[tidak jelas]` tetap terlihat di samping bagian itu.
