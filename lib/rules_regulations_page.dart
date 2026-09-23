import 'package:flutter/material.dart';

/// Same content as `images/RulesRegulation.html` — rules poster image.
class RulesRegulationsPage extends StatelessWidget {
  const RulesRegulationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rules & regulations'),
        backgroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hostel rules and regulations',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/Rules1.jpg', fit: BoxFit.fitWidth),
            ),
          ],
        ),
      ),
    );
  }
}
