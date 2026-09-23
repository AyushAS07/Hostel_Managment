import 'package:flutter/material.dart';

/// Content summarised from `MessFacility.html` in the website project.
class MessFacilityPage extends StatelessWidget {
  const MessFacilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess facility'),
        backgroundColor: Colors.blue[800],
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Image.asset('assets/images/hero_3.jpg', fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our mess services',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We provide hygienic and nutritious meals to ensure the well-being of our students.',
                ),
                const SizedBox(height: 20),
                _card(
                  context,
                  title: 'Meal timings',
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Breakfast: 7:30 AM – 9:00 AM'),
                      Text('Lunch: 12:30 PM – 2:00 PM'),
                      Text('Dinner: 7:30 PM – 9:00 PM'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/food-1.jpg', fit: BoxFit.cover),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
