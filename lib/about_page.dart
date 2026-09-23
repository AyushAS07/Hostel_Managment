import 'package:flutter/material.dart';
import 'app_urls.dart';
import 'link_utils.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/images/RIT logo1.png', height: 100, fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            const Text(
              'RIT Hostels',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'For official college information, history, and departments, open the RIT website using the buttons below — the same links used on the original hostel website.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => launchExternalUrl(context, AppUrls.ritCollegeAbout),
              icon: const Icon(Icons.school_outlined),
              label: const Text('About RIT (college website)'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => launchExternalUrl(context, AppUrls.ritCollegeHome),
              icon: const Icon(Icons.language),
              label: const Text('RIT home page'),
            ),
            const SizedBox(height: 32),
            const Text(
              'In this app',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Browse hostels, facilities, mess timings, rules, and contact details from the home screen and menu — aligned with the Hostel Management website content.',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
