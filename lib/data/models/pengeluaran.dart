import 'package:equatable/equatable.dart';

class Pengeluaran extends Equatable {
  final int? id;
  final String kategori;
  final String? keterangan;
  final double jumlah;
  final String tanggal;
  final String? buktiPengeluaran;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Pengeluaran({
    this.id,
    required this.kategori,
    this.keterangan,
    required this.jumlah,
    required this.tanggal,
    this.buktiPengeluaran,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  static const List<String> kategoriList = [
    'Kebersihan',
    'Keamanan',
    'Perbaikan Fasilitas',
    'Kegiatan Sosial',
    'Administrasi',
    'Listrik & Air',
    'Lainnya',
  ];

  factory Pengeluaran.fromMap(Map<String, dynamic> map) {
    return Pengeluaran(
      id: map['id'] as int?,
      kategori: map['kategori'] as String,
      keterangan: map['keterangan'] as String?,
      jumlah: (map['jumlah'] as num?)?.toDouble() ?? 0,
      tanggal: map['tanggal'] as String,
      buktiPengeluaran: map['bukti_pengeluaran'] as String?,
      createdBy: map['created_by'] as int?,
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
      'kategori': kategori,
      'keterangan': keterangan,
      'jumlah': jumlah,
      'tanggal': tanggal,
      'bukti_pengeluaran': buktiPengeluaran,
      'created_by': createdBy,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Pengeluaran copyWith({
    int? id,
    String? kategori,
    String? keterangan,
    double? jumlah,
    String? tanggal,
    String? buktiPengeluaran,
    int? createdBy,
  }) {
    return Pengeluaran(
      id: id ?? this.id,
      kategori: kategori ?? this.kategori,
      keterangan: keterangan ?? this.keterangan,
      jumlah: jumlah ?? this.jumlah,
      tanggal: tanggal ?? this.tanggal,
      buktiPengeluaran: buktiPengeluaran ?? this.buktiPengeluaran,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, kategori, jumlah, tanggal];
}
