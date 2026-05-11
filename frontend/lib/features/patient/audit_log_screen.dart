import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/audit_model.dart';

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

  Color _actionColor(String type) {
    switch (type) {
      case 'upload': return const Color(0xFF1D9E75);
      case 'view': return const Color(0xFF185FA5);
      case 'download': return const Color(0xFF854F0B);
      case 'delete': return Colors.redAccent;
      case 'edit': return const Color(0xFF534AB7);
      case 'permission_granted': return AppColors.accent;
      case 'permission_revoked': return const Color(0xFF993C1D);
      default: return AppColors.textSecondary;
    }
  }

  IconData _actionIcon(String type) {
    switch (type) {
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
      backgroundColor: AppColors.bg,
      appBar: darkGlassAppBar(title: 'Audit Log'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      const Text('No activity yet',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: _loadLogs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (_, i) {
                      final log = _logs[i];
                      final color = _actionColor(log.actionType);
                      return DarkListCard(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_actionIcon(log.actionType),
                                color: color),
                          ),
                          title: Text(
                            log.actionDisplay,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (log.recordTitle != null)
                                Text(log.recordTitle!,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              Text(
                                'By ${log.actorName} · ${log.actorRole}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${log.actionDate.day}/${log.actionDate.month}/${log.actionDate.year} at ${log.actionDate.hour.toString().padLeft(2, '0')}:${log.actionDate.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: log.actionStatus == 'success'
                                  ? AppColors.accent.withValues(alpha: 0.15)
                                  : Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log.actionStatus,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: log.actionStatus == 'success'
                                    ? AppColors.accent
                                    : Colors.redAccent,
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
