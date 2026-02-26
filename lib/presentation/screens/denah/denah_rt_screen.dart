import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/database/database_helper.dart';
import 'package:flutter_pos/data/models/warga.dart';
import 'package:flutter_pos/data/repositories/warga_repository.dart';
import 'package:flutter_pos/logic/cubits/warga/warga_cubit.dart';
import 'package:flutter_pos/presentation/screens/warga/warga_form_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DenahPin {
  final int? id;
  final int? wargaId;
  final int? rumahId;
  final double xPercent;
  final double yPercent;
  final String? label;

  DenahPin({this.id, this.wargaId, this.rumahId, required this.xPercent, required this.yPercent, this.label});

  factory DenahPin.fromMap(Map<String, dynamic> map) {
    return DenahPin(
      id: map['id'] as int?,
      wargaId: map['warga_id'] as int?,
      rumahId: map['rumah_id'] as int?,
      xPercent: (map['x_percent'] as num).toDouble(),
      yPercent: (map['y_percent'] as num).toDouble(),
      label: map['warga_nama'] as String? ?? map['label'] as String?,
    );
  }
}

class DenahRtScreen extends StatefulWidget {
  const DenahRtScreen({super.key});

  @override
  State<DenahRtScreen> createState() => _DenahRtScreenState();
}

class _DenahRtScreenState extends State<DenahRtScreen> {
  String? _denahPath;
  final _picker = ImagePicker();
  bool _loading = true;
  bool _editMode = false;
  List<DenahPin> _pins = [];
  final _transformController = TransformationController();
  Size _imageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadDenah();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadDenah() async {
    setState(() => _loading = true);
    try {
      final db = await DatabaseHelper.instance.database;

      final result = await db.query('app_settings', where: "key = ?", whereArgs: ['denah_rt']);
      if (result.isNotEmpty && result.first['value'] != null) {
        final path = result.first['value'] as String;
        if (path.isNotEmpty && File(path).existsSync()) {
          _denahPath = path;
          // Get actual image dimensions
          final bytes = File(path).readAsBytesSync();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          _imageSize = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
          frame.image.dispose();
        }
      }

      final pinResults = await db.rawQuery('''
        SELECT dp.*, w.nama as warga_nama
        FROM denah_pin dp
        LEFT JOIN warga w ON dp.warga_id = w.id
        ORDER BY dp.created_at ASC
      ''');
      _pins = pinResults.map((m) => DenahPin.fromMap(m)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveDenah(String path) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query('app_settings', where: "key = ?", whereArgs: ['denah_rt']);
    if (existing.isEmpty) {
      await db.insert('app_settings', {'key': 'denah_rt', 'value': path});
    } else {
      await db.update('app_settings', {'value': path}, where: "key = ?", whereArgs: ['denah_rt']);
    }
  }

  Future<void> _pickDenah() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 2000);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/photos/denah');
    if (!await photosDir.exists()) await photosDir.create(recursive: true);

    final ext = p.extension(picked.path);
    final fileName = 'denah_rt_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedFile = await File(picked.path).copy('${photosDir.path}/$fileName');

    await _saveDenah(savedFile.path);
    setState(() => _denahPath = savedFile.path);

    // Reload to get image dimensions
    await _loadDenah();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Denah RT berhasil diperbarui'), backgroundColor: AppThemeColors.success),
      );
    }
  }

  void _handleTap(TapUpDetails details) async {
    if (!_editMode || _imageSize == Size.zero) return;

    // localPosition is relative to the GestureDetector = the SizedBox = image size
    final xPercent = (details.localPosition.dx / _imageSize.width).clamp(0.0, 1.0);
    final yPercent = (details.localPosition.dy / _imageSize.height).clamp(0.0, 1.0);

    final wargaRepo = WargaRepository();
    final wargaList = await wargaRepo.getAll(status: 'aktif');
    if (!mounted) return;

    final selected = await showDialog<Warga>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pilih Warga'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: wargaList.isEmpty
              ? const Center(child: Text('Belum ada data warga'))
              : ListView.builder(
                  itemCount: wargaList.length,
                  itemBuilder: (context, index) {
                    final w = wargaList[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppThemeColors.primarySurface,
                        child: Text(w.nama[0], style: const TextStyle(color: AppThemeColors.primary, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(w.nama),
                      subtitle: w.noHp != null ? Text(w.noHp!) : null,
                      onTap: () => Navigator.pop(context, w),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ],
      ),
    );

    if (selected == null) return;

    final db = await DatabaseHelper.instance.database;
    await db.insert('denah_pin', {
      'warga_id': selected.id,
      'rumah_id': selected.rumahId,
      'x_percent': xPercent,
      'y_percent': yPercent,
      'label': selected.nama,
    });

    await _loadDenah();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pin ditambahkan untuk ${selected.nama}'), backgroundColor: AppThemeColors.success),
      );
    }
  }

  Future<void> _deletePin(DenahPin pin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pin'),
        content: Text('Hapus pin untuk ${pin.label ?? "warga"}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppThemeColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && pin.id != null) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('denah_pin', where: 'id = ?', whereArgs: [pin.id]);
      await _loadDenah();
    }
  }

  Future<void> _navigateToWarga(DenahPin pin) async {
    if (pin.wargaId == null) return;

    // Fetch full warga data
    final wargaRepo = WargaRepository();
    final warga = await wargaRepo.getById(pin.wargaId!);
    if (warga == null || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => WargaCubit(),
          child: WargaFormScreen(warga: warga),
        ),
      ),
    );

    // Reload pins — warga name may have changed
    await _loadDenah();
  }

  void _zoomIn() {
    final current = _transformController.value.clone();
    final scale = current.getMaxScaleOnAxis();
    if (scale < 4.0) {
      // Zoom toward center of viewport
      final double newScale = (scale * 1.5).clamp(0.3, 4.0);
      final double factor = newScale / scale;
      current.scale(factor);
      _transformController.value = current;
    }
  }

  void _zoomOut() {
    final current = _transformController.value.clone();
    final scale = current.getMaxScaleOnAxis();
    if (scale > 0.3) {
      final double newScale = (scale / 1.5).clamp(0.3, 4.0);
      final double factor = newScale / scale;
      current.scale(factor);
      _transformController.value = current;
    }
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      appBar: AppBar(
        title: const Text('Denah RT'),
        backgroundColor: AppThemeColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_denahPath != null)
            IconButton(
              icon: Icon(_editMode ? Icons.check : Icons.edit_location_alt),
              onPressed: () => setState(() => _editMode = !_editMode),
              tooltip: _editMode ? 'Selesai' : 'Tambah Pin',
            ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _pickDenah,
            tooltip: 'Upload Denah',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppThemeColors.primary))
          : _denahPath != null && _imageSize != Size.zero
              ? Column(
                  children: [
                    if (_editMode)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                        color: AppThemeColors.warning.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            const Icon(Icons.touch_app, color: AppThemeColors.warning, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Ketuk pada denah untuk menandai lokasi warga. Ketuk pin untuk menghapus.',
                                style: AppTypography.bodySmall.copyWith(color: AppThemeColors.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Map area — original size, scrollable, zoomable
                    Expanded(
                      child: Stack(
                        children: [
                          InteractiveViewer(
                            transformationController: _transformController,
                            constrained: false,
                            minScale: 0.3,
                            maxScale: 4.0,
                            boundaryMargin: const EdgeInsets.all(200),
                            child: GestureDetector(
                              onTapUp: _editMode ? _handleTap : null,
                              child: SizedBox(
                                width: _imageSize.width,
                                height: _imageSize.height,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Image at original size
                                    Positioned.fill(
                                      child: Image.file(
                                        File(_denahPath!),
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    // Pins at exact positions
                                    for (int i = 0; i < _pins.length; i++)
                                      Positioned(
                                        left: _pins[i].xPercent * _imageSize.width,
                                        top: _pins[i].yPercent * _imageSize.height,
                                        child: FractionalTranslation(
                                          translation: const Offset(-0.5, -1.0),
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              if (_editMode) {
                                                _deletePin(_pins[i]);
                                              } else {
                                                _navigateToWarga(_pins[i]);
                                              }
                                            },
                                            child: _buildPinWidget(i),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Zoom controls
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _zoomButton(Icons.add, _zoomIn),
                                const SizedBox(height: 4),
                                _zoomButton(Icons.restart_alt, _resetZoom),
                                const SizedBox(height: 4),
                                _zoomButton(Icons.remove, _zoomOut),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Pin chip list
                    if (_pins.isNotEmpty)
                      Container(
                        height: 80,
                        color: Colors.white,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                            },
                          ),
                          child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                          itemCount: _pins.length,
                          itemBuilder: (context, index) {
                            final pin = _pins[index];
                            return GestureDetector(
                              onTap: () {
                                if (_editMode) {
                                  _deletePin(pin);
                                } else {
                                  _navigateToWarga(pin);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: AppSpacing.sm),
                                child: Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: AppThemeColors.primary,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  label: Text(pin.label ?? 'Warga', style: AppTypography.labelSmall),
                                  deleteIcon: _editMode ? const Icon(Icons.close, size: 16) : null,
                                  onDeleted: _editMode ? () => _deletePin(pin) : null,
                                  backgroundColor: AppThemeColors.primarySurface,
                                ),
                              ),
                            );
                          },
                        ),
                        ),
                      ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 80,
                          color: AppThemeColors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Belum ada denah RT',
                          style: AppTypography.bodyLarge.copyWith(color: AppThemeColors.textSecondary)),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Upload gambar denah RT terlebih dahulu',
                          style: AppTypography.bodySmall.copyWith(color: AppThemeColors.textSecondary)),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton.icon(
                        onPressed: _pickDenah,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Upload Denah RT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppThemeColors.primary),
        ),
      ),
    );
  }

  Widget _buildPinWidget(int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _editMode ? AppThemeColors.error : AppThemeColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        Icon(Icons.location_pin,
          color: _editMode ? AppThemeColors.error : Colors.red,
          size: 20,
        ),
      ],
    );
  }
}
