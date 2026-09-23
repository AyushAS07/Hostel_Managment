import 'package:flutter/material.dart';
import 'hostel_detail_page.dart';
import 'login_page.dart';

class HostelsPage extends StatelessWidget {
  const HostelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostels'),
        backgroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchSection(),
            _buildHostelList(context),
            _buildOffersSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Check availability', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Campus / hostel',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Boys', child: Text('Boys')),
                    DropdownMenuItem(value: 'Girls', child: Text('Girls')),
                  ],
                  onChanged: (val) {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                  items: List.generate(4, (index) => (index + 1).toString())
                      .map((y) => DropdownMenuItem(value: y, child: Text('Year $y')))
                      .toList(),
                  onChanged: (val) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
              child: const Text('Check availability', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostelList(BuildContext context) {
    final List<Map<String, Object?>> hostels = [
      {
        'name': 'Indra (New Boys Hostel)',
        'price': 'Tap for details & 3D tour',
        'image': 'assets/images/NewHostel.jpg',
        'kind': HostelDetailKind.indra,
      },
      {
        'name': 'Boys Hostel (A, B, C, D)',
        'price': 'Tap for facilities & video',
        'image': 'assets/images/Hostel View.jpg',
        'kind': HostelDetailKind.boysBlock,
      },
      {
        'name': 'Girls Hostel (Fairy)',
        'price': 'Tap for information',
        'image': 'assets/images/GirlsH1.jpg',
        'kind': HostelDetailKind.girlsFairy,
      },
      {
        'name': 'Girls Hostel (Haripriya)',
        'price': 'Tap for information',
        'image': 'assets/images/Girls_Hostel1.jpg',
        'kind': HostelDetailKind.girlsHaripriya,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: hostels.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final h = hostels[index];
          return _buildHostelCard(
            context,
            h['name']! as String,
            h['price']! as String,
            h['image']! as String,
            h['kind']! as HostelDetailKind,
          );
        },
      ),
    );
  }

  Widget _buildHostelCard(
    BuildContext context,
    String name,
    String price,
    String imagePath,
    HostelDetailKind kind,
  ) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => HostelDetailPage(kind: kind)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(price, style: TextStyle(color: Colors.blue[800], fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          const Text('Reserve a seat', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text(
            'Continue to login to complete reservation, same flow as the website “Reserve now”.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const LoginPage()),
              );
            },
            child: const Text('Go to login'),
          ),
        ],
      ),
    );
  }
}
