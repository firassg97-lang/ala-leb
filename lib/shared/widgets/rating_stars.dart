import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int count;
  final double size;
  final bool showCount;

  const RatingStars({
    super.key,
    required this.rating,
    this.count = 0,
    this.size = 16,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          if (i < rating.floor()) {
            return Icon(Icons.star, size: size, color: warningColor);
          } else if (i < rating && rating - i >= 0.5) {
            return Icon(Icons.star_half, size: size, color: warningColor);
          } else {
            return Icon(Icons.star_border, size: size, color: Colors.grey[300]);
          }
        }),
        if (showCount && count > 0) ...[
          const SizedBox(width: 4),
          Text('($count)',
              style: TextStyle(
                  fontSize: size * 0.75, color: Colors.grey)),
        ],
      ],
    );
  }
}

class InteractiveRatingStars extends StatefulWidget {
  final int initialRating;
  final void Function(int) onRatingChanged;
  final double size;

  const InteractiveRatingStars({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 40,
  });

  @override
  State<InteractiveRatingStars> createState() => _InteractiveRatingStarsState();
}

class _InteractiveRatingStarsState extends State<InteractiveRatingStars> {
  late int _rating;

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
        return GestureDetector(
          onTap: () {
            setState(() => _rating = i + 1);
            widget.onRatingChanged(i + 1);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              i < _rating ? Icons.star : Icons.star_border,
              size: widget.size,
              color: i < _rating ? warningColor : Colors.grey[400],
            ),
          ),
        );
      }),
    );
  }
}
