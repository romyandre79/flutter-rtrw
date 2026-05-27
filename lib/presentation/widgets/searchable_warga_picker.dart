import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/logic/cubits/warga/warga_cubit.dart';
import 'package:flutter_pos/logic/cubits/warga/warga_state.dart';
import 'package:flutter_pos/data/models/warga.dart';
import 'package:flutter_pos/presentation/widgets/base_searchable_picker.dart';

class SearchableWargaPicker extends StatelessWidget {
  final Warga? selectedWarga;
  final Function(Warga?) onWargaSelected;
  final String? label;
  final String? hint;
  final String? Function(Warga?)? validator;

  const SearchableWargaPicker({
    super.key,
    this.selectedWarga,
    required this.onWargaSelected,
    this.label,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WargaCubit, WargaState>(
      builder: (context, state) {
        List<Warga> wargaList = [];
        bool isLoading = state is WargaLoading;

        if (state is WargaLoaded) {
          wargaList = state.wargaList;
        }

        return BaseSearchablePicker<Warga>(
          title: 'Pilih Warga',
          label: label,
          hint: hint,
          items: wargaList,
          isLoading: isLoading,
          selectedValue: selectedWarga,
          itemLabel: (warga) => warga.nama,
          itemSubtitle: (warga) => warga.noHp ?? 'No HP tidak ada',
          searchMatcher: (warga, query) => 
              warga.nama.toLowerCase().contains(query.toLowerCase()) ||
              (warga.noHp != null && warga.noHp!.contains(query)),
          onSelected: onWargaSelected,
          onRefresh: () => context.read<WargaCubit>().loadWarga(),
          validator: validator,
          icon: Icons.person,
          emptyMessage: 'Warga tidak ditemukan',
        );
      },
    );
  }
}
