import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class StudentMyRoomPage extends StatefulWidget {
  const StudentMyRoomPage({super.key});

  @override
  State<StudentMyRoomPage> createState() => _StudentMyRoomPageState();
}

class _StudentMyRoomPageState extends State<StudentMyRoomPage> {
  var _loading = true;
  String? _error;
  Map<String, dynamic> _roomPayload = const {};
  List<Map<String, dynamic>> _checkins = const [];

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
      final checkins = await ApiService.myCheckins();
      if (!mounted) return;
      setState(() {
        _roomPayload = roomPayload;
        _checkins = checkins;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = (_roomPayload['room'] as Map?) ?? const {};
    final active = (_roomPayload['activeCheckin'] as Map?) ?? const {};
    final activeRoomLabel =
        room.isEmpty ? 'Not assigned' : '${room['building'] ?? ''} ${room['roomNo'] ?? ''}'.trim();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'My room',
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
          Card(
            child: ListTile(
              leading: const Icon(Icons.meeting_room),
              title: Text(activeRoomLabel),
              subtitle: Text(active.isEmpty ? '' : 'Checked in: ${active['checkInAt']}'),
            ),
          ),
          const SizedBox(height: 16),
          const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._checkins.map((c) {
            final r = (c['room'] as Map?) ?? const {};
            final label = r.isEmpty ? (c['roomId']?.toString() ?? '') : '${r['building']} ${r['roomNo']}';
            final out = (c['checkOutAt']?.toString() ?? '').trim();
            return Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(label),
                subtitle: Text('In: ${c['checkInAt']}\nOut: ${out.isEmpty ? '—' : out}'),
                isThreeLine: true,
              ),
            );
          }),
          if (!_loading && _error == null && _checkins.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('No check-in history yet.'),
            ),
        ],
      ),
    );
  }
}

