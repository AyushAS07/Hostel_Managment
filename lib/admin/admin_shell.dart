import 'package:flutter/material.dart';

import '../home_page.dart';
import '../services/session_service.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_students_page.dart';
import 'pages/admin_rooms_page.dart';
import 'pages/admin_complaints_page.dart';
import 'pages/admin_checkinout_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final destinations = const <NavigationRailDestination>[
      NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: Text('Students'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.meeting_room_outlined),
        selectedIcon: Icon(Icons.meeting_room),
        label: Text('Rooms'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.report_outlined),
        selectedIcon: Icon(Icons.report),
        label: Text('Complaints'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.login_outlined),
        selectedIcon: Icon(Icons.login),
        label: Text('Check-in/out'),
      ),
    ];

    final pages = const <Widget>[
      AdminDashboardPage(),
      AdminStudentsPage(),
      AdminRoomsPage(),
      AdminComplaintsPage(),
      AdminCheckInOutPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (v) => setState(() => _index = v),
            labelType: NavigationRailLabelType.all,
            destinations: destinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[_index]),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await SessionService.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
      (route) => false,
    );
  }
}

