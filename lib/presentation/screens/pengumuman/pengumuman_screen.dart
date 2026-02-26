import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/warga.dart';
import 'package:flutter_pos/logic/cubits/warga/warga_cubit.dart';
import 'package:flutter_pos/logic/cubits/warga/warga_state.dart';
import 'package:url_launcher/url_launcher.dart';

class PengumumanScreen extends StatefulWidget {
  const PengumumanScreen({super.key});

  @override
  State<PengumumanScreen> createState() => _PengumumanScreenState();
}

class _PengumumanScreenState extends State<PengumumanScreen> {
  final TextEditingController _pesanController = TextEditingController();
  final Set<int> _selectedWargaIds = {};
  bool _selectAll = false;
  List<Warga> _currentWargaList = [];

  @override
  void initState() {
    super.initState();
    context.read<WargaCubit>().loadAll();
  }

  @override
  void dispose() {
    _pesanController.dispose();
    super.dispose();
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedWargaIds.addAll(
            _currentWargaList.where((w) => w.id != null && w.noHp != null && w.noHp!.isNotEmpty).map((w) => w.id!));
      } else {
        _selectedWargaIds.clear();
      }
    });
  }

  void _toggleWargaSelection(int wargaId, bool? value) {
    setState(() {
      if (value == true) {
        _selectedWargaIds.add(wargaId);
      } else {
        _selectedWargaIds.remove(wargaId);
      }
      
      final wargaWithHpCount = _currentWargaList.where((w) => w.id != null && w.noHp != null && w.noHp!.isNotEmpty).length;
      _selectAll = _selectedWargaIds.length == wargaWithHpCount && _currentWargaList.isNotEmpty;
    });
  }

  Future<void> _sendPengumuman() async {
    final pesan = _pesanController.text.trim();
    if (pesan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan tidak boleh kosong')),
      );
      return;
    }

    if (_selectedWargaIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu warga')),
      );
      return;
    }

    final selectedWarga = _currentWargaList
        .where((w) => w.id != null && _selectedWargaIds.contains(w.id))
        .toList();

    int successCount = 0;
    int failCount = 0;

    for (final warga in selectedWarga) {
      if (warga.noHp == null || warga.noHp!.isEmpty) {
        failCount++;
        continue;
      }

      String noHp = warga.noHp!.replaceAll(RegExp(r'[^0-9]'), '');
      if (noHp.startsWith('0')) {
        noHp = '62${noHp.substring(1)}';
      } else if (!noHp.startsWith('62')) {
        noHp = '62$noHp';
      }

      final urlString = 'https://wa.me/$noHp?text=${Uri.encodeComponent(pesan)}';
      final url = Uri.parse(urlString);

      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          successCount++;
          // Add a delay between opening links so that they can be handled individually by the browser/app.
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Selesai. Membuka WA untuk $successCount warga.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      appBar: AppBar(
        title: const Text('Kirim Pengumuman'),
        backgroundColor: AppThemeColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Colors.white,
            child: TextField(
              controller: _pesanController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tulis pesan pengumuman di sini...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppThemeColors.background,
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppThemeColors.primary.withValues(alpha: 0.05),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _selectAll,
                  onChanged: _toggleSelectAll,
                  activeColor: AppThemeColors.primary,
                ),
                Text(
                  'Pilih Semua Warga',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_selectedWargaIds.length} Terpilih',
                  style: AppTypography.labelMedium.copyWith(color: AppThemeColors.primary),
                ),
              ],
            ),
          ),

          Expanded(
            child: BlocConsumer<WargaCubit, WargaState>(
              listener: (context, state) {
                if (state is WargaLoaded) {
                  setState(() {
                    _currentWargaList = state.wargaList;
                  });
                }
              },
              builder: (context, state) {
                if (state is WargaLoading && _currentWargaList.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppThemeColors.primary));
                }
                if (state is WargaError) {
                  return Center(child: Text(state.message));
                }
                
                if (_currentWargaList.isEmpty) {
                   return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: AppThemeColors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('Belum ada data warga', style: AppTypography.bodyMedium.copyWith(color: AppThemeColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: _currentWargaList.length,
                  itemBuilder: (context, index) {
                    final warga = _currentWargaList[index];
                    final isSelected = warga.id != null && _selectedWargaIds.contains(warga.id);
                    final hasHp = warga.noHp != null && warga.noHp!.isNotEmpty;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppThemeColors.primarySurface,
                        backgroundImage: warga.fotoProfil != null && File(warga.fotoProfil!).existsSync()
                            ? FileImage(File(warga.fotoProfil!))
                            : null,
                        child: warga.fotoProfil == null || !File(warga.fotoProfil!).existsSync()
                            ? Icon(
                                warga.jenisKelamin == JenisKelamin.P ? Icons.woman : Icons.man,
                                color: AppThemeColors.primary,
                              )
                            : null,
                      ),
                      title: Text(warga.nama, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        hasHp ? warga.noHp! : 'Tidak ada no. HP',
                        style: TextStyle(color: hasHp ? AppThemeColors.textSecondary : AppThemeColors.error),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: hasHp ? (value) => _toggleWargaSelection(warga.id!, value) : null,
                        activeColor: AppThemeColors.primary,
                      ),
                      onTap: hasHp ? () => _toggleWargaSelection(warga.id!, !isSelected) : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ElevatedButton.icon(
            onPressed: _sendPengumuman,
            icon: const Icon(Icons.send),
            label: const Text('Kirim Pengumuman via WA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
