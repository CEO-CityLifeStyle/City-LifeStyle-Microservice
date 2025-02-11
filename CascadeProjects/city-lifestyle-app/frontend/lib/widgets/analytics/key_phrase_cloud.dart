import 'package:flutter/material.dart';
import 'package:flutter_tags_x/flutter_tags_x.dart';

class KeyPhraseCloud extends StatelessWidget {
  final List<dynamic> phrases;

  const KeyPhraseCloud({Key? key, required this.phrases}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tags(
      itemCount: phrases.length,
      itemBuilder: (index) {
        final phrase = phrases[index];
        final score = (phrase['score'] as num).toDouble();
        final fontSize = _calculateFontSize(score);
        final color = _calculateColor(score);

        return ItemTags(
          index: index,
          title: phrase['text'],
          textStyle: TextStyle(
            fontSize: fontSize,
            color: Colors.white,
          ),
          color: color,
          activeColor: color,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          elevation: 2,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          combine: ItemTagsCombine.withTextBefore,
        );
      },
      columns: 3,
      symmetry: false,
      horizontalScroll: false,
      verticalDirection: VerticalDirection.down,
      runSpacing: 8,
    );
  }

  double _calculateFontSize(double score) {
    // Scale font size based on score (importance)
    // Score is typically between 0 and 1
    const double minFontSize = 12;
    const double maxFontSize = 24;
    return minFontSize + (maxFontSize - minFontSize) * score;
  }

  Color _calculateColor(double score) {
    if (score >= 0.8) {
      return Colors.green;
    } else if (score >= 0.6) {
      return Colors.lightGreen;
    } else if (score >= 0.4) {
      return Colors.blue;
    } else if (score >= 0.2) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
