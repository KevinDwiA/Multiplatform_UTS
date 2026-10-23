# DompetKu — UTS Pemrograman Multiplatform

Aplikasi mobile pencatatan keuangan pribadi harian berbasis Flutter yang dirancang dengan pendekatan mandiri (*offline-first*), memanfaatkan *asynchronous programming* secara menyeluruh serta mengintegrasikan dua teknik *data persistence* lokal (SQLite dan SharedPreferences).

Aplikasi ini berjalan sepenuhnya secara lokal tanpa memerlukan koneksi internet, akun daring, backend server, Firebase, MySQL, maupun XAMPP.

---

## Identitas Mahasiswa

| Informasi | Keterangan |
|---|---|
| **Nama** | Muhamad Kevin Dwi Arisandi |
| **NIM** | 240605110252 |
| **Kelas** | [KELAS] |
| **Mata Kuliah** | Pemrograman Multiplatform |
| **Program Studi** | Teknik Informatika |
| **Fakultas** | Sains dan Teknologi |
| **Universitas** | Universitas Islam Negeri Maulana Malik Ibrahim Malang |
| **Tahun Akademik**| 2026 |

---

## Dokumen Laporan UTS

Dokumen akademik resmi laporan Ujian Tengah Semester telah disertakan secara lengkap di dalam repository ini:
- 📄 **Format PDF**: [laporan/Laporan_UTS_Multiplatform_Muhamad_Kevin_Dwi_Arisandi.pdf](laporan/Laporan_UTS_Multiplatform_Muhamad_Kevin_Dwi_Arisandi.pdf)
- 📝 **Format Word (DOCX)**: [laporan/Laporan_UTS_Multiplatform_Muhamad_Kevin_Dwi_Arisandi.docx](laporan/Laporan_UTS_Multiplatform_Muhamad_Kevin_Dwi_Arisandi.docx)

Laporan mencakup Cover resmi, BAB I Pendahuluan (latar belakang & fitur), BAB II Pembahasan (11 tangkapan layar antarmuka asli dengan caption, persiapan project & package, implementasi asynchronous programming, implementasi data persistence SQLite & SharedPreferences, tabel hasil pengujian lengkap), BAB III Penutup (kesimpulan & saran), serta Daftar Pustaka.

---

## Deskripsi dan Tujuan Aplikasi

**DompetKu** bertujuan membantu pengguna mencatat dan memantau arus kas pribadi (pemasukan dan pengeluaran) secara disiplin, cepat, dan aman. Dengan privasi data 100% tersimpan di perangkat lokal pengguna, aplikasi ini mengeliminasi risiko kebocoran data finansial pribadi ke server pihak ketiga serta menjamin kinerja instan tanpa latensi jaringan.

---

## Daftar Fitur Aplikasi

1. **Dashboard Keuangan Terintegrasi**:
   - Menampilkan kartu saldo saat ini (*all-time balance*).
   - Menampilkan total pemasukan dan total pengeluaran bulan berjalan.
   - Menampilkan ringkasan penggunaan anggaran bulanan (*visual progress bar* dan sisa anggaran).
   - Menampilkan lima transaksi terbaru yang teragregasi otomatis dari basis data.
2. **Manajemen Transaksi (CRUD Lengkap)**:
   - Pencatatan transaksi Pemasukan (*income*) dan Pengeluaran (*expense*).
   - Validasi nilai nominal angka positif terbatas (`amount > 0` dan `amount.isFinite`).
   - Pemilihan kategori terelasi sesuai tipe transaksi.
   - Pemilihan tanggal transaksi interaktif (*date picker*).
   - Pengisian catatan/keterangan opsional.
   - Pengeditan transaksi eksisting (*pre-populated form*).
   - Penghapusan transaksi yang dilindungi oleh dialog modal konfirmasi keamanan.
3. **Kategori Transaksi Relasional**:
   - 12 kategori awal terstruktur (*seed* otomatis saat basis data dibuat).
   - Kategori Pemasukan: Gaji, Bonus & Hadiah, Investasi, Penjualan.
   - Kategori Pengeluaran: Makanan & Minuman, Transportasi, Pendidikan, Belanja Harian, Hiburan & Hobi, Kesehatan, Tagihan & Utilitas, Lainnya.
   - Ikon tematik dan kode warna visual.
4. **Riwayat dan Filter Multi-Dimensi**:
   - Menampilkan seluruh daftar riwayat transaksi.
   - Filter instan berdasarkan tipe transaksi (Semua / Pemasukan / Pengeluaran).
   - Filter berdasarkan kategori transaksi.
   - Filter berdasarkan bulan kalender.
5. **Batas Anggaran Bulanan (Monthly Budgeting)**:
   - Penetapan pagu pengeluaran bulanan melalui dialog modal interaktif.
   - Indikator kemajuan (*LinearProgressIndicator*) yang menghitung persentase beban pengeluaran terhadap pagu anggaran secara otomatis.
   - Tersimpan persisten di SharedPreferences.
6. **Pengaturan Tema (Dark & Light Mode)**:
   - Beralih tema gelap/terang secara instan melalui ikon AppBar.
   - Palet warna Material Design 3 yang kontras dan nyaman di mata.
   - Preferensi tema tersimpan secara persisten di SharedPreferences.
7. **Keandalan dan Responsivitas**:
   - Tata letak adaptif yang diuji pada layar 320 dp hingga 412 dp tanpa *RenderFlex overflow*.
   - Formulir dapat digulir aman saat *keyboard* virtual terbuka (*scrollable keyboard safety*).

---

## Teknologi dan Dependency

Aplikasi dikembangkan menggunakan Flutter SDK dan Dart dengan dependensi minimal yang terfokus:

- **Framework**: Flutter (Material Design 3)
- **Bahasa**: Dart (SDK `^3.13.2`)
- **Basis Data Relasional**: `sqflite: ^2.4.5`
- **Utilitas Sistem Berkas**: `path: ^1.9.1`
- **Penyimpanan Preferensi**: `shared_preferences: ^2.5.6`
- **Format Internasional**: `intl: ^0.20.3` (pemformatan mata uang Rupiah `NumberFormat.currency` dan tanggal Bahasa Indonesia)
- **Ikon UI**: `cupertino_icons: ^1.0.8`

---

## Penerapan Asynchronous Programming

Operasi I/O disk, basis data, dan penyimpanan preferensi dijalankan secara asinkron menggunakan paradigma `Future`, `async`, dan `await` agar *main thread* (UI thread) tetap mulus tanpa *freeze*:

1. **Inisialisasi Basis Data Asinkron**:
   ```dart
   Future<Database> get database async {
     if (_database != null) return _database!;
     _opening ??= _initDB(databaseName);
     try {
       _database = await _opening!;
       return _database!;
     } finally {
       _opening = null;
     }
   }
   ```
2. **Operasi CRUD Asinkron**:
   ```dart
   Future<int> insertTransaction(TransactionItem transaction) async {
     final db = await database;
     return await db.insert('transactions', transaction.toMap());
   }
   ```
3. **Agregasi Keuangan Asinkron**:
   ```dart
   Future<Map<String, double>> getFinancialSummary({String? monthPrefix}) async {
     final db = await database;
     final allTotals = await db.rawQuery('''
       SELECT 
         COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS total_income,
         COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS total_expense
       FROM transactions
     ''');
     // ...
   }
   ```
4. **Penyimpanan Preferensi Asinkron**:
   ```dart
   Future<bool> setDarkMode(bool value) async {
     final prefs = await SharedPreferences.getInstance();
     return await prefs.setBool(keyIsDarkMode, value);
   }
   ```
5. **State Handling di Antarmuka**:
   Pemanggilan data asinkron pada UI membungkus operasi dengan `try-catch`, memeriksa status `mounted` sebelum memicu `setState`, dan menampilkan indikator *loading* (`CircularProgressIndicator`) serta pesan kesalahan terstruktur.

---

## Penerapan Data Persistence

Aplikasi memadukan dua teknik penyimpanan data lokal:

### 1. SQLite Database (`dompetku.db`)
Digunakan untuk data transaksional yang terstruktur dan berelasi.
- **Tabel `categories`**:
  * `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
  * `name`: `TEXT NOT NULL`
  * `type`: `TEXT NOT NULL` (`income` atau `expense`)
  * `icon`: `TEXT NOT NULL`
  * `color`: `INTEGER NOT NULL`
- **Tabel `transactions`**:
  * `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
  * `category_id`: `INTEGER NOT NULL`
  * `type`: `TEXT NOT NULL` (`income` atau `expense`)
  * `amount`: `REAL NOT NULL`
  * `transaction_date`: `TEXT NOT NULL` (format `YYYY-MM-DD`)
  * `description`: `TEXT`
  * `created_at`: `TEXT NOT NULL` (format ISO-8601)
  * `FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT`
- **Indeks**: `CREATE INDEX idx_transactions_date ON transactions (transaction_date DESC)`
- **Integritas Relasional**: `PRAGMA foreign_keys = ON` diaktifkan saat konfigurasi koneksi; klausa `ON DELETE RESTRICT` mencegah penghapusan kategori yang masih digunakan oleh catatan transaksi.

### 2. SharedPreferences
Digunakan untuk data konfigurasi dan preferensi aplikasi berbentuk *key-value pair*:
- `dompetku_is_dark_mode` (`bool`): Status preferensi tema gelap (true) atau terang (false).
- `dompetku_monthly_budget` (`double`): Batas nominal pengeluaran bulanan yang ditetapkan pengguna.

---

## Struktur Folder Project

```text
dompetku_uts/
├── android/            # Konfigurasi build Android (Gradle & Manifest)
├── laporan/            # Dokumen resmi Laporan UTS (PDF & DOCX)
├── lib/
│   ├── database/       # DatabaseHelper SQLite & migrasi skema
│   ├── models/         # Model data Category & TransactionItem
│   ├── screens/        # Antarmuka TransactionFormScreen & navigasi
│   ├── services/       # ThemePreferenceService, BudgetPreferenceService, CurrencyHelper
│   └── main.dart       # Titik masuk utama, DashboardScreen, TransactionsScreen
├── test/
│   ├── budget_test.dart    # Unit test preferensi anggaran
│   ├── database_test.dart  # Unit test SQLite nyata (CRUD, agregasi, FK RESTRICT)
│   └── widget_test.dart    # Widget test responsivitas (320dp & 412dp) dan tema
├── analysis_options.yaml   # Aturan linter resmi Flutter
├── pubspec.yaml            # Deklarasi paket & dependensi
└── README.md               # Dokumentasi lengkap project
```

---

## Tutorial Instalasi dan Menjalankan Aplikasi

Pastikan lingkungan komputer telah terpasang **Flutter SDK** (versi stable yang kompatibel dengan Dart SDK `^3.13.2`) dan **Android SDK / Emulator**.

1. **Clone repository**:
   ```bash
   git clone https://github.com/Farilzzz/240605110252-Muhamad-Kevin-Dwi-Arisandi-UTS-Multiplatform.git
   ```

2. **Masuk ke direktori project**:
   ```bash
   cd 240605110252-Muhamad-Kevin-Dwi-Arisandi-UTS-Multiplatform
   ```

3. **Periksa kesiapan toolchain**:
   ```bash
   flutter doctor
   ```

4. **Unduh seluruh dependensi**:
   ```bash
   flutter pub get
   ```

5. **Hubungkan perangkat fisik atau jalankan Android Emulator**:
   ```bash
   flutter devices
   ```

6. **Jalankan aplikasi**:
   ```bash
   flutter run
   ```

7. **Kompilasi paket APK Debug**:
   ```bash
   flutter build apk --debug
   ```
   *Output file APK*: `build/app/outputs/flutter-apk/app-debug.apk`

---

## Panduan Penggunaan Aplikasi

1. **Membuka Aplikasi**: Aplikasi langsung membuka halaman Beranda tanpa login. Saldo awal dan transaksi ditampilkan Rp 0.
2. **Mengatur Anggaran Bulanan**: Tekan ikon tabungan pada AppBar di kanan atas, masukkan nominal anggaran (misalnya `3000000`), lalu tekan **Simpan**.
3. **Mencatat Pemasukan**: Tekan tombol `+ Transaksi`, pilih tombol hijau **Pemasukan**, isi nominal (misalnya `5000000`), pilih kategori (misal: *Gaji*), pilih tanggal, dan tekan **Simpan Transaksi**. Saldo otomatis bertambah.
4. **Mencatat Pengeluaran**: Tekan tombol `+ Transaksi`, pilih tombol merah **Pengeluaran**, isi nominal (misalnya `150000`), pilih kategori (misal: *Makanan & Minuman*), lalu simpan. Saldo berkurang dan bilah anggaran akan memperlihatkan persentase pemakaian dana.
5. **Melihat Riwayat & Filter**: Tekan tautan **Lihat semua** di samping judul 5 transaksi terbaru. Gunakan menu dropdown untuk memfilter berdasarkan tipe (Pemasukan/Pengeluaran), kategori, atau bulan kalender.
6. **Mengedit Transaksi**: Pada daftar transaksi, ketuk salah satu item transaksi untuk membuka formulir edit, ubah data yang diinginkan, lalu simpan perubahan.
7. **Menghapus Transaksi**: Geser item transaksi ke arah kiri (*swipe to delete*) atau gunakan tombol hapus. Konfirmasi pada dialog modal yang muncul.
8. **Mengganti Tema Gelap/Terang**: Tekan ikon bulan/matahari pada AppBar untuk beralih antara Dark Mode dan Light Mode.

---

## Hasil Pengujian

Seluruh proses verifikasi dijalankan dengan hasil riil:

- **Analisis Statis (`flutter analyze`)**:
  `No issues found!` (0 error, 0 warning, 0 info).
- **Pengujian Otomatis (`flutter test`)**:
  `All tests passed!` (7 passed, 0 failed).
  * Validasi batas nominal positif dan angka terbatas.
  * Operasi CRUD nyata SQLite FFI dan kalkulasi agregasi saldo.
  * Uji penegakan integritas referensial Foreign Key (`ON DELETE RESTRICT`).
  * Uji simpan, baca, dan hapus preferensi SharedPreferences.
  * Uji render widget responsif pada lebar 320.0 dp dan 412.0 dp.
- **Kompilasi Android APK (`flutter build apk --debug`)**:
  Berhasil dikompilasi menghasilkan file instalasi APK (154 MB).
- **Verifikasi Runtime & Persistensi Offline pada Emulator Android**:
  * Aplikasi berjalan tanpa internet (*WiFi & data seluler dimatikan total*).
  * Aplikasi dihentikan paksa (*force-stop*) dan dibuka kembali: data transaksi SQLite dan tema gelap SharedPreferences tetap utuh 100%.

---

## Keterangan Dukungan Offline dan Keterbatasan

- **Kemandirian Penuh**: Seluruh data tersimpan secara lokal pada database SQLite internal perangkat dan SharedPreferences. Aplikasi tidak memerlukan koneksi internet untuk seluruh fiturnya.
- **Tanpa Akun & Cloud**: Tidak ada proses autentikasi akun daring atau sinkronisasi multi-device berbasis cloud.
- **Penyimpanan Lokal**: Jika aplikasi di-uninstall secara total dari perangkat, data basis data lokal akan terhapus mengikuti siklus hidup sandbox aplikasi Android standar.

---

## Identitas Pengembang

**Muhamad Kevin Dwi Arisandi**  
NIM: 240605110252  
Kelas: [KELAS]  
Program Studi Teknik Informatika  
Fakultas Sains dan Teknologi  
Universitas Islam Negeri Maulana Malik Ibrahim Malang  
2026
