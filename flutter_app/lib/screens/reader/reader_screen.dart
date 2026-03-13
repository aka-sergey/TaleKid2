import 'package:flutter/material.dart';

/// Reader screen - will be implemented in Phase 7
class ReaderScreen extends StatelessWidget {
  final String storyId;

  const ReaderScreen({super.key, required this.storyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Чтение сказки')),
      body: Center(
        child: Text(
          'Чтение сказки: $storyId\n(будет реализовано в Фазе 7)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
