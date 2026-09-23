import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminCheckInOutPage extends StatefulWidget {
  const AdminCheckInOutPage({super.key});

  @override
  State<AdminCheckInOutPage> createState() => _AdminCheckInOutPageState();
}

class _AdminCheckInOutPageState extends State<AdminCheckInOutPage> {
  var _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = const [];
  List<Map<String, dynamic>> _rooms = const [];
  List<Map<String, dynamic>> _checkins = const [];

  String? _selectedUserId;
  String? _selectedRoomId;

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
      final users = await ApiService.adminListUsers();
      final rooms = await ApiService.adminListRooms();
      final checkins = await ApiService.adminListCheckins();
      if (!mounted) return;
      setState(() {
        _users = users;
        _rooms = rooms;
        _checkins = checkins;
        _selectedUserId ??= users.isNotEmpty ? users.first['id']?.toString() : null;
        _selectedRoomId ??= rooms.isNotEmpty ? rooms.first['id']?.toString() : null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkIn() async {
    final userId = _selectedUserId;
    final roomId = _selectedRoomId;
    if (userId == null || roomId == null) return;
    try {
      await ApiService.adminCheckIn(userId: userId, roomId: roomId);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked in'), behavior: SnackBarBehavior.floating),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _checkOut(String checkinId) async {
    try {
      await ApiService.adminCheckOut(checkinId: checkinId);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked out'), behavior: SnackBarBehavior.floating),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _checkins.where((c) => (c['checkOutAt']?.toString() ?? '').isEmpty).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Check-in / Check-out',
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
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('New check-in', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUserId,
                    items: _users
                        .map(
                          (u) => DropdownMenuItem(
                            value: u['id']?.toString(),
                            child: Text('${u['name'] ?? ''} (${u['email'] ?? ''})'),
                          ),
                        )
                        .toList(),
                    onChanged: _loading ? null : (v) => setState(() => _selectedUserId = v),
                    decoration: const InputDecoration(labelText: 'User'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRoomId,
                    items: _rooms
                        .map((r) {
                          final cap = r['capacity']?.toString() ?? '1';
                          final occ = r['occupiedCount']?.toString() ?? '0';
                          return DropdownMenuItem(
                            value: r['id']?.toString(),
                            child: Text('${r['building']} ${r['roomNo']} ($occ/$cap)'),
                          );
                        })
                        .toList(),
                    onChanged: _loading ? null : (v) => setState(() => _selectedRoomId = v),
                    decoration: const InputDecoration(labelText: 'Room'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loading ? null : _checkIn,
                    child: const Text('Check in'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Active check-ins', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...active.map((c) {
            final id = c['id']?.toString() ?? '';
            final user = (c['user'] as Map?) ?? const {};
            final room = (c['room'] as Map?) ?? const {};
            final userLabel = '${user['name'] ?? ''} (${user['email'] ?? ''})'.trim();
            final roomLabel = '${room['building'] ?? ''} ${room['roomNo'] ?? ''}'.trim();
            return Card(
              child: ListTile(
                leading: const Icon(Icons.login),
                title: Text(userLabel.isEmpty ? 'User' : userLabel),
                subtitle: Text('Room: $roomLabel\nIn: ${c['checkInAt'] ?? ''}'),
                isThreeLine: true,
                trailing: TextButton(
                  onPressed: _loading ? null : () => _checkOut(id),
                  child: const Text('Check out'),
                ),
              ),
            );
          }),
          if (!_loading && _error == null && active.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('No active check-ins.'),
            ),
        ],
      ),
    );
  }
}

