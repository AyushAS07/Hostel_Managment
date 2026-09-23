import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminComplaintsPage extends StatefulWidget {
  const AdminComplaintsPage({super.key});

  @override
  State<AdminComplaintsPage> createState() => _AdminComplaintsPageState();
}

class _AdminComplaintsPageState extends State<AdminComplaintsPage> {
  var _loading = true;
  String? _error;
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
      final complaints = await ApiService.adminListComplaints();
      if (!mounted) return;
      setState(() => _complaints = complaints);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await ApiService.adminUpdateComplaintStatus(id, status);
      if (!mounted) return;
      await _load();
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
                  'Complaints',
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
          ..._complaints.map((c) {
            final id = c['id']?.toString() ?? '';
            final title = c['title']?.toString() ?? '';
            final status = (c['status']?.toString() ?? 'open').toLowerCase();
            final user = (c['user'] as Map?) ?? const {};
            final who = '${user['name'] ?? ''} (${user['email'] ?? ''})'.trim();
            return Card(
              child: ListTile(
                leading: const Icon(Icons.report),
                title: Text(title),
                subtitle: Text(
                  [
                    if (who.isNotEmpty) who,
                    c['description']?.toString() ?? '',
                  ].where((s) => s.trim().isNotEmpty).join('\n'),
                ),
                isThreeLine: true,
                trailing: DropdownButton<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'open', child: Text('OPEN')),
                    DropdownMenuItem(value: 'in_progress', child: Text('IN PROGRESS')),
                    DropdownMenuItem(value: 'resolved', child: Text('RESOLVED')),
                    DropdownMenuItem(value: 'closed', child: Text('CLOSED')),
                  ],
                  onChanged: _loading ? null : (v) => v == null ? null : _setStatus(id, v),
                ),
              ),
            );
          }),
          if (!_loading && _error == null && _complaints.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text('No complaints yet.'),
            ),
        ],
      ),
    );
  }
}

