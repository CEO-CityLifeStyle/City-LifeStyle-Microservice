import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class FirebaseTestWidget extends StatelessWidget {
  const FirebaseTestWidget({super.key});

  Future<void> _testFirebase(BuildContext context) async {
    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.logEvent(
        name: 'test_event',
        parameters: {
          'test_param': 'test_value',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase Analytics event logged successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase Analytics error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => _testFirebase(context),
        child: const Text('Test Firebase Analytics'),
      ),
    );
  }
}
