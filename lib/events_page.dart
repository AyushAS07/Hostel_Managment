import 'package:flutter/material.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: Colors.blue[800],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildEventCard(
            context,
            'February 26, 2013',
            'Cultural Club',
            'Jagannath Hostel, Devi Hostel ..',
            'Opportunities abound to join groups that celebrate racial, ethnic, and cultural heritages of every kind.',
            'assets/images/cul.png',
          ),
          _buildEventCard(
            context,
            'March 12, 2015',
            'Political Club',
            'East Hostel, New Hostel...',
            'A political club can give you the platform to confront issues that are important to you, to support a candidate who shares your political views, or to connect with like-minded students and professors.',
            'assets/images/pol.jpg',
          ),
          _buildEventCard(
            context,
            'December 22, 2013',
            'Academic Club',
            'Lalitgiri Hostel, Devi Hostel...',
            'Academic clubs are among the most popular on campus. They are usually based on an area of study.',
            'assets/images/devi.jpg',
          ),
          _buildEventCard(
            context,
            'August 26, 2014',
            'Sports Club',
            'West Hostel, East Hostel...',
            'Campuses offers clubs and intramural activities in an enormous range of sports. Club sports are usually not regulated by the rules of the NCAA.',
            'assets/images/acc.jpg',
          ),
          _buildEventCard(
            context,
            'January 12, 2013',
            'Happiness Club',
            'Devi Hostel, Mahanadi Hostel',
            'There have been a ton of studies out there about how to be happier, and a lot of it seems to involve being with others who share your interests.',
            'assets/images/daya.jpg',
          ),
          _buildEventCard(
            context,
            'September 26, 2015',
            'Re-Enactment Club',
            'Devi Hostel, Daya Hostel...',
            'History majors (and enthusiasts) will love playing dress-up and recreating historical moments to the finest details.',
            'assets/images/girls.jpg',
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, String date, String title, String host, String desc, String imageAsset) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(imageAsset, height: 180, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(host, style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                const SizedBox(height: 10),
                Text(desc, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
