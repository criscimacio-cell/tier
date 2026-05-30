import 'package:flutter/material.dart';
import '../models/models.dart';

class BadgeCard extends StatelessWidget {
  final AppBadge badge;

  const BadgeCard({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: badge.earned ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: badge.earned
            ? [
                BoxShadow(
                  color: const Color(0xFF1A535C).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
        border: Border.all(
          color: badge.earned
              ? const Color(0xFF1A535C).withValues(alpha: 0.2)
              : Colors.grey.shade200,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.earned
                      ? const Color(0xFFF7F3E9)
                      : Colors.grey.shade200,
                  border: Border.all(
                    color: badge.earned
                        ? const Color(0xFFF39C12).withValues(alpha: 0.4)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    badge.emoji,
                    style: TextStyle(
                      fontSize: 26,
                      color: badge.earned ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              if (!badge.earned)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade400,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (badge.earned)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF27AE60),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: badge.earned ? const Color(0xFF1A1A2E) : Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            badge.description,
            style: TextStyle(
              fontSize: 10,
              color:
                  badge.earned ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
