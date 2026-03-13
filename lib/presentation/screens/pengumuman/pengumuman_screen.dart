import 'dart:io';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/warga.dart';
import 'package:flutter_pos/logic/cubits/warga/warga_cubit.dart';
import 'package:flutter_pos/logic/cubits/warga/warga_state.dart';
import 'package:flutter_pos/logic/cubits/settings/settings_cubit.dart';
import 'package:flutter_pos/logic/cubits/settings/settings_state.dart';
import 'package:flutter_pos/data/models/pengumuman_template.dart';
import 'package:flutter_pos/logic/cubits/pengumuman_template/pengumuman_template_cubit.dart';
import 'package:flutter_pos/logic/cubits/pengumuman_template/pengumuman_template_state.dart';
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
    context.read<PengumumanTemplateCubit>().loadTemplates();
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

    // Check for fonnte token
    final settingsState = context.read<SettingsCubit>().state;
    String fonnteToken = '';
    if (settingsState is SettingsLoaded) {
      fonnteToken = settingsState.storeInfo.fonnteToken;
    } else if (settingsState is SettingsUpdated) {
      fonnteToken = settingsState.storeInfo.fonnteToken;
    } else {
      fonnteToken = context.read<SettingsCubit>().currentInfo?.fonnteToken ?? '';
    }

    if (fonnteToken.isEmpty) {
       // Fallback to manual WhatsApp opening if no token is set
       _sendManualWhatsapp(pesan, selectedWarga);
       return;
    }

    // Direct send via Fonnte API
    _sendDirectWhatsapp(pesan, selectedWarga, fonnteToken);
  }

  Future<void> _sendDirectWhatsapp(String pesan, List<Warga> selectedWarga, String token) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    int successCount = 0;
    int failCount = 0;
    
    // Prepare phone numbers
    List<String> validNumbers = [];
    for (final warga in selectedWarga) {
      if (warga.noHp == null || warga.noHp!.isEmpty) continue;
      
      String noHp = warga.noHp!.replaceAll(RegExp(r'[^0-9]'), '');
      if (noHp.startsWith('0')) {
        noHp = '62${noHp.substring(1)}';
      } else if (!noHp.startsWith('62')) {
        noHp = '62$noHp';
      }
      validNumbers.add(noHp);
    }

    if (validNumbers.isEmpty) {
      if (mounted) Navigator.pop(context); // hide loading
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada nomor HP valid untuk dikirim.')),
      );
      return;
    }

    try {
      // Fonnte API endpoint for sending messages
      final url = Uri.parse('https://api.fonnte.com/send');
      final target = validNumbers.join(',');

      final response = await http.post(
        url,
        headers: {
          'Authorization': token,
        },
        body: {
          'target': target,
          'message': pesan,
        }
      );

      if (mounted) Navigator.pop(context); // hide loading

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selesai. Pesan berhasil dikirim ke ${validNumbers.length} nomor.')),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim via Fonnte: ${data['reason']}'), backgroundColor: AppThemeColors.error),
          );
        }
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error server Fonnte: ${response.statusCode}'), backgroundColor: AppThemeColors.error),
         );
      }

    } catch (e) {
      if (mounted) Navigator.pop(context); // hide loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: AppThemeColors.error),
      );
    }
  }

  Future<void> _sendManualWhatsapp(String pesan, List<Warga> selectedWarga) async {
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

  void _showSaveTemplateDialog() {
    final pesan = _pesanController.text.trim();
    if (pesan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis pesan pengumuman terlebih dahulu')),
      );
      return;
    }

    final judulController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simpan sebagai Template'),
        content: TextField(
          controller: judulController,
          decoration: const InputDecoration(
            hintText: 'Judul Template (misal: Tagihan Air)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final judul = judulController.text.trim();
              if (judul.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Judul tidak boleh kosong')),
                 );
                 return;
              }
              final template = PengumumanTemplate(judul: judul, isi: pesan);
              context.read<PengumumanTemplateCubit>().addTemplate(template);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppThemeColors.primary),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  void _showTemplatesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Template Tersimpan', style: AppTypography.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: BlocConsumer<PengumumanTemplateCubit, PengumumanTemplateState>(
                    listener: (context, state) {
                      if (state is PengumumanTemplateOperationSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.message), backgroundColor: AppThemeColors.success),
                        );
                      } else if (state is PengumumanTemplateError) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.message), backgroundColor: AppThemeColors.error),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is PengumumanTemplateLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is PengumumanTemplateLoaded) {
                        if (state.templates.isEmpty) {
                          return const Center(child: Text('Belum ada template tersimpan'));
                        }

                        return ListView.separated(
                          controller: scrollController,
                          itemCount: state.templates.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final template = state.templates[index];
                            return ListTile(
                              title: Text(template.judul, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                              subtitle: Text(template.isi, maxLines: 2, overflow: TextOverflow.ellipsis),
                              onTap: () {
                                _pesanController.text = template.isi;
                                Navigator.pop(context);
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppThemeColors.error),
                                onPressed: () {
                                  context.read<PengumumanTemplateCubit>().deleteTemplate(template.id!);
                                },
                              ),
                            );
                          },
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                )
              ],
            );
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      appBar: AppBar(
        title: const Text('Kirim Pengumuman'),
        backgroundColor: AppThemeColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
             icon: const Icon(Icons.bookmarks),
             tooltip: 'Template Tersimpan',
             onPressed: _showTemplatesModal,
          ),
        ],
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
                suffixIcon: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.save_outlined),
                      tooltip: 'Simpan sebagai Template',
                      color: AppThemeColors.primary,
                      onPressed: _showSaveTemplateDialog,
                    ),
                  ],
                ),
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
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              bool hasFonnte = false;
              if (state is SettingsLoaded && state.storeInfo.fonnteToken.isNotEmpty) {
                 hasFonnte = true;
              } else if (state is SettingsUpdated && state.storeInfo.fonnteToken.isNotEmpty) {
                 hasFonnte = true;
              } else if (context.read<SettingsCubit>().currentInfo?.fonnteToken.isNotEmpty == true) {
                 hasFonnte = true;
              }

              return ElevatedButton.icon(
                onPressed: _sendPengumuman,
                icon: const Icon(Icons.send),
                label: Text(hasFonnte ? 'Kirim Langsung (Fonnte)' : 'Kirim via Aplikasi WA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              );
            }
          ),
        ),
      ),
    );
  }
}
