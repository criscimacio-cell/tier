import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color? activeColor;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 18,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? const Color(0xFFF39C12);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        IconData icon;
        if (rating >= starValue) {
          icon = Icons.star_rounded;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(icon, size: size, color: color);
      }),
    );
  }
}

class InteractiveStarRating extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final double size;

  const InteractiveStarRating({
    super.key,
    required this.initialRating,
    required this.onRatingChanged,
    this.size = 36,
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = (i + 1).toDouble();
        return GestureDetector(
          onTap: () {
            setState(() => _rating = starValue);
            widget.onRatingChanged(starValue);
          },
          child: Icon(
            _rating >= starValue ? Icons.star_rounded : Icons.star_border_rounded,
            size: widget.size,
            color: const Color(0xFFF39C12),
          ),
        );
      }),
    );
  }
}
