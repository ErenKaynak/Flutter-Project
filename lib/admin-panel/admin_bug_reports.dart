import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../pages/theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';

class BugReportsPage extends StatelessWidget {
  const BugReportsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : (isDark ? Colors.red.shade900 : Colors.red);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bugReports),
        backgroundColor: themeColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bug_reports')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reports = snapshot.data?.docs ?? [];

          if (reports.isEmpty) {
            return Center(child: Text(l10n.noBugReports));
          }

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index].data() as Map<String, dynamic>;
              final status = report['status'] as String;
              final createdAt = (report['createdAt'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  leading: Icon(
                    Icons.bug_report,
                    color: _getStatusColor(status, isDark),
                  ),
                  title: Text(
                    report['title'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.reportedBy}: ${report['userEmail'] ?? l10n.anonymous}',
                        style: TextStyle(fontSize: 12),
                      ),
                      if (createdAt != null)
                        Text(
                          '${l10n.reportedOn}: ${_formatDate(createdAt)}',
                          style: TextStyle(fontSize: 12),
                        ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status, isDark).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(status, l10n),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(status, isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.description,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(report['description'] ?? ''),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildStatusButton(
                                context,
                                l10n.markAsInProgress,
                                'in_progress',
                                reports[index].reference,
                                themeColor,
                              ),
                              _buildStatusButton(
                                context,
                                l10n.markAsResolved,
                                'resolved',
                                reports[index].reference,
                                themeColor,
                              ),
                              _buildStatusButton(
                                context,
                                l10n.dismiss,
                                'dismissed',
                                reports[index].reference,
                                themeColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    String label,
    String status,
    DocumentReference reference,
    Color themeColor,
  ) {
    return TextButton(
      onPressed: () async {
        try {
          await reference.update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating status: $e')),
            );
          }
        }
      },
      style: TextButton.styleFrom(
        foregroundColor: themeColor,
      ),
      child: Text(label),
    );
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return isDark ? Colors.grey : Colors.grey.shade700;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'pending':
        return l10n.pending;
      case 'in_progress':
        return l10n.inProgress;
      case 'resolved':
        return l10n.resolved;
      case 'dismissed':
        return l10n.dismissed;
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 