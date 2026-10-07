# Ancient Empire PC

Proyek pengembangan game strategi taktis berbasis giliran untuk PC, terinspirasi oleh *Ancient Empires*. README ini menjadi titik awal dokumentasi proyek.

> Proyek ini merupakan proyek penggemar yang tidak resmi dan tidak berafiliasi dengan pemilik atau pengembang *Ancient Empires*. Nama dan materi terkait *Ancient Empires* tetap menjadi milik pemegang haknya masing-masing.

## Status proyek

Proyek masih berada pada tahap awal. Belum ada build game atau instruksi instalasi dan menjalankan game yang tersedia.

## Mengenai game

*Ancient Empires* adalah game strategi taktis berbasis giliran dengan latar fantasi. Pemain memimpin pasukan di peta berbentuk kotak-kotak dan berusaha menyelesaikan tujuan misi dengan memanfaatkan posisi, jenis unit, dan kondisi medan.

Permainan berlangsung bergantian, bukan secara real-time: pemain merencanakan aksi pasukannya, lalu mengakhiri giliran agar pihak lawan dapat bergerak. Tujuan tiap misi bisa berbeda, misalnya mengalahkan pasukan lawan atau menguasai sasaran tertentu.

## Cara bermain

Alur bermain umumnya seperti ini:

1. **Pilih unit** yang ingin diperintah pada giliranmu.
2. **Gerakkan unit** ke petak yang dapat dijangkau. Posisi dan medan perlu diperhatikan karena dapat memengaruhi pergerakan maupun keuntungan saat bertarung.
3. **Serang atau ambil posisi** sesuai kemampuan unit. Unit jarak dekat dan jarak jauh memiliki peran serta jangkauan yang berbeda.
4. **Kelola sasaran misi.** Pada skenario yang menyediakan bangunan atau titik kendali, kuasai atau pertahankan lokasi itu sesuai tujuan yang diberikan.
5. **Akhiri giliran** setelah semua aksi yang diperlukan dilakukan. Lawan kemudian menjalankan gilirannya.
6. **Menangkan misi** dengan memenuhi kondisi kemenangan yang ditentukan skenario.

Strateginya bukan hanya menyerang: lindungi unit yang rentan, pilih posisi yang menguntungkan, dan sesuaikan komposisi pasukan dengan situasi serta tujuan misi.

## Arah proyek ini

README ini menjelaskan game yang menjadi inspirasi dan gambaran arah desain; mekanik di atas **belum diimplementasikan** di proyek ini. Tujuannya adalah membuat game strategi taktis berbasis giliran untuk PC dengan identitas dan aset orisinal, bukan menyalin materi milik game aslinya.

## Tujuan

Mengembangkan pengalaman strategi taktis berbasis giliran yang dapat dimainkan di PC. Detail aturan, misi, unit, dan aset orisinal akan ditentukan seiring perkembangan proyek.

## Teknologi

### Klien game (frontend)

- **Godot 4** sebagai engine utama.
  - Ringan, mendukung 2D maupun 3D dalam satu engine, dan dapat diekspor ke desktop (Windows terlebih dahulu, lalu Linux atau macOS bila dibutuhkan).
  - **GDScript** untuk prototipe cepat, atau **C#** bila lebih nyaman dengan bahasa bertipe kuat.

### Gaya visual (2D/2.5D/3D)

- **Target awal: 2.5D** — terrain 3D dengan unit berbasis sprite, sehingga memberi kedalaman visual tanpa biaya produksi 3D penuh. Alternatifnya grid 2D penuh, yang paling cepat diprototipe.
- **3D penuh (opsi lanjutan):** memberi kesan lebih modern (kamera, animasi, medan), tetapi menuntut modeling, rigging, animasi, pencahayaan, dan optimasi—waktu serta biaya produksi naik signifikan.
- **Pendekatan:** bangun dulu gameplay inti di 2D/2.5D, lalu tingkatkan ke 3D bila fondasi sudah solid. Godot memudahkan transisi ini.

### Backend

- **Belum diperlukan untuk versi awal.** Selama game bersifat *single-player* dan *offline*, progres dan pengaturan disimpan secara lokal. Ini menyederhanakan pengembangan dan memastikan game tetap dapat dimainkan tanpa koneksi internet.
- **Opsional (nanti):** bila fitur online seperti akun, multiplayer, atau sinkronisasi progres masuk cakupan, pertimbangkan **Nakama** sebagai backend game. Nakama menyediakan fitur umum game online dan dapat memakai **PostgreSQL** untuk penyimpanan data.

### Konfigurasi dan rahasia

- Kredensial dan pengaturan sensitif disimpan di file `.env` (tidak di-commit). Salin `.env.example` menjadi `.env` lalu isi nilainya.
- Variabel yang tersedia saat ini: `DATABASE_URL` untuk koneksi PostgreSQL (mis. Neon), format `postgresql://USER:PASSWORD@HOST/DBNAME?sslmode=require`.
- Aturan: jangan pernah menulis kredensial langsung di kode atau dokumentasi. Putar ulang (*rotate*) kredensial apa pun yang pernah terekspos.

### Rute yang disarankan

1. Mulai dengan **Godot 4 + penyimpanan lokal** dan gaya visual **2.5D** (atau 2D penuh untuk prototipe tercepat).
2. Naikkan ke **3D** bila gameplay inti sudah solid.
3. Tambahkan backend (mis. Nakama) hanya jika fitur online benar-benar masuk cakupan.

## Pengembangan

### Prasyarat

- **Godot 4.x** (dikembangkan dengan 4.7). Unduh dari https://godotengine.org/download atau `winget install --id GodotEngine.GodotEngine -e`.

### Menjalankan

Jalankan proyek langsung tanpa membuka editor:

```
godot --path .
```

Atau buka Godot, pilih **Import**, arahkan ke `project.godot` di folder ini, lalu tekan **F5**.

### Struktur proyek

- `project.godot` — konfigurasi proyek.
- `scenes/main.tscn` — scene utama.
- `scripts/game.gd` — logika dan render gameplay (grid, unit, giliran, pertarungan, bangunan).
- `assets/icons/` — icon karakter orisinal (SVG): `soldier`, `archer`, `brute`.
- `tests/smoke.tscn` — uji fungsional singkat.
- `tests/shot.tscn` — membuat screenshot untuk verifikasi tampilan.

### Pengujian

```
godot --headless --path . res://tests/smoke.tscn
```

Keluaran `SMOKE OK` menandakan logika dasar (pilih unit, gerak, giliran musuh, restart) berjalan.

### Main di browser (ekspor Web)

Godot bisa mengekspor game ke HTML5 (WebAssembly + WebGL 2.0) sehingga dapat dimainkan langsung di browser. Syarat: proyek memakai **GDScript** (ekspor web Godot 4 belum mendukung C#) dan browser berbasis Chromium atau Firefox.

**1. Pasang export template** (sekali saja)

- Lewat editor: **Editor › Manage Export Templates… › Download and Install**.
- Atau unduh berkas template sesuai versi Godot dari https://godotengine.org/download lalu pasang lewat menu yang sama.

Template bersifat global (dipakai semua proyek), jadi cukup dipasang sekali per versi Godot.

**2. Siapkan preset Web**

Preset **Web** sudah tersedia di repo ini (`export_presets.cfg`), dengan **Thread Support** nonaktif (mode *single-thread* tidak butuh header server khusus). Bila ingin mengubahnya, buka **Project › Export… › Web**. Opsional: aktifkan **Progressive Web App › Enable** agar bisa dimainkan offline.

File `export_presets.cfg` sengaja ikut ter-*commit* agar ekspor via CLI reprodusibel. Catatan: ekspor Web Godot 4 belum mendukung proyek C#.

**3. Lakukan ekspor**

Lewat editor: klik **Export Project**, target `build/web/index.html`.

Lewat CLI:

```
godot --headless --path . --export-release "Web" build/web/index.html
```

**4. Jalankan lewat web server lokal**

Berkas harus disajikan lewat HTTP, bukan dibuka langsung sebagai `file://`. Cara termudah dengan Python:

```
python -m http.server 8060 --directory build/web
```

Lalu buka http://localhost:8060 di browser.

> Catatan: bila **Thread Support** diaktifkan, server wajib mengirim header `Cross-Origin-Opener-Policy: same-origin` dan `Cross-Origin-Embedder-Policy: require-corp`. Godot menyediakan skrip `serve.py` untuk ini: https://github.com/godotengine/godot/blob/master/platform/web/serve.py (`python serve.py --root build/web`). Untuk hosting produksi yang tidak bisa mengatur header, aktifkan opsi **Progressive Web App**.

### Bangunan dan ekonomi

Di peta terdapat bangunan milik masing-masing pihak (menghalangi pergerakan). Saat giliranmu, **klik bangunanmu** untuk membuka menunya:

- **Barak (A)** — rekrut unit baru: *Prajurit* (60g) atau *Pemanah* (90g). Unit muncul di petak kosong terdekat.
- **Pasar ($)** — beli item untuk unit pemain yang sedang dipilih: *Ramuan* (40g, pulihkan penuh) atau *Asah* (50g, +2 ATK).

Ekonomi: pemain mulai dengan **200 gold**, dan mendapat **+50 gold** setiap kali menghabisi unit musuh.

### Cheat (untuk uji coba)

Cheat **hanya memengaruhi pemain**, tidak menyentuh musuh. Saat bermain, tekan tombol berikut:

- **K** — hapus semua musuh (menang instan).
- **H** — pulihkan penuh semua unit pemain.
- **G** — aktif/nonaktif *god mode* (unit pemain kebal).
- **M** — semua unit pemain bisa bergerak lagi.
- **P** — serangan unit pemain +5.

### Status gameplay

Prototipe awal sudah memuat: papan grid, unit pemain dan musuh, pergerakan berbasis jangkauan, penyerangan unit bersebelahan, giliran bergantian dengan AI musuh sederhana, serta kondisi menang/kalah dan mulai ulang. Aturan, unit, dan aset orisinal masih akan dikembangkan.

## Lisensi dan aset

Lisensi proyek dan ketentuan penggunaan aset belum ditentukan. Jangan menganggap aset, nama, atau materi dari game aslinya bebas digunakan.
