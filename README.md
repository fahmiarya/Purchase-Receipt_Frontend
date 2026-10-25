# SC3 Frontend — Pembelian & Penerimaan Barang

Frontend web untuk Studi Kasus 3 (Pembelian & Penerimaan Barang). Dibangun dengan **Flutter Web**, state management memakai `setState` (StatefulWidget), HTTP client `http`, dan routing `go_router`.

Lihat `REQUIREMENTS.md` untuk spesifikasi lengkap dan `SC3.postman_collection.json` untuk kontrak API.

## Struktur

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # GoRouter + 3 route (items, purchase-orders, goods-receipts)
├── core/
│   ├── api/                  # api_client (BASE_URL + error handling),
│   │                         # api_provider (singleton), item/po/gr api
│   └── models/               # Item, PurchaseOrder(+Item), GoodsReceipt(+Item),
│                             # Vendor & Category (seed lokal), json_helpers (parser toleran)
├── features/
│   ├── items/                # items_page (split panel), item_list, item_form, item_provider
│   ├── purchase_orders/      # po_page, po_list, po_form, po_detail, po_provider
│   └── goods_receipts/       # gr_page, gr_list, gr_form, gr_detail, gr_provider
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
# Masuk ke folder frontend
cd frontend

# Install dependencies
flutter pub get

# Aktifkan web support (jika belum)
flutter config --enable-web

# Jalankan di Chrome
flutter run -d chrome

# Build untuk web
flutter build web
```

## Catatan Kontrak API

- `BASE_URL = http://localhost:8080/api/v1` (dienisasi di `lib/core/api/api_provider.dart`).
- Body request memakai nama field persis seperti Postman collection:
  - Items create: `name`, `itemCategoryCode`, `brandCode`, `uom` — `code`, `sequence`, `stock` dibuat otomatis backend; update hanya data master (`name`, `brandCode`, `uom`, tanpa `stock`).
  - PO create: `vendorId`, `tglPO`, `notes`, `items[] {itemId, qtyPO, hargaPO}`; `no_pr` tidak ada di collection (backend yang meng-generate).
  - GR create: `poId`, `tglGR`, `notes`, `items[] {poItemId, qtyDiterima}`.
- Query filter list: Items `category_code`, `search`; PO `status`, `vendor`, `date`; GR `po_id`, `date`. Tidak ada parameter lain (mis. `startDate`/`endDate`).
- Tidak ada endpoint vendor/kategori → pilihan vendor & kategori memakai seed lokal (`lib/core/models/vendor.dart`, `ItemCategory.seedList` di `lib/core/models/item.dart`).
- `POST /goods-receipts/preview` **belum ada** di collection → fitur preview sengaja tidak diimplementasikan sampai endpoint tersebut tersedia di backend.
- Response shape backend tidak tercantum lengkap di collection → parsing model toleran terhadap camelCase/snake_case (`lib/core/models/json_helpers.dart`). Jika response aktual backend berbeda, sesuaikan model tersebut.
- Error handling: pesan `error` (+`details`) dari API ditampilkan sebagai SnackBar merah; network error/timeout menjadi "Gagal terhubung ke server".
- GR bersifat immutable; koreksi lewat Goods Return (di luar scope).
