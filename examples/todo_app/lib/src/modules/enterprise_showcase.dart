import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cubepod_enterprise/cubepod_enterprise.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';
import 'package:cubepod_state/cubepod_state.dart';

class AuditLogItem {
  final String severity;
  final String message;
  AuditLogItem(this.severity, this.message);
}

class MyAuditLogger implements AuditLogger {
  final Function(AuditLogItem) onLog;
  MyAuditLogger(this.onLog);

  @override
  void logAction(String userId, String action, Map<String, dynamic> metadata) {
    onLog(AuditLogItem(metadata['severity'] ?? 'INFO', action));
  }
}

class EnterpriseShowcasePage extends StatefulWidget {
  const EnterpriseShowcasePage({super.key});

  @override
  State<EnterpriseShowcasePage> createState() => _EnterpriseShowcasePageState();
}

class _EnterpriseShowcasePageState extends State<EnterpriseShowcasePage> {
  late final InMemoryFeatureFlagService flags;
  late final MyAuditLogger logger;
  final logs = StateSignal<List<AuditLogItem>>([]);

  Timer? _infinityTimer;
  int _currentDelayMs = 1000;
  bool _isInfinityRunning = false;

  @override
  void initState() {
    super.initState();
    flags = InMemoryFeatureFlagService();
    flags.setFlag('beta_feature', false);
    flags.setFlag('premium_ui', true);

    logger = MyAuditLogger((log) {
      logs.update((l) => [...l, log]);
    });
  }

  void _startInfinity() {
    if (_isInfinityRunning) return;
    setState(() {
      _isInfinityRunning = true;
      _currentDelayMs = 1000;
    });
    _scheduleNextInfinity();
  }

  void _scheduleNextInfinity() {
    if (!_isInfinityRunning) return;

    _infinityTimer = Timer(Duration(milliseconds: _currentDelayMs), () {
      logger.logAction(
          'system',
          'INFINITY BARRAGE! Delay: ${_currentDelayMs}ms',
          {'severity': 'CRITICAL'});

      _currentDelayMs = (_currentDelayMs / 2).floor();
      if (_currentDelayMs < 10) {
        _currentDelayMs =
            10; // Cap at 100 updates/sec to not completely freeze the app
      }

      _scheduleNextInfinity();
    });
  }

  void _stopInfinity() {
    setState(() {
      _isInfinityRunning = false;
    });
    _infinityTimer?.cancel();
    _infinityTimer = null;
  }

  @override
  void dispose() {
    _infinityTimer?.cancel();
    logs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enterprise & Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatefulBuilder(
            builder: (context, setState) {
              final isBeta = flags.isEnabled('beta_feature');
              return SwitchListTile(
                title: const Text('Beta Feature'),
                value: isBeta,
                onChanged: (val) {
                  flags.setFlag('beta_feature', val);
                  logger.logAction('user1', 'User toggled beta_feature to $val',
                      {'severity': 'INFO'});
                  setState(() {});
                },
              );
            },
          ),
          const Divider(),
          ElevatedButton(
            onPressed: () => logger.logAction('user1',
                'Simulated security breach!', {'severity': 'CRITICAL'}),
            child: const Text('Log Critical Error'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isInfinityRunning ? null : _startInfinity,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: const Text('Start Infinity Barrage',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isInfinityRunning ? _stopInfinity : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Stop Barrage',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Audit Logs:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          CubeBuilder(builder: (context, watch) {
            // Only show last 20 logs to avoid ListView lag if it gets to 10k items during barrage
            final allLogs = watch(logs);
            final displayLogs = allLogs.length > 20
                ? allLogs.sublist(allLogs.length - 20)
                : allLogs;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: displayLogs
                  .map((l) => Text('[${l.severity}] ${l.message}'))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}
