import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'about_page.dart';
import 'admission_page.dart';
import 'contact_page.dart';
import 'hostel_detail_page.dart';
import 'image_preview_page.dart';
import 'link_utils.dart';
import 'login_page.dart';
import 'registration_page.dart';
import 'hostels_page.dart';
import 'events_page.dart';
import 'mess_facility_page.dart';
import 'rules_regulations_page.dart';
import 'navigation_observer.dart';
import 'services/session_service.dart';
import 'admin/admin_shell.dart';
import 'student/student_shell.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final user = await SessionService.getCurrentUser();
    if (!mounted) return;
    setState(() => _currentUser = user);
  }

  Future<void> _openLogin() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const LoginPage()),
    );
    await _loadSession();
  }

  Future<void> _openRegister() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const RegistrationPage()),
    );
    await _loadSession();
  }

  Future<void> _logout() async {
    await SessionService.clear();
    if (!mounted) return;
    setState(() => _currentUser = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.2),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset('assets/images/RIT logo1.png', fit: BoxFit.contain),
        ),
        title: Text(
          'RIT HOSTEL',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_currentUser != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  _currentUser?['name']?.toString() ?? 'Logged in',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue[800]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'RIT HOSTEL',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (_currentUser != null) ...[
                    Text(
                      _currentUser?['name']?.toString() ?? 'Account',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _currentUser?['email']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    const Text('Menu', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ],
              ),
            ),
            _buildDrawerItem(context, Icons.home, 'Home', null),
            _buildDrawerItem(context, Icons.hotel, 'Hostels', const HostelsPage()),
            _buildDrawerItem(context, Icons.info, 'About', const AboutPage()),
            _buildDrawerItem(context, Icons.assignment, 'Admission', const AdmissionPage()),
            _buildDrawerItem(context, Icons.fact_check_outlined, 'Rules & regulations', const RulesRegulationsPage()),
            _buildDrawerItem(context, Icons.contact_mail, 'Contact', const ContactPage()),
            _buildDrawerItem(context, Icons.event, 'Events', const EventsPage()),
            if (_currentUser == null) ...[
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Login'),
                onTap: () async {
                  Navigator.pop(context);
                  await _openLogin();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Register'),
                onTap: () async {
                  Navigator.pop(context);
                  await _openRegister();
                },
              ),
            ] else ...[
              if ((_currentUser?['role']?.toString() ?? '') != 'admin')
                ListTile(
                  leading: const Icon(Icons.school),
                  title: const Text('Student'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(builder: (_) => const StudentShell()),
                    );
                    await _loadSession();
                  },
                ),
              if ((_currentUser?['role']?.toString() ?? '') == 'admin')
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Admin'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(builder: (_) => const AdminShell()),
                    );
                    await _loadSession();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context);
                  await _logout();
                },
              ),
            ],
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildHostelsSection(context),
            _buildFacilitiesSection(context),
            _buildPhotosSection(context),
            _buildMessBanner(context),
            _buildReserveBanner(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Widget? page) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        }
      },
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      height: 640,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Hostel_Mangement1.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'WELCOME TO RIT HOSTELS',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'A Best Place for Students',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            if (_currentUser == null)
              ElevatedButton(
                onPressed: _openLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  'Reserve Now',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            else ...[
              Text(
                'You are logged in as ${_currentUser?['name'] ?? 'a user'}.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final role = _currentUser?['role']?.toString() ?? 'student';
                  if (role == 'admin') {
                    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AdminShell()));
                  } else {
                    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const StudentShell()));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  _currentUser?['role']?.toString() == 'admin'
                      ? 'Go to admin panel'
                      : 'View student dashboard',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHostelsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/sliderjj.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Hostels',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'A hostel is a shelter for the students who come from far off places. Students live there with each other and learn the value of discipline and co-operation.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          const SizedBox(height: 30),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 0.8,
            children: [
              _buildHostelCard(context, 'Indra (New Boys Hostel)', 'assets/images/NewHostel.jpg', HostelDetailKind.indra),
              _buildHostelCard(context, 'Boys Hostel (A,B,C,D)', 'assets/images/Hostel View.jpg', HostelDetailKind.boysBlock),
              _buildHostelCard(context, 'Girls Hostel (Fairy)', 'assets/images/GirlsH1.jpg', HostelDetailKind.girlsFairy),
              _buildHostelCard(context, 'Girls Hostel (Haripriya)', 'assets/images/Girls_Hostel1.jpg', HostelDetailKind.girlsHaripriya),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHostelCard(BuildContext context, String name, String imagePath, HostelDetailKind kind) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => HostelDetailPage(kind: kind)),
          );
        },
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitiesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/BGF.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Our Facilities',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildFacilityItem(
            context,
            'assets/images/facilities/Medical.jpg',
            'Medical facility',
            '8PM–10PM (Mon–Sat), 24/7 emergency',
            onTap: () => _showMedicalInfo(context),
          ),
          _buildFacilityItem(
            context,
            'assets/images/facilities/mess.jpg',
            'Mess facility',
            'Hygienic and nutritious meals served three times a day',
            onTap: () {
              Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MessFacilityPage()));
            },
          ),
          _buildFacilityItem(
            context,
            'assets/images/facilities/laundry.jpg',
            'Laundry facility',
            'Modern washing machines and dryers',
            onTap: () => _showSimpleInfoDialog(
              context,
              title: 'Laundry facility',
              body: 'Modern washing machines and dryers are available for students’ convenience.',
            ),
          ),
          _buildFacilityItem(
            context,
            'assets/images/facilities/wifi.jpg',
            'Free WiFi',
            'High-speed internet connectivity 24/7',
            onTap: () => _showSimpleInfoDialog(
              context,
              title: 'Free WiFi',
              body: 'High-speed internet connectivity is available 24/7 throughout the hostel premises.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityItem(
    BuildContext context,
    String imagePath,
    String title,
    String desc, {
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(imagePath, width: 56, height: 56, fit: BoxFit.cover),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  void _showMedicalInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Medical facility'),
        content: const SingleChildScrollView(
          child: Text(
            'Timings: 8PM–10PM (Mon–Sat)\n'
            'Emergency: 24/7\n'
            'Services: first aid, health check-ups',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showSimpleInfoDialog(BuildContext context, {required String title, required String body}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(BuildContext context) {
    final photos = [
      'assets/images/H1.jpg',
      'assets/images/H17.jpg',
      'assets/images/H16.jpg',
      'assets/images/H20.jpg',
      'assets/images/H2.jpg',
      'assets/images/H6.jpg',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Text(
            'Photos',
            style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 250,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) {
                final path = photos[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => ImagePreviewPage(assetPath: path)),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      path,
                      width: 190,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: photos.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessBanner(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MessFacilityPage()));
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/hero_3.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: Colors.black45,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Our Hostel Mess',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mess of all hostels provides better quality of food. The sanitation are all in hygienic condition and provide health quality foods.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap for mess details',
                  style: GoogleFonts.roboto(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReserveBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/sliderjj.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const SizedBox(
            width: 260,
            child: Text(
              'A Best Place To Stay.\nReserve Now!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: _currentUser != null ? null : _openLogin,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reserve Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      color: Colors.blueGrey[900],
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const Text('Contact Info', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Address: RIT College, Islampur 415409', style: TextStyle(color: Colors.white70))),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => launchPhone(context, '+919937159477'),
            child: const Row(
              children: [
                Icon(Icons.phone, color: Colors.blue, size: 20),
                SizedBox(width: 10),
                Text('Phone: (+91) 993 715 9477', style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => launchEmail(context, 'ritindia.edu@gmail.com'),
            child: const Row(
              children: [
                Icon(Icons.email, color: Colors.blue, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Email: ritindia.edu@gmail.com',
                    style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          const Text('Copyright © All rights reserved', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const Text('Made by Hacko Army', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
