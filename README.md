# SC3 Frontend — Pembelian & Penerimaan Barang

Frontend web untuk Studi Kasus 3 (Pembelian & Penerimaan Barang). Dibangun dengan **Flutter Web** (Dart SDK `>=3.0.0`), state management memakai `setState` (StatefulWidget), HTTP client `http`, format angka `intl`, dan routing `go_router`.

Lihat `REQUIREMENTS.md` untuk spesifikasi lengkap dan `SC3.postman_collection.json` untuk kontrak API.

## Struktur

> **Note:** root repo ini adalah root proyek Flutter (tidak ada folder `frontend/` di dalamnya).

```
├── pubspec.yaml              # Dart SDK >=3.0.0, deps: http, go_router, intl
├── analysis_options.yaml     # flutter_lints
├── web/                      # index.html, manifest.json, ikon PWA
├── test/
│   └── widget_test.dart      # Smoke test render halaman Items
└── lib/
    ├── main.dart                 # Entry point
    ├── app.dart                  # GoRouter + 3 route (items, purchase-orders, goods-receipts)
    ├── core/
    │   ├── api/                  # api_client (BASE_URL + error handling),
    │   │                         # api_provider (singleton), item/po/gr api
    │   └── models/               # Item, PurchaseOrder(+Item), GoodsReceipt(+Item),
    │                             # Vendor & Category (seed lokal), json_helpers (parser toleran)
    ├── features/
    │   ├── items/                # items_page (split panel), item_list, item_form, item_provider
    │   ├── purchase_orders/      # po_page, po_list (filter chips + rentang tanggal), po_form, po_detail, po_provider
    │   └── goods_receipts/       # gr_page, gr_list (rentang tanggal), gr_form (tanggal ≥ tglPO), gr_detail, gr_provider
    └── widgets/
        ├── app_shell.dart        # NavigationRail + content area
        ├── status_badge.dart     # Chip warna status PO
        └── confirm_dialog.dart   # Dialog konfirmasi hapus/cancel
```

## Run Instructions

### Prerequisites

- Flutter SDK 3.x dengan web support aktif (`flutter config --enable-web`)
- Backend Fastify sudah running di `http://localhost:8080`
- Backend wajib mengizinkan CORS (`origin: true`) untuk request dari dev server Flutter

### Setup

```bash
# Clone repo, lalu masuk ke ROOT-nya (langsung isi proyek Flutter)
git clone https://github.com/fahmiarya/Purchase-Receipt_Frontend.git
cd Purchase-Receipt_Frontend

# Install dependencies (sesuai pubspec.lock)
flutter pub get

# Aktifkan web support (jika belum)
flutter config --enable-web

# (Opsional) jalankan smoke test render
flutter test

# Jalankan di Chrome
flutter run -d chrome

# Build untuk web
flutter build web
```

> Pastikan backend hidup **sebelum** membuka halaman — UI menampilkan "Gagal terhubung ke server" saat backend tidak merespons. Endpoint & kontrak lengkap ada di bagian [Catatan Kontrak API](#catatan-kontrak-api).

## Catatan Kontrak API

- `BASE_URL = http://localhost:8080/api/v1` (didefinisikan di `lib/core/api/api_provider.dart`).
- Body request memakai nama field persis seperti Postman collection:
  - Items create: `name`, `itemCategoryCode`, `brandCode`, `uom` — `code`, `sequence`, `stock` dibuat otomatis backend; update hanya data master (`name`, `brandCode`, `uom`, tanpa `stock`). Item **tidak dihapus** — hanya toggle aktif/nonaktif via `PATCH /items/:id/toggle-status` (body `{ "isActive": false|true }`).
  - PO create: `vendorId`, `tglPO`, `notes`, `items[] {itemId, qtyPO, hargaPO}`; `no_pr` tidak ada di collection (backend yang meng-generate).
  - GR create: `poId`, `tglGR`, `notes`, `items[] {poItemId, qtyDiterima}`.
- Query filter list: Items `category_code`, `search`, `include_inactive`; PO `status`, `vendor`, tanggal; GR `po_id`, tanggal.
  - Filter tanggal memakai **rentang**: `startDate` & `endDate` (format `YYYY-MM-DD`, inklusif). Tombol UI "Dari"/"Sampai" di list PO & GR memetakan langsung ke kedua parameter tersebut.
  - Backend menolak rentang terbalik (`endDate < startDate`) dan tanggal tidak valid dengan 422.
- Aturan tanggal GR: `tglGR` **tidak boleh lebih awal dari `tglPO`** — date picker form GR dibatasi mulai dari tanggal PO yang dipilih (di-clamp saat ganti PO), plus guard di form dan penolakan 422 dari backend (hari yang sama diperbolehkan).
- Nilai `status` PO dikirim apa adanya dari chip (`Open`/`Partial`/`Complete`/`Cancelled`); backend menerima kapitalisasi apa pun.
- Aturan soft-disable item: item **aktif** bisa dipilih untuk PO; item **nonaktif** hilang dari list default (Items & dropdown PO) tapi tetap ada di history PO/GR. Toggle tersedia di kartu list (ikon mata) dan tombol di panel detail; switch "Tampilkan nonaktif" mengirim `include_inactive=true`. Backend juga menolak (422) item nonaktif untuk PO baru.
- Tidak ada endpoint master data vendor/kategori → pilihan vendor & kategori memakai seed lokal (`lib/core/models/vendor.dart`, `ItemCategory.seedList` di `lib/core/models/item.dart`).
- `POST /goods-receipts/preview` **belum ada** di collection → fitur preview sengaja tidak diimplementasikan sampai endpoint tersebut tersedia di backend.
- Response shape backend tidak tercantum lengkap di collection → parsing model toleran terhadap camelCase/snake_case (`lib/core/models/json_helpers.dart`):
  - Angka decimal dikirim backend sebagai **string** (`"100"`) — semua field numerik memakai `asNum`/`asDouble`, bukan cast langsung (implicit downcast gagal di Flutter web).
  - Tanggal (`tglPO`, `tglGR`) datang sebagai timestamp ISO lengkap dan dinormalisasi ke `YYYY-MM-DD` oleh `asDateString` sebelum ditampilkan/diverifikasi.
- Error handling: pesan `error` (+`details`) dari API ditampilkan sebagai SnackBar merah; network error/timeout menjadi "Gagal terhubung ke server".
- GR bersifat immutable; koreksi lewat Goods Return (di luar scope).
