import 'package:flutter/material.dart';
import '../models/models.dart';

class MoodChip extends StatelessWidget {
  final Mood mood;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  const MoodChip({
    super.key,
    required this.mood,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? const Color(0xFF1A535C).withValues(alpha: 0.15)
        : Colors.white;
    final border = selected
        ? const Color(0xFF1A535C)
        : Colors.grey.shade300;
    final textColor = selected
        ? const Color(0xFF1A535C)
        : Colors.grey.shade700;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 5 : 8,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: selected ? 1.5 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A535C).withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mood.emoji,
              style: TextStyle(fontSize: compact ? 14 : 16),
            ),
            const SizedBox(width: 5),
            Text(
              mood.label,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
