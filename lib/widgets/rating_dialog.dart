import 'package:flutter/material.dart';

/// A dialog for leaving a rating and review after a transaction.
///
/// Shows 5 tappable star icons and a comment text field.
/// Returns a map with `rating` (int 1-5) and `comment` (String?) on submit,
/// or null if cancelled.
class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.revieweeName,
  });

  /// The name of the user being reviewed.
  final String? revieweeName;

  /// Show the rating dialog and return the result.
  ///
  /// Returns `{rating: int, comment: String?}` or `null` if cancelled.
  static Future<Map<String, dynamic>?> show(BuildContext context,
      {String? revieweeName}) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => RatingDialog(revieweeName: revieweeName),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.revieweeName != null
            ? 'Rate ${widget.revieweeName}'
            : 'Leave a Review',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How was your experience?'),
          const SizedBox(height: 16),
          // Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return IconButton(
                icon: Icon(
                  starValue <= _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () => setState(() => _rating = starValue),
              );
            }),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 4),
            Text(
              _ratingLabel(_rating),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'Write a comment (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 500,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _rating == 0
              ? null
              : () {
                  Navigator.of(context).pop({
                    'rating': _rating,
                    'comment': _commentController.text.trim().isEmpty
                        ? null
                        : _commentController.text.trim(),
                  });
                },
          child: const Text('Submit'),
        ),
      ],
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
