import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

class ListQueryBar extends StatelessWidget {
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final String sortValue;
  final Map<String, String> sortOptions;
  final ValueChanged<String?> onSortChanged;
  final String filterValue;
  final Map<String, String> filterOptions;
  final ValueChanged<String?> onFilterChanged;
  final int resultCount;

  const ListQueryBar({
    super.key,
    required this.searchHint,
    required this.onSearchChanged,
    required this.sortValue,
    required this.sortOptions,
    required this.onSortChanged,
    required this.filterValue,
    required this.filterOptions,
    required this.onFilterChanged,
    required this.resultCount,
  });

  InputDecoration _decoration({required String label, IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE7E9EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            key: const Key('listSearchField'),
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: _decoration(
              label: searchHint,
              prefixIcon: Icons.search_rounded,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('sort-$sortValue'),
                  initialValue: sortValue,
                  isExpanded: true,
                  decoration: _decoration(
                    label: 'Sắp xếp',
                    prefixIcon: Icons.sort_rounded,
                  ),
                  items: sortOptions.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onSortChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('filter-$filterValue'),
                  initialValue: filterValue,
                  isExpanded: true,
                  decoration: _decoration(
                    label: 'Bộ lọc',
                    prefixIcon: Icons.filter_alt_outlined,
                  ),
                  items: filterOptions.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onFilterChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$resultCount kết quả',
              style: const TextStyle(
                color: AppColors.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
