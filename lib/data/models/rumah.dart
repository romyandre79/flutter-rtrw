import 'package:equatable/equatable.dart';

class Rumah extends Equatable {
  final int? id;
  final String nomorRumah;
  final String? blok;
  final String? alamat;
  final String? rt;
  final String? rw;
  final String statusKepemilikan;
  final double? luasTanah;
  final double? luasBangunan;
  final String? foto;
  final String? catatan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Populated from join
  final int penghuniCount;

  const Rumah({
    this.id,
    required this.nomorRumah,
    this.blok,
    this.alamat,
    this.rt,
    this.rw,
    this.statusKepemilikan = 'Milik Sendiri',
    this.luasTanah,
    this.luasBangunan,
    this.foto,
    this.catatan,
    this.createdAt,
    this.updatedAt,
    this.penghuniCount = 0,
  });

  String get displayName {
    if (blok != null && blok!.isNotEmpty) {
      return 'Blok $blok No. $nomorRumah';
    }
    return 'No. $nomorRumah';
  }

  factory Rumah.fromMap(Map<String, dynamic> map) {
    return Rumah(
      id: map['id'] as int?,
      nomorRumah: map['nomor_rumah'] as String,
      blok: map['blok'] as String?,
      alamat: map['alamat'] as String?,
      rt: map['rt'] as String?,
      rw: map['rw'] as String?,
      statusKepemilikan: (map['status_kepemilikan'] as String?) ?? 'Milik Sendiri',
      luasTanah: (map['luas_tanah'] as num?)?.toDouble(),
      luasBangunan: (map['luas_bangunan'] as num?)?.toDouble(),
      foto: map['foto'] as String?,
      catatan: map['catatan'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      penghuniCount: (map['penghuni_count'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nomor_rumah': nomorRumah,
      'blok': blok,
      'alamat': alamat,
      'rt': rt,
      'rw': rw,
      'status_kepemilikan': statusKepemilikan,
      'luas_tanah': luasTanah,
      'luas_bangunan': luasBangunan,
      'foto': foto,
      'catatan': catatan,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Rumah copyWith({
    int? id,
    String? nomorRumah,
    String? blok,
    String? alamat,
    String? rt,
    String? rw,
    String? statusKepemilikan,
    double? luasTanah,
    double? luasBangunan,
    String? foto,
    String? catatan,
  }) {
    return Rumah(
      id: id ?? this.id,
      nomorRumah: nomorRumah ?? this.nomorRumah,
      blok: blok ?? this.blok,
      alamat: alamat ?? this.alamat,
      rt: rt ?? this.rt,
      rw: rw ?? this.rw,
      statusKepemilikan: statusKepemilikan ?? this.statusKepemilikan,
      luasTanah: luasTanah ?? this.luasTanah,
      luasBangunan: luasBangunan ?? this.luasBangunan,
      foto: foto ?? this.foto,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt,
      updatedAt: updatedAt,
      penghuniCount: penghuniCount,
    );
  }

  @override
  List<Object?> get props => [id, nomorRumah, blok, rt, rw];
}
