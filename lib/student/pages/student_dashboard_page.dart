import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  var _loading = true;
  String? _error;
  Map<String, dynamic> _roomPayload = const {};
  List<Map<String, dynamic>> _complaints = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roomPayload = await ApiService.myRoom();
      final complaints = await ApiService.myComplaints();
      if (!mounted) return;
      setState(() {
        _roomPayload = roomPayload;
        _complaints = complaints;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _card(String title, Object? value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value?.toString() ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = (_roomPayload['room'] as Map?) ?? const {};
    final active = (_roomPayload['activeCheckin'] as Map?) ?? const {};
    final openCount = _complaints.where((c) {
      final s = (c['status']?.toString() ?? 'open').toLowerCase();
      return s != 'resolved' && s != 'closed';
    }).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 12),
          _card('Open complaints', openCount, Icons.report),
          _card(
            'Current room',
            room.isEmpty ? 'Not assigned' : '${room['building'] ?? ''} ${room['roomNo'] ?? ''}',
            Icons.meeting_room,
          ),
          _card('Checked in at', active['checkInAt'] ?? (room.isEmpty ? '' : '—'), Icons.login),
        ],
      ),
    );
  }
}

