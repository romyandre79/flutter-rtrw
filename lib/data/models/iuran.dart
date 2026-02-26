import 'package:equatable/equatable.dart';

enum JenisIuran { bulanan, tahunan, insidentil }
enum StatusBayar { lunas, belumBayar }

class Iuran extends Equatable {
  final int? id;
  final int? wargaId;
  final int? rumahId;
  final String jenis; // bulanan, tahunan, insidentil
  final String? keterangan;
  final double jumlah;
  final String? periode; // e.g. "2026-02" for monthly, "2026" for yearly
  final String? tanggalBayar;
  final String statusBayar; // lunas, belum_bayar
  final String? buktiPembayaran;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Populated from join
  final String? wargaNama;
  final String? rumahNomor;

  const Iuran({
    this.id,
    this.wargaId,
    this.rumahId,
    this.jenis = 'bulanan',
    this.keterangan,
    required this.jumlah,
    this.periode,
    this.tanggalBayar,
    this.statusBayar = 'belum_bayar',
    this.buktiPembayaran,
    this.createdAt,
    this.updatedAt,
    this.wargaNama,
    this.rumahNomor,
  });

  String get jenisDisplay {
    switch (jenis) {
      case 'bulanan':
        return 'Bulanan';
      case 'tahunan':
        return 'Tahunan';
      case 'insidentil':
        return 'Insidentil';
      default:
        return jenis;
    }
  }

  String get statusDisplay => statusBayar == 'lunas' ? 'Lunas' : 'Belum Bayar';
  bool get isLunas => statusBayar == 'lunas';

  factory Iuran.fromMap(Map<String, dynamic> map) {
    return Iuran(
      id: map['id'] as int?,
      wargaId: map['warga_id'] as int?,
      rumahId: map['rumah_id'] as int?,
      jenis: (map['jenis'] as String?) ?? 'bulanan',
      keterangan: map['keterangan'] as String?,
      jumlah: (map['jumlah'] as num?)?.toDouble() ?? 0,
      periode: map['periode'] as String?,
      tanggalBayar: map['tanggal_bayar'] as String?,
      statusBayar: (map['status_bayar'] as String?) ?? 'belum_bayar',
      buktiPembayaran: map['bukti_pembayaran'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      wargaNama: map['warga_nama'] as String?,
      rumahNomor: map['rumah_nomor'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'warga_id': wargaId,
      'rumah_id': rumahId,
      'jenis': jenis,
      'keterangan': keterangan,
      'jumlah': jumlah,
      'periode': periode,
      'tanggal_bayar': tanggalBayar,
      'status_bayar': statusBayar,
      'bukti_pembayaran': buktiPembayaran,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Iuran copyWith({
    int? id,
    int? wargaId,
    int? rumahId,
    String? jenis,
    String? keterangan,
    double? jumlah,
    String? periode,
    String? tanggalBayar,
    String? statusBayar,
    String? buktiPembayaran,
  }) {
    return Iuran(
      id: id ?? this.id,
      wargaId: wargaId ?? this.wargaId,
      rumahId: rumahId ?? this.rumahId,
      jenis: jenis ?? this.jenis,
      keterangan: keterangan ?? this.keterangan,
      jumlah: jumlah ?? this.jumlah,
      periode: periode ?? this.periode,
      tanggalBayar: tanggalBayar ?? this.tanggalBayar,
      statusBayar: statusBayar ?? this.statusBayar,
      buktiPembayaran: buktiPembayaran ?? this.buktiPembayaran,
      createdAt: createdAt,
      updatedAt: updatedAt,
      wargaNama: wargaNama,
      rumahNomor: rumahNomor,
    );
  }

  @override
  List<Object?> get props => [id, wargaId, rumahId, jenis, jumlah, periode, statusBayar];
}
