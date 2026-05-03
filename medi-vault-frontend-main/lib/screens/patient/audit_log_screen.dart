import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../models/audit_model.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<AuditModel> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final response = await ApiService.get(Constants.auditLogs);
    if (response['success'] == true) {
      final logs = (response['logs'] as List)
          .map((l) => AuditModel.fromJson(l))
          .toList();
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Color _actionColor(String actionType) {
    switch (actionType) {
      case 'upload': return const Color(0xFF0F6E56);
      case 'view': return const Color(0xFF185FA5);
      case 'download': return const Color(0xFF854F0B);
      case 'delete': return Colors.red;
      case 'edit': return const Color(0xFF534AB7);
      case 'permission_granted': return const Color(0xFF1D9E75);
      case 'permission_revoked': return const Color(0xFF993C1D);
      case 'login': return Colors.grey;
      case 'logout': return Colors.grey;
      default: return Colors.grey;
    }
  }

  IconData _actionIcon(String actionType) {
    switch (actionType) {
      case 'upload': return Icons.upload_file;
      case 'view': return Icons.visibility;
      case 'download': return Icons.download;
      case 'delete': return Icons.delete;
      case 'edit': return Icons.edit;
      case 'permission_granted': return Icons.lock_open;
      case 'permission_revoked': return Icons.lock;
      case 'login': return Icons.login;
      case 'logout': return Icons.logout;
      default: return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No activity yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLogs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final color = _actionColor(log.actionType);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _actionIcon(log.actionType),
                              color: color,
                            ),
                          ),
                          title: Text(
                            log.actionDisplay,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (log.recordTitle != null)
                                Text(
                                  log.recordTitle!,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              Text(
                                'By ${log.actorName} · ${log.actorRole}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${log.actionDate.day}/${log.actionDate.month}/${log.actionDate.year} at ${log.actionDate.hour.toString().padLeft(2, '0')}:${log.actionDate.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: log.actionStatus == 'success'
                                  ? const Color(0xFF0F6E56).withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log.actionStatus,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: log.actionStatus == 'success'
                                    ? const Color(0xFF0F6E56)
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}