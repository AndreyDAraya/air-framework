import 'package:flutter/material.dart';
import '../widgets/shared_widgets.dart';
import '../module_logger.dart';

class LogsTab extends StatefulWidget {
  const LogsTab({super.key});

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    ModuleLogger().addListener(_onLogsUpdated);
  }

  @override
  void dispose() {
    ModuleLogger().removeListener(_onLogsUpdated);
    _searchController.dispose();
    super.dispose();
  }

  void _onLogsUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final allLogs = ModuleLogger().logs;
    final logs = allLogs
        .where(
          (l) =>
              l.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              l.moduleId.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Column(
      children: [
        buildSearchBar(
          controller: _searchController,
          hint: 'Search logs...',
          onChanged: (v) => setState(() => _searchQuery = v),
          onClear: () => setState(() {
            _searchController.clear();
            _searchQuery = '';
          }),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                'LOG STREAM',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => ModuleLogger().clear()),
                child: const Text(
                  'CLEAR',
                  style: TextStyle(color: Colors.redAccent, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: logs.isEmpty
              ? emptyState(Icons.list_alt, 'No matching logs')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[logs.length - 1 - index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getLogLevelColor(
                          log.level,
                        ).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getLogLevelColor(
                            log.level,
                          ).withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                log.emoji,
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '[${log.moduleId}]',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                formatTime(log.timestamp),
                                style: const TextStyle(
                                  color: Colors.white24,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                          if (log.data != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Data: ${log.data}',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _getLogLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }
}
