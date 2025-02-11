import 'package:flutter/material.dart';
import '../../models/place.dart';

class RecommendationExplanation extends StatelessWidget {
  final Place place;
  final List<String> reasons;
  final double similarity;

  const RecommendationExplanation({
    Key? key,
    required this.place,
    required this.reasons,
    required this.similarity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline),
                const SizedBox(width: 8),
                Text(
                  'Why we recommend this place',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(reason),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              children: [
                const Text('Match Score: '),
                LinearProgressIndicator(
                  value: similarity,
                  backgroundColor: Colors.grey[200],
                  color: _getMatchColor(similarity),
                  minHeight: 8,
                ),
                const SizedBox(width: 8),
                Text(
                  '${(similarity * 100).round()}%',
                  style: TextStyle(
                    color: _getMatchColor(similarity),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getMatchColor(double similarity) {
    if (similarity >= 0.8) return Colors.green;
    if (similarity >= 0.6) return Colors.lightGreen;
    if (similarity >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
