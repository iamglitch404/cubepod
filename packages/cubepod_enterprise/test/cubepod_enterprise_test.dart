import 'package:cubepod_enterprise/cubepod_enterprise.dart';
import 'package:test/test.dart';

class _TestAuditLogger implements AuditLogger {
  final List<Map<String, dynamic>> logs = [];

  @override
  void logAction(String userId, String action, Map<String, dynamic> metadata) {
    logs.add({'userId': userId, 'action': action, 'metadata': metadata});
  }
}

void main() {
  group('TenantConfig', () {
    test('stores tenantId and settings', () {
      const config = TenantConfig(
        tenantId: 'acme',
        databaseUrl: 'https://acme.example.com/db',
        settings: {'darkMode': true},
      );
      expect(config.tenantId, 'acme');
      expect(config.settings['darkMode'], true);
    });
  });

  group('InMemoryFeatureFlagService', () {
    test('returns defaultValue when flag not set', () {
      final service = InMemoryFeatureFlagService();
      expect(service.isEnabled('new_ui'), isFalse);
      expect(service.isEnabled('new_ui', defaultValue: true), isTrue);
    });

    test('returns true when flag is explicitly enabled', () {
      final service = InMemoryFeatureFlagService();
      service.setFlag('dark_mode', true);
      expect(service.isEnabled('dark_mode'), isTrue);
    });

    test('returns false when flag is explicitly disabled', () {
      final service = InMemoryFeatureFlagService();
      service.setFlag('beta_feature', false);
      expect(service.isEnabled('beta_feature'), isFalse);
    });

    test('fetchFlags() completes without error', () async {
      final service = InMemoryFeatureFlagService();
      await expectLater(service.fetchFlags(), completes);
    });
  });

  group('AuditLogger', () {
    test('logAction records actions correctly', () {
      final logger = _TestAuditLogger();
      logger.logAction('user-1', 'LOGIN', {'ip': '127.0.0.1'});
      expect(logger.logs.length, 1);
      expect(logger.logs.first['userId'], 'user-1');
      expect(logger.logs.first['action'], 'LOGIN');
    });
  });
}
