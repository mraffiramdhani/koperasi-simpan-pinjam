// Model data ringan (map dari JSON Supabase).

class Member {
  Member({
    required this.id,
    required this.noAnggota,
    required this.nama,
    required this.status,
    this.nik,
    this.alamat,
    this.phone,
    this.fotoKtpPath,
    this.tanggalGabung,
  });

  final String id;
  final String? noAnggota;
  final String nama;
  final String status;
  final String? nik;
  final String? alamat;
  final String? phone;
  final String? fotoKtpPath;
  final String? tanggalGabung;

  bool get isActive => status == 'active';

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: j['id'] as String,
        noAnggota: j['no_anggota'] as String?,
        nama: j['nama'] as String,
        status: j['status'] as String,
        nik: j['nik'] as String?,
        alamat: j['alamat'] as String?,
        phone: j['phone'] as String?,
        fotoKtpPath: j['foto_ktp_path'] as String?,
        tanggalGabung: j['tanggal_gabung'] as String?,
      );
}

class SavingsAccount {
  SavingsAccount({required this.id, required this.tipe, required this.saldo});

  final String id;
  final String tipe;
  final num saldo;

  factory SavingsAccount.fromJson(Map<String, dynamic> j) => SavingsAccount(
        id: j['id'] as String,
        tipe: j['tipe'] as String,
        saldo: j['saldo'] as num,
      );
}

class SavingsTxn {
  SavingsTxn({
    required this.id,
    required this.jenis,
    required this.nominal,
    required this.metode,
    required this.createdAt,
    this.keterangan,
  });

  final String id;
  final String jenis;
  final num nominal;
  final String metode;
  final String createdAt;
  final String? keterangan;

  bool get isSetor => jenis == 'setor';

  factory SavingsTxn.fromJson(Map<String, dynamic> j) => SavingsTxn(
        id: j['id'] as String,
        jenis: j['jenis'] as String,
        nominal: j['nominal'] as num,
        metode: j['metode'] as String,
        createdAt: j['created_at'] as String,
        keterangan: j['keterangan'] as String?,
      );
}

class Loan {
  Loan({
    required this.id,
    required this.pokok,
    required this.tenor,
    required this.jasaPersen,
    required this.status,
    required this.tanggalPengajuan,
    this.tujuan,
  });

  final String id;
  final num pokok;
  final int tenor;
  final num jasaPersen;
  final String status;
  final String tanggalPengajuan;
  final String? tujuan;

  factory Loan.fromJson(Map<String, dynamic> j) => Loan(
        id: j['id'] as String,
        pokok: j['pokok'] as num,
        tenor: j['tenor'] as int,
        jasaPersen: j['jasa_persen'] as num,
        status: j['status'] as String,
        tanggalPengajuan: j['tanggal_pengajuan'] as String,
        tujuan: j['tujuan'] as String?,
      );
}

class Installment {
  Installment({
    required this.id,
    required this.angsuranKe,
    required this.jatuhTempo,
    required this.total,
    required this.status,
  });

  final String id;
  final int angsuranKe;
  final String jatuhTempo;
  final num total;
  final String status;

  bool get isLunas => status == 'lunas';

  factory Installment.fromJson(Map<String, dynamic> j) => Installment(
        id: j['id'] as String,
        angsuranKe: j['angsuran_ke'] as int,
        jatuhTempo: j['jatuh_tempo'] as String,
        total: j['total'] as num,
        status: j['status'] as String,
      );
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.judul,
    required this.isi,
    required this.tipe,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String judul;
  final String isi;
  final String tipe;
  final String createdAt;
  final String? readAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        judul: j['judul'] as String,
        isi: j['isi'] as String,
        tipe: j['tipe'] as String,
        createdAt: j['created_at'] as String,
        readAt: j['read_at'] as String?,
      );
}
