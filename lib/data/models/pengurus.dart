import 'package:equatable/equatable.dart';

class Pengurus extends Equatable {
  final int? id;
  final int? wargaId;
  final String jabatan;
  final String? periodeMulai;
  final String? periodeSelesai;
  final String status;
  final String? catatan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Populated from join with warga
  final String? wargaNama;
  final String? wargaNoHp;
  final String? wargaFotoProfil;

  const Pengurus({
    this.id,
    this.wargaId,
    required this.jabatan,
    this.periodeMulai,
    this.periodeSelesai,
    this.status = 'aktif',
    this.catatan,
    this.createdAt,
    this.updatedAt,
    this.wargaNama,
    this.wargaNoHp,
    this.wargaFotoProfil,
  });

  String get statusDisplay => status == 'aktif' ? 'Aktif' : 'Non-Aktif';

  String get periodeDisplay {
    if (periodeMulai == null) return '-';
    final mulai = periodeMulai ?? '-';
    final selesai = periodeSelesai ?? 'sekarang';
    return '$mulai - $selesai';
  }

  factory Pengurus.fromMap(Map<String, dynamic> map) {
    return Pengurus(
      id: map['id'] as int?,
      wargaId: map['warga_id'] as int?,
      jabatan: map['jabatan'] as String,
      periodeMulai: map['periode_mulai'] as String?,
      periodeSelesai: map['periode_selesai'] as String?,
      status: (map['status'] as String?) ?? 'aktif',
      catatan: map['catatan'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      wargaNama: map['warga_nama'] as String?,
      wargaNoHp: map['warga_no_hp'] as String?,
      wargaFotoProfil: map['warga_foto_profil'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'warga_id': wargaId,
      'jabatan': jabatan,
      'periode_mulai': periodeMulai,
      'periode_selesai': periodeSelesai,
      'status': status,
      'catatan': catatan,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Pengurus copyWith({
    int? id,
    int? wargaId,
    String? jabatan,
    String? periodeMulai,
    String? periodeSelesai,
    String? status,
    String? catatan,
  }) {
    return Pengurus(
      id: id ?? this.id,
      wargaId: wargaId ?? this.wargaId,
      jabatan: jabatan ?? this.jabatan,
      periodeMulai: periodeMulai ?? this.periodeMulai,
      periodeSelesai: periodeSelesai ?? this.periodeSelesai,
      status: status ?? this.status,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt,
      updatedAt: updatedAt,
      wargaNama: wargaNama,
      wargaNoHp: wargaNoHp,
      wargaFotoProfil: wargaFotoProfil,
    );
  }

  @override
  List<Object?> get props => [id, wargaId, jabatan, status];
}
