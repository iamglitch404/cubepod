abstract class AuditLogger {
  void logAction(String userId, String action, Map<String, dynamic> metadata);
}
