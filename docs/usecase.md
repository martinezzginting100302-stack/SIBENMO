# Diagram Use Case — SIBENMO

**SIBENMO** (Sistem Informasi Bengkel Mobile) adalah aplikasi Flutter yang berkomunikasi dengan
server Laravel (Sanctum) melalui `lib/services/api_service.dart` dan menyimpan salinan data lokal
di SQLite sebagai fallback offline (`lib/database/database_helper.dart`).

> Diagram di bawah memakai tipe `usecase-beta` bawaan Mermaid (**Mermaid >= 12.0.0**).
> Buka file ini di GitHub, VS Code (ekstensi Mermaid Preview), atau <https://mermaid.live>.

---

## 1. Daftar aktor

| Aktor      | Peran                                                        | Folder layar                        |
| ---------- | ------------------------------------------------------------ | ----------------------------------- |
| `Pelanggan` | Pemilik kendaraan; mendaftar sendiri, mengajukan servis, memantau biaya | `lib/screens/pelanggan/`  |
| `Mekanik`   | Teknisi yang memeriksa, mengerjakan, dan menyelesaikan servis        | `lib/screens/mekanik/`    |
| `Admin`     | Mengelola data master, transaksi, pembayaran, dan laporan            | `lib/screens/admin/`      |

## 2. Alur status servis (konteks relasi antar use case)

```
Diterima  ->  Diperiksa  ->  Dikerjakan  ->  Selesai  ->  Dibayar
  Admin        Mekanik        Mekanik         Mekanik       Admin
  (buat/       (pemeriksaan)  (kerjakan &     (tandai       (proses
   terima)                     catat sparepart) selesai)     pembayaran)
```

Sumber: `lib/screens/pelanggan/status_servis.dart:183`, `lib/screens/admin/manage_transaksi.dart:321`.

---

## 3. Diagram konteks (ringkasan seluruh sistem)

```mermaid
usecase-beta
direction LR
accTitle: Diagram use case SIBENMO
accDescr {
  Tiga aktor yaitu Pelanggan, Mekanik dan Admin berinteraksi
  dengan aplikasi mobile SIBENMO untuk mengelola layanan bengkel.
}

actor Pelanggan("Pelanggan")
actor Mekanik("Mekanik")
actor Admin("Admin")

systemBoundary SIBENMO("Sistem Aplikasi Mobile SIBENMO")
  DaftarAkun("Daftar Akun")
  MasukSistem("Masuk Sistem")
  Keluar("Keluar dari Sistem")
  KelolaKendaraanSaya("Kelola Data Kendaraan")
  AjukanServis("Ajukan Servis")
  PantauStatusServis("Pantau Status Servis")
  LihatRiwayatPelanggan("Lihat Riwayat Servis")
  LihatRincianBiaya("Lihat Rincian Biaya")
  KelolaPekerjaan("Kelola Pekerjaan Servis")
  CatatSparepart("Catat Pemakaian Sparepart")
  TandaiSelesai("Tandai Servis Selesai")
  KelolaDataMaster("Kelola Data Master")
  KelolaTransaksi("Kelola Transaksi Servis")
  ProsesPembayaran("Proses Pembayaran")
  BuatLaporan("Buat Laporan Servis")
end

Pelanggan --> DaftarAkun
Pelanggan --> MasukSistem
Pelanggan --> Keluar
Pelanggan --> KelolaKendaraanSaya
Pelanggan --> AjukanServis
Pelanggan --> PantauStatusServis
Pelanggan --> LihatRiwayatPelanggan
Pelanggan --> LihatRincianBiaya

Mekanik --> MasukSistem
Mekanik --> Keluar
Mekanik --> KelolaPekerjaan
Mekanik --> CatatSparepart
Mekanik --> TandaiSelesai

Admin --> MasukSistem
Admin --> Keluar
Admin --> KelolaDataMaster
Admin --> KelolaTransaksi
Admin --> ProsesPembayaran
Admin --> BuatLaporan
```

---

## 4. Diagram use case — Pelanggan

```mermaid
usecase-beta
direction LR
accTitle: Diagram use case modul Pelanggan
accDescr {
  Pelanggan mendaftar akun, mengelola kendaraan, mengajukan servis,
  memantau status, melihat riwayat dan rincian biaya.
}

actor Pelanggan("Pelanggan")

systemBoundary ModulPelanggan("Modul Pelanggan")
  DaftarAkun("Daftar Akun")
  MasukSistem("Masuk Sistem")
  Keluar("Keluar dari Sistem")
  KelolaKendaraan("Kelola Kendaraan Saya")
  TambahKendaraan("Tambah Kendaraan")
  UbahKendaraan("Ubah Data Kendaraan")
  HapusKendaraan("Hapus Kendaraan")
  AjukanServis("Ajukan Servis")
  PilihKendaraan("Pilih Kendaraan")
  TulisKeluhan("Tulis Keluhan Kendaraan")
  PilihMekanik("Pilih Mekanik")
  PantauStatusServis("Pantau Status Servis")
  LihatRiwayatServis("Lihat Riwayat Servis")
  LihatRincianBiaya("Lihat Rincian Biaya")
  PilihServis("Pilih Servis yang Ditampilkan")
end

note for MasukSistem "Semua use case lain memerlukan sesi login yang aktif"
note for KelolaKendaraan "Mencakup tambah, ubah, hapus dan pencarian kendaraan"

Pelanggan --> DaftarAkun
Pelanggan --> MasukSistem
Pelanggan --> Keluar
Pelanggan --> KelolaKendaraan
Pelanggan --> AjukanServis
Pelanggan --> PantauStatusServis
Pelanggan --> LihatRiwayatServis
Pelanggan --> LihatRincianBiaya

TambahKendaraan ..> : extend KelolaKendaraan
UbahKendaraan ..> : extend KelolaKendaraan
HapusKendaraan ..> : extend KelolaKendaraan
AjukanServis ..> : include PilihKendaraan
AjukanServis ..> : include TulisKeluhan
PilihMekanik ..> : extend AjukanServis
LihatRincianBiaya ..> : include PilihServis
```

| Use case | Sumber di kode |
| --- | --- |
| Daftar Akun | `lib/screens/register_screen.dart` (membuat akun berperan `pelanggan`) |
| Masuk Sistem / Keluar | `lib/screens/login_screen.dart`, `lib/providers/auth_provider.dart` |
| Kelola Kendaraan Saya | `lib/screens/pelanggan/kelola_kendaraan.dart` |
| Ajukan Servis | `lib/screens/pelanggan/daftar_servis.dart` (status awal `Diterima`) |
| Pantau Status Servis | `lib/screens/pelanggan/status_servis.dart` (timeline 5 tahap) |
| Lihat Riwayat Servis | `lib/screens/pelanggan/riwayat_servis_pelanggan.dart` |
| Lihat Rincian Biaya | `lib/screens/pelanggan/rincian_biaya.dart` |

---

## 5. Diagram use case — Mekanik

```mermaid
usecase-beta
direction LR
accTitle: Diagram use case modul Mekanik
accDescr {
  Mekanik melihat daftar pekerjaan, memeriksa kendaraan,
  mencatat jasa dan sparepart, lalu menandai servis selesai.
}

actor Mekanik("Mekanik")

systemBoundary ModulMekanik("Modul Mekanik")
  MasukSistem("Masuk Sistem")
  Keluar("Keluar dari Sistem")
  LihatDaftarPekerjaan("Lihat Daftar Pekerjaan")
  FilterStatusPekerjaan("Filter Status Pekerjaan")
  LihatDetailKendaraan("Lihat Detail Kendaraan dan Pelanggan")
  LakukanPemeriksaan("Lakukan Pemeriksaan Kendaraan")
  KerjakanServis("Catat Pekerjaan Servis")
  TambahJasaCustom("Tambah Jasa Custom")
  CatatSparepart("Catat Pemakaian Sparepart")
  AturJumlahSparepart("Atur Jumlah Sparepart")
  TandaiSelesai("Tandai Servis Selesai")
  LihatRiwayatPekerjaan("Lihat Riwayat Pekerjaan")
end

note for MasukSistem "Semua use case lain memerlukan sesi login yang aktif"
note for LakukanPemeriksaan "Mengubah status servis menjadi Diperiksa"
note for TandaiSelesai "Mengubah status servis menjadi Selesai"

Mekanik --> MasukSistem
Mekanik --> Keluar
Mekanik --> LihatDaftarPekerjaan
Mekanik --> LihatDetailKendaraan
Mekanik --> LakukanPemeriksaan
Mekanik --> KerjakanServis
Mekanik --> CatatSparepart
Mekanik --> TandaiSelesai
Mekanik --> LihatRiwayatPekerjaan

FilterStatusPekerjaan ..> : extend LihatDaftarPekerjaan
TambahJasaCustom ..> : extend KerjakanServis
AturJumlahSparepart ..> : extend CatatSparepart
```

| Use case | Sumber di kode |
| --- | --- |
| Lihat Daftar Pekerjaan | `lib/screens/mekanik/daftar_pekerjaan.dart` (filter status) |
| Lihat Detail Kendaraan | `lib/screens/mekanik/detail_kendaraan.dart` |
| Melakukan Pemeriksaan | `lib/screens/mekanik/pemeriksaan.dart` (status `Diperiksa`) |
| Catat Pekerjaan Servis | `lib/screens/mekanik/catat_servis.dart` (status `Dikerjakan`) |
| Catat Pemakaian Sparepart | `lib/screens/mekanik/catat_sparepart.dart` (mengurangi stok) |
| Tandai Servis Selesai | `lib/screens/mekanik/catat_sparepart.dart:161` (status `Selesai`) |
| Lihat Riwayat Pekerjaan | `lib/screens/mekanik/mekanik_home.dart` |

---

## 6. Diagram use case — Admin

```mermaid
usecase-beta
direction LR
accTitle: Diagram use case modul Admin
accDescr {
  Admin mengelola data master, transaksi servis,
  memproses pembayaran, mencari riwayat dan membuat laporan.
}

actor Admin("Admin")

systemBoundary ModulAdmin("Modul Admin")
  MasukSistem("Masuk Sistem")
  Keluar("Keluar dari Sistem")
  KelolaPelanggan("Kelola Data Pelanggan")
  KelolaKendaraanAdmin("Kelola Data Kendaraan")
  KelolaMekanik("Kelola Data Mekanik")
  KelolaJasaServis("Kelola Jenis Jasa Servis")
  KelolaSparepart("Kelola Data Sparepart")
  KelolaTransaksi("Kelola Transaksi Servis")
  BuatTransaksiServis("Buat Transaksi Servis")
  UpdateStatusServis("Update Status Servis")
  ProsesPembayaran("Proses Pembayaran")
  PilihMetodePembayaran("Pilih Metode Pembayaran")
  CariRiwayatServis("Cari Riwayat Servis")
  BuatLaporanServis("Buat Laporan Servis")
  TentukanRentangTanggal("Tentukan Rentang Tanggal")
end

note for MasukSistem "Semua use case lain memerlukan sesi login berperan admin"
note for KelolaPelanggan "Berlaku juga untuk Kelola Kendaraan, Mekanik, Jasa Servis dan Sparepart: tambah, ubah, hapus, cari"

Admin --> MasukSistem
Admin --> Keluar
Admin --> KelolaPelanggan
Admin --> KelolaKendaraanAdmin
Admin --> KelolaMekanik
Admin --> KelolaJasaServis
Admin --> KelolaSparepart
Admin --> KelolaTransaksi
Admin --> ProsesPembayaran
Admin --> CariRiwayatServis
Admin --> BuatLaporanServis

BuatTransaksiServis ..> : extend KelolaTransaksi
UpdateStatusServis ..> : extend KelolaTransaksi
PilihMetodePembayaran ..> : include ProsesPembayaran
TentukanRentangTanggal ..> : include BuatLaporanServis
```

| Use case | Sumber di kode |
| --- | --- |
| Kelola Data Pelanggan | `lib/screens/admin/manage_pelanggan.dart` |
| Kelola Data Kendaraan | `lib/screens/admin/manage_kendaraan.dart` |
| Kelola Data Mekanik | `lib/screens/admin/manage_mekanik.dart` |
| Kelola Jenis Jasa Servis | `lib/screens/admin/manage_jasa.dart` |
| Kelola Data Sparepart | `lib/screens/admin/manage_sparepart.dart` |
| Kelola Transaksi Servis | `lib/screens/admin/manage_transaksi.dart` (buat + update status) |
| Proses Pembayaran | `lib/screens/admin/manage_pembayaran.dart` (Tunai, Transfer, QRIS, Kartu) |
| Cari Riwayat Servis | `lib/screens/admin/riwayat_servis.dart` |
| Buat Laporan Servis | `lib/screens/admin/laporan.dart` (`getLaporanServis`) |

---

## 7. Diagram use case — Autentikasi dan akun

```mermaid
usecase-beta
direction LR
accTitle: Diagram use case autentikasi SIBENMO
accDescr {
  Ketiga aktor merupakan generalisasi dari Pengguna Terdaftar.
  Hanya pelanggan yang dapat mendaftar mandiri dari aplikasi.
}

actor Pengguna("Pengguna Terdaftar")
actor Pelanggan("Pelanggan")
actor Mekanik("Mekanik")
actor Admin("Admin")

systemBoundary ModulAkun("Modul Autentikasi dan Akun")
  DaftarAkun("Daftar Akun Pelanggan")
  MasukSistem("Masuk Sistem")
  PilihHalamanPeran("Buka Halaman Sesuai Peran")
  Keluar("Keluar dari Sistem")
end

note for DaftarAkun "Pendaftaran mandiri di aplikasi hanya menghasilkan akun berperan pelanggan"

Pelanggan --|> Pengguna
Mekanik --|> Pengguna
Admin --|> Pengguna

Pengguna --> MasukSistem
Pengguna --> PilihHalamanPeran
Pengguna --> Keluar
Pelanggan --> DaftarAkun
```

Pemetaan peran ke layar (sumber: `lib/screens/login_screen.dart`):

| Peran      | Layar tujuan setelah login |
| ---------- | -------------------------- |
| `admin`    | `AdminHome`                |
| `pelanggan`| `PelangganHome`            |
| `mekanik`  | `MekanikHome`              |

---

## 8. Legenda relasi

| Notasi | Arti |
| --- | --- |
| `A --> B` | Asosiasi: aktor menggunakan use case |
| `A ..> : include B` | **Include**: use case A selalu menjalankan use case B |
| `A ..> : extend B` | **Extend**: use case A bersifat opsional dan memperluas use case B |
| `A --\|> B` | **Generalization**: A adalah spesialisasi dari B |

### Ringkasan relasi include / extend

| Tipe | Relasi |
| --- | --- |
| include | `AjukanServis` → `PilihKendaraan`, `TulisKeluhan` |
| include | `LihatRincianBiaya` → `PilihServis` |
| include | `ProsesPembayaran` → `PilihMetodePembayaran` |
| include | `BuatLaporanServis` → `TentukanRentangTanggal` |
| extend | `TambahKendaraan`, `UbahKendaraan`, `HapusKendaraan` → `KelolaKendaraan` |
| extend | `PilihMekanik` → `AjukanServis` (opsional) |
| extend | `FilterStatusPekerjaan` → `LihatDaftarPekerjaan` |
| extend | `TambahJasaCustom` → `KerjakanServis` |
| extend | `AturJumlahSparepart` → `CatatSparepart` |
| extend | `BuatTransaksiServis`, `UpdateStatusServis` → `KelolaTransaksi` |
| generalization | `Pelanggan`, `Mekanik`, `Admin` → `Pengguna Terdaftar` |

---

## 9. Catatan rendering

- Tipe `usecase-beta` baru tersedia sejak **Mermaid 12.0.0**. Jika renderernya lebih lama,
  ubah front matter diagram menjadi tipe `flowchart`, atau perbarui ekstensi Mermaid.
- Setiap pernyataan wajib berdiri sendiri pada satu baris fisik.
- Jika ingin diagram terpisah per aktor dalam satu gambar, gabungkan blok `systemBoundary`
  dari beberapa modul ke dalam satu blok `usecase-beta`.
