import 'package:flutter/material.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';

class BaseSearchablePicker<T> extends StatefulWidget {
  final T? selectedValue;
  final String title;
  final List<T> items;
  final String Function(T) itemLabel;
  final String Function(T)? itemSubtitle;
  final bool Function(T, String) searchMatcher;
  final void Function(T) onSelected;
  final String? label;
  final String? hint;
  final String? Function(T?)? validator;
  final IconData icon;
  final VoidCallback? onRefresh;
  final bool isLoading;
  final String emptyMessage;

  const BaseSearchablePicker({
    super.key,
    this.selectedValue,
    required this.title,
    required this.items,
    required this.itemLabel,
    this.itemSubtitle,
    required this.searchMatcher,
    required this.onSelected,
    this.label,
    this.hint,
    this.validator,
    this.icon = Icons.search,
    this.onRefresh,
    this.isLoading = false,
    this.emptyMessage = 'Data tidak ditemukan',
  });

  @override
  State<BaseSearchablePicker<T>> createState() => _BaseSearchablePickerState<T>();
}

class _BaseSearchablePickerState<T> extends State<BaseSearchablePicker<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPicker(BuildContext context) {
    _searchController.clear();
    _searchQuery = '';
    
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredItems = widget.items
              .where((item) => widget.searchMatcher(item, _searchQuery))
              .toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: AppThemeColors.primarySurface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: AppThemeColors.primary),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppThemeColors.primary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                // List
                Expanded(
                  child: widget.isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off, size: 48, color: Colors.grey),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  _searchQuery.isEmpty 
                                    ? 'Belum ada data' 
                                    : widget.emptyMessage, 
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredItems.length,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final isSelected = item == widget.selectedValue;

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: isSelected ? AppThemeColors.primary : Colors.grey,
                                ),
                                title: Text(widget.itemLabel(item), style: const TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: widget.itemSubtitle != null 
                                  ? Text(widget.itemSubtitle!(item), style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)
                                  : null,
                                onTap: () {
                                  widget.onSelected(item);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: AppThemeColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        InkWell(
          onTap: () => _showPicker(context),
          borderRadius: BorderRadius.circular(12),
          child: FormField<T>(
            initialValue: widget.selectedValue,
            validator: widget.validator,
            builder: (state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: state.hasError ? AppThemeColors.error : AppThemeColors.border,
                        width: state.hasError ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(widget.icon, color: AppThemeColors.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            widget.selectedValue == null
                                ? (widget.hint ?? 'Pilih Data')
                                : widget.itemLabel(widget.selectedValue as T),
                            style: TextStyle(
                              color: widget.selectedValue == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                  if (state.hasError) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.md),
                      child: Text(
                        state.errorText ?? '',
                        style: const TextStyle(color: AppThemeColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
