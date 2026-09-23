import 'package:flutter/material.dart';
import 'app_urls.dart';
import 'link_utils.dart';

enum HostelDetailKind { indra, boysBlock, girlsFairy, girlsHaripriya }

class HostelDetailPage extends StatelessWidget {
  const HostelDetailPage({super.key, required this.kind});

  final HostelDetailKind kind;

  String get _title {
    switch (kind) {
      case HostelDetailKind.indra:
        return 'Indra (New Boys Hostel)';
      case HostelDetailKind.boysBlock:
        return 'Boys Hostel (A, B, C, D)';
      case HostelDetailKind.girlsFairy:
        return 'Girls Hostel (Fairy)';
      case HostelDetailKind.girlsHaripriya:
        return 'Girls Hostel (Haripriya)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.blue[800],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(_heroAsset, height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Text(_heading, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._bodyWidgets(context),
        ],
      ),
    );
  }

  String get _heroAsset {
    switch (kind) {
      case HostelDetailKind.indra:
        return 'assets/images/NewHostel.jpg';
      case HostelDetailKind.boysBlock:
        return 'assets/images/Hostel View.jpg';
      case HostelDetailKind.girlsFairy:
        return 'assets/images/GirlsH1.jpg';
      case HostelDetailKind.girlsHaripriya:
        return 'assets/images/Girls_Hostel1.jpg';
    }
  }

  String get _heading {
    switch (kind) {
      case HostelDetailKind.indra:
        return 'Hostel information';
      case HostelDetailKind.boysBlock:
        return 'Campus & facilities';
      case HostelDetailKind.girlsFairy:
        return 'Girls Hostel (Fairy)';
      case HostelDetailKind.girlsHaripriya:
        return 'Girls Hostel (Haripriya)';
    }
  }

  List<Widget> _bodyWidgets(BuildContext context) {
    switch (kind) {
      case HostelDetailKind.indra:
        return [
          const Text(
            'Indra Hostel provides comfortable accommodation for students with modern amenities and facilities. '
            'The hostel is equipped with all necessary services to ensure a pleasant stay for the students.',
          ),
          const SizedBox(height: 12),
          ..._bulletList(const [
            'Free WiFi access',
            '24/7 security',
            'Modern mess facility',
            'Laundry services',
            'Study room',
            'Recreation room',
          ]),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => launchExternalUrl(context, AppUrls.indraHostelYoutube),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Watch 3D view (YouTube)'),
          ),
        ];
      case HostelDetailKind.boysBlock:
        return [
          const Text('Basic facilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._bulletList(const [
            'Free WiFi access',
            '24/7 security',
            'CCTV surveillance',
            'Power backup',
          ]),
          const SizedBox(height: 16),
          const Text('Room amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._bulletList(const [
            'Single / double occupancy',
            'Attached bathroom',
            'Study table & chair',
            'Wardrobe & storage',
          ]),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => launchExternalUrl(context, AppUrls.boysHostelCampusYoutube),
            icon: const Icon(Icons.video_library_outlined),
            label: const Text('Watch campus view (YouTube)'),
          ),
        ];
      case HostelDetailKind.girlsFairy:
        return [
          const Text('Basic facilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._bulletList(const [
            'Free WiFi access',
            '24/7 security',
            'CCTV surveillance',
            'Power backup',
            'Common study room',
          ]),
          const SizedBox(height: 16),
          const Text('Room amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._bulletList(const [
            'Triple occupancy rooms',
            'Attached bathroom',
            'Study table & chair',
            'Wardrobe & storage',
            'Reading lamp',
          ]),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/images/GirlsH1.jpg', fit: BoxFit.cover),
          ),
        ];
      case HostelDetailKind.girlsHaripriya:
        return [
          const Text('Basic facilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._bulletList(const [
            'Free WiFi access',
            '24/7 security',
            'CCTV surveillance',
            'Power backup',
            'Common recreation room',
          ]),
          const SizedBox(height: 16),
          const Text('Room amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._bulletList(const [
            'Double occupancy rooms',
            'Attached bathroom',
            'Study table & chair',
            'Wardrobe & storage',
            'Reading lamp',
          ]),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/images/Girls_Hostel1.jpg', fit: BoxFit.cover),
          ),
        ];
    }
  }

  List<Widget> _bulletList(List<String> items) {
    return items
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✓ '),
                Expanded(child: Text(e)),
              ],
            ),
          ),
        )
        .toList();
  }
}
