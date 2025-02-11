import 'package:flutter/widgets.dart';

class NavigationIntent extends Intent {
  final int index;
  const NavigationIntent(this.index);
}

class ExportDataIntent extends Intent {
  const ExportDataIntent();
}

class RefreshDataIntent extends Intent {
  const RefreshDataIntent();
}

class FilterDataIntent extends Intent {
  const FilterDataIntent();
}

class ClearSelectionIntent extends Intent {
  const ClearSelectionIntent();
}
