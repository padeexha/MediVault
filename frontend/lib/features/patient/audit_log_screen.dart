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
        _logs      = logs;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Color _actionColor(String type) {
    switch (type) {
      case 'upload':             return const Color(0xFF1D9E75);
      case 'view':               return const Color(0xFF185FA5);
      case 'download':           return const Color(0xFF854F0B);
      case 'delete':             return Colors.redAccent;
      case 'edit':               return const Color(0xFF534AB7);
      case 'permission_granted': return AppColors.ecgGreen;
      case 'permission_revoked': return const Color(0xFF993C1D);
      case 'login':              return AppColors.accentBlue;
      case 'logout':             return AppColors.textSecondary;
      default:                   return AppColors.textSecondary;
    }
  }

  IconData _actionIcon(String type) {
    switch (type) {
      case 'upload':             return Icons.upload_file;
      case 'view':               return Icons.visibility;
      case 'download':           return Icons.download;
      case 'delete':             return Icons.delete;
      case 'edit':               return Icons.edit;
      case 'permission_granted': return Icons.lock_open;
      case 'permission_revoked': return Icons.lock;
      case 'login':              return Icons.login;
      case 'logout':             return Icons.logout;
      default:                   return Icons.info;
    }
  }

  /// Groups logs by calendar date (today, yesterday, or formatted date)
  Map<String, List<AuditModel>> _groupByDate(List<AuditModel> logs) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final grouped = <String, List<AuditModel>>{};

    for (final log in logs) {
      final logDate = DateTime(
          log.actionDate.year, log.actionDate.month, log.actionDate.day);
      late String label;
      if (logDate == today) {
        label = 'Today';
      } else if (logDate == yesterday) {
        label = 'Yesterday';
      } else {
        final months = [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        label =
            '${log.actionDate.day} ${months[log.actionDate.month]} ${log.actionDate.year}';
      }
      grouped.putIfAbsent(label, () => []).add(log);
    }
    return grouped;
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
              ? _emptyState()
              : RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: _loadLogs,
                  child: _buildTimeline(),
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history,
                size: 72, color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 20),
            const Text('No Activity Yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Actions like uploads, views, downloads, and access changes will appear here.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final grouped = _groupByDate(_logs);
    final entries = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: entries.length,
      itemBuilder: (_, gi) {
        final dateLabel = entries[gi].key;
        final dayLogs   = entries[gi].value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.accentBlue
                              .withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      dateLabel,
                      style: const TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ],
              ),
            ),
            // Timeline entries for this date
            ...dayLogs.asMap().entries.map((e) {
              final isLast = e.key == dayLogs.length - 1;
              return _timelineItem(e.value, isLast: isLast);
            }),
          ],
        );
      },
    );
  }

  Widget _timelineItem(AuditModel log, {required bool isLast}) {
    final color  = _actionColor(log.actionType);
    final isDoctor = log.actorRole == 'doctor';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: color.withValues(alpha: 0.45), width: 1.5),
                  ),
                  child: Icon(_actionIcon(log.actionType),
                      color: color, size: 13),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.only(top: 4),
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.actionDisplay,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: log.actionStatus == 'success'
                                ? AppColors.ecgGreen
                                    .withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            log.actionStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: log.actionStatus == 'success'
                                  ? AppColors.ecgGreen
                                  : Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (log.recordTitle != null) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.insert_drive_file_outlined,
                              size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              log.recordTitle!,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          isDoctor
                              ? Icons.medical_services_outlined
                              : Icons.person_outline,
                          size: 11,
                          color: isDoctor
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${log.actorName} · ${log.actorRole}',
                          style: TextStyle(
                              color: isDoctor
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                              fontSize: 11),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(log.actionDate),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
