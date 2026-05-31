import 'package:flutter/material.dart';
import '../models/models.dart';

class CategoryFilterBar extends StatelessWidget {
  final Category? selected;
  final ValueChanged<Category?> onSelected;

  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
              backgroundColor: Colors.white.withValues(alpha: 0.85),
              selectedColor: const Color(0xFF6366F1),
              labelStyle: TextStyle(
                color: selected == null ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          ...Category.values.map((cat) {
            final isSelected = selected == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                label: Text(cat.label),
                selected: isSelected,
                onSelected: (_) => onSelected(isSelected ? null : cat),
                backgroundColor: Colors.white.withValues(alpha: 0.85),
                selectedColor: cat.color,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
