import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class StudentComplaintsPage extends StatefulWidget {
  const StudentComplaintsPage({super.key});

  @override
  State<StudentComplaintsPage> createState() => _StudentComplaintsPageState();
}

class _StudentComplaintsPageState extends State<StudentComplaintsPage> {
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
      final complaints = await ApiService.myComplaints();
      if (!mounted) return;
      setState(() => _complaints = complaints);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
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
                  'My complaints',
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
            final status = (c['status']?.toString() ?? 'open').toUpperCase();
            return Card(
              child: ListTile(
                leading: const Icon(Icons.report),
                title: Text(c['title']?.toString() ?? ''),
                subtitle: Text('${c['description'] ?? ''}\nStatus: $status'),
                isThreeLine: true,
              ),
            );
          }),
          if (!_loading && _error == null && _complaints.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('No complaints yet.'),
            ),
        ],
      ),
    );
  }
}

