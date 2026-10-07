# AGENTS.md

Panduan untuk agen/otomasi yang bekerja di repo ini.

## Aturan kerja

- **Selalu `git commit` lalu `git push` setelah menyelesaikan setiap task**, kecuali diminta sebaliknya. Jangan menunggu diminta.
- Sebelum commit: jalankan pengujian (lihat bawah), lalu periksa `git status`/`git diff` dan hanya stage file yang relevan.
- Jangan men-commit rahasia. Kredensial disimpan di `.env` (di-*ignore*); jangan pernah menulis kredensial ke kode atau dokumentasi.
- Untuk perubahan tampilan/gameplay, verifikasi dengan menjalankan game, bukan hanya membaca kode.

## Gaya commit

Gunakan Conventional Commits dan pesan berbahasa Indonesia, mis.:

- `feat: tambah ...`
- `fix: perbaiki ...`
- `docs: perbarui ...`
- `style: rombak UI ...`
- `test: tambah ...`

## Konteks proyek

- Engine: **Godot 4** (dikembangkan dengan 4.7), bahasa **GDScript**.
- Scene utama: `scenes/main.tscn`; logika & render: `scripts/game.gd`.
- Desain: game strategi taktis berbasis giliran; target gaya visual 2.5D.

## Perintah penting

Jalankan game:

```
godot --path .
```

Uji fungsional (harus mencetak `SMOKE OK`):

```
godot --headless --path . res://tests/smoke.tscn
```

Ekspor Web lalu serve:

```
godot --headless --path . --export-release "Web" build/web/index.html
python -m http.server 8060 --directory build/web
```
