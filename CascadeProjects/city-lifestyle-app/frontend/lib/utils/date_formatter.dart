import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  final formatter = DateFormat('MMM d, y');
  return formatter.format(date);
}
