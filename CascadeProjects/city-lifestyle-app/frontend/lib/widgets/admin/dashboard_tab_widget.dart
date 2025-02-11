import 'package:flutter/material.dart';

class DashboardTabWidget extends StatelessWidget {
  final String title;
  final Widget content;
  final bool isLoading;

  const DashboardTabWidget({
    super.key,
    required this.title,
    required this.content,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : content,
        ),
      ],
    ),
  );
}
