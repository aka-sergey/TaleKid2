import 'package:flutter/material.dart';

/// Library screen - will be implemented in Phase 7
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Библиотека')),
      body: const Center(
        child: Text(
          'Библиотека сказок\n(будет реализована в Фазе 7)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
