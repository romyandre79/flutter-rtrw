import 'package:equatable/equatable.dart';

enum JenisKelamin { L, P }

enum StatusWarga { aktif, pindah, meninggal }

enum StatusKK { kepalaKeluarga, istri, anak, lainnya }

class Warga extends Equatable {
  final int? id;
  final String? nik;
  final String nama;
  final String? tempatLahir;
  final DateTime? tanggalLahir;
  final JenisKelamin? jenisKelamin;
  final String? agama;
  final String? statusPerkawinan;
  final String? pekerjaan;
  final String? noKk;
  final String? statusKk;
  final String? noHp;
  final String? alamat;
  final String? rt;
  final String? rw;
  final int? rumahId;
  final String? fotoKtp;
  final String? fotoKk;
  final String? fotoProfil;
  final StatusWarga status;
  final String? catatan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Warga({
    this.id,
    this.nik,
    required this.nama,
    this.tempatLahir,
    this.tanggalLahir,
    this.jenisKelamin,
    this.agama,
    this.statusPerkawinan,
    this.pekerjaan,
    this.noKk,
    this.statusKk,
    this.noHp,
    this.alamat,
    this.rt,
    this.rw,
    this.rumahId,
    this.fotoKtp,
    this.fotoKk,
    this.fotoProfil,
    this.status = StatusWarga.aktif,
    this.catatan,
    this.createdAt,
    this.updatedAt,
  });

  int? get usia {
    if (tanggalLahir == null) return null;
    final now = DateTime.now();
    int age = now.year - tanggalLahir!.year;
    if (now.month < tanggalLahir!.month ||
        (now.month == tanggalLahir!.month && now.day < tanggalLahir!.day)) {
      age--;
    }
    return age;
  }

  String get jenisKelaminDisplay {
    switch (jenisKelamin) {
      case JenisKelamin.L:
        return 'Laki-laki';
      case JenisKelamin.P:
        return 'Perempuan';
      default:
        return '-';
    }
  }

  String get statusDisplay {
    switch (status) {
      case StatusWarga.aktif:
        return 'Aktif';
      case StatusWarga.pindah:
        return 'Pindah';
      case StatusWarga.meninggal:
        return 'Meninggal';
    }
  }

  factory Warga.fromMap(Map<String, dynamic> map) {
    return Warga(
      id: map['id'] as int?,
      nik: map['nik'] as String?,
      nama: map['nama'] as String,
      tempatLahir: map['tempat_lahir'] as String?,
      tanggalLahir: map['tanggal_lahir'] != null
          ? DateTime.tryParse(map['tanggal_lahir'] as String)
          : null,
      jenisKelamin: map['jenis_kelamin'] == 'L'
          ? JenisKelamin.L
          : map['jenis_kelamin'] == 'P'
              ? JenisKelamin.P
              : null,
      agama: map['agama'] as String?,
      statusPerkawinan: map['status_perkawinan'] as String?,
      pekerjaan: map['pekerjaan'] as String?,
      noKk: map['no_kk'] as String?,
      statusKk: map['status_kk'] as String?,
      noHp: map['no_hp'] as String?,
      alamat: map['alamat'] as String?,
      rt: map['rt'] as String?,
      rw: map['rw'] as String?,
      rumahId: map['rumah_id'] as int?,
      fotoKtp: map['foto_ktp'] as String?,
      fotoKk: map['foto_kk'] as String?,
      fotoProfil: map['foto_profil'] as String?,
      status: StatusWarga.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'aktif'),
        orElse: () => StatusWarga.aktif,
      ),
      catatan: map['catatan'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nik': nik,
      'nama': nama,
      'tempat_lahir': tempatLahir,
      'tanggal_lahir': tanggalLahir?.toIso8601String(),
      'jenis_kelamin': jenisKelamin?.name,
      'agama': agama,
      'status_perkawinan': statusPerkawinan,
      'pekerjaan': pekerjaan,
      'no_kk': noKk,
      'status_kk': statusKk,
      'no_hp': noHp,
      'alamat': alamat,
      'rt': rt,
      'rw': rw,
      'rumah_id': rumahId,
      'foto_ktp': fotoKtp,
      'foto_kk': fotoKk,
      'foto_profil': fotoProfil,
      'status': status.name,
      'catatan': catatan,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Warga copyWith({
    int? id,
    String? nik,
    String? nama,
    String? tempatLahir,
    DateTime? tanggalLahir,
    JenisKelamin? jenisKelamin,
    String? agama,
    String? statusPerkawinan,
    String? pekerjaan,
    String? noKk,
    String? statusKk,
    String? noHp,
    String? alamat,
    String? rt,
    String? rw,
    int? rumahId,
    String? fotoKtp,
    String? fotoKk,
    String? fotoProfil,
    StatusWarga? status,
    String? catatan,
  }) {
    return Warga(
      id: id ?? this.id,
      nik: nik ?? this.nik,
      nama: nama ?? this.nama,
      tempatLahir: tempatLahir ?? this.tempatLahir,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      agama: agama ?? this.agama,
      statusPerkawinan: statusPerkawinan ?? this.statusPerkawinan,
      pekerjaan: pekerjaan ?? this.pekerjaan,
      noKk: noKk ?? this.noKk,
      statusKk: statusKk ?? this.statusKk,
      noHp: noHp ?? this.noHp,
      alamat: alamat ?? this.alamat,
      rt: rt ?? this.rt,
      rw: rw ?? this.rw,
      rumahId: rumahId ?? this.rumahId,
      fotoKtp: fotoKtp ?? this.fotoKtp,
      fotoKk: fotoKk ?? this.fotoKk,
      fotoProfil: fotoProfil ?? this.fotoProfil,
      status: status ?? this.status,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, nik, nama, status];
}
