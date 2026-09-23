import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminRoomsPage extends StatefulWidget {
  const AdminRoomsPage({super.key});

  @override
  State<AdminRoomsPage> createState() => _AdminRoomsPageState();
}

class _AdminRoomsPageState extends State<AdminRoomsPage> {
  var _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rooms = const [];

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
      final rooms = await ApiService.adminListRooms();
      if (!mounted) return;
      setState(() => _rooms = rooms);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRoomDialog({Map<String, dynamic>? room}) async {
    final buildingCtrl = TextEditingController(text: room?['building']?.toString() ?? '');
    final roomNoCtrl = TextEditingController(text: room?['roomNo']?.toString() ?? '');
    final typeCtrl = TextEditingController(text: room?['type']?.toString() ?? '');
    final floorCtrl = TextEditingController(text: room?['floor']?.toString() ?? '0');
    final capCtrl = TextEditingController(text: room?['capacity']?.toString() ?? '1');
    final statusCtrl = TextEditingController(text: room?['status']?.toString() ?? 'available');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(room == null ? 'Add room' : 'Edit room'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: buildingCtrl, decoration: const InputDecoration(labelText: 'Building')),
              TextField(controller: roomNoCtrl, decoration: const InputDecoration(labelText: 'Room No')),
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type (Single/Double/Triple)')),
              TextField(
                controller: floorCtrl,
                decoration: const InputDecoration(labelText: 'Floor'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: capCtrl,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
              ),
              TextField(controller: statusCtrl, decoration: const InputDecoration(labelText: 'Status (available/full/maintenance)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      if (room == null) {
        await ApiService.adminCreateRoom(
          building: buildingCtrl.text.trim(),
          roomNo: roomNoCtrl.text.trim(),
          type: typeCtrl.text.trim(),
          floor: int.tryParse(floorCtrl.text.trim()) ?? 0,
          capacity: int.tryParse(capCtrl.text.trim()) ?? 1,
          status: statusCtrl.text.trim(),
        );
      } else {
        await ApiService.adminUpdateRoom(
          room['id']?.toString() ?? '',
          building: buildingCtrl.text.trim(),
          roomNo: roomNoCtrl.text.trim(),
          type: typeCtrl.text.trim(),
          floor: int.tryParse(floorCtrl.text.trim()) ?? 0,
          capacity: int.tryParse(capCtrl.text.trim()) ?? 1,
          status: statusCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved'), behavior: SnackBarBehavior.floating),
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Room Management',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : () => _openRoomDialog(),
                icon: const Icon(Icons.add),
                tooltip: 'Add room',
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 12),
          ..._rooms.map((r) {
            final cap = r['capacity']?.toString() ?? '1';
            final occ = r['occupiedCount']?.toString() ?? '0';
            return Card(
              child: ListTile(
                leading: const Icon(Icons.meeting_room),
                title: Text('${r['building'] ?? ''} - ${r['roomNo'] ?? ''}'),
                subtitle: Text('Type: ${r['type'] ?? ''} • Floor: ${r['floor'] ?? 0} • $occ/$cap occupied'),
                trailing: Text((r['status']?.toString() ?? 'available').toUpperCase()),
                onTap: () => _openRoomDialog(room: r),
              ),
            );
          }),
          if (!_loading && _error == null && _rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text('No rooms added yet. Tap + to add one.'),
            ),
        ],
      ),
    );
  }
}

