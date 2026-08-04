class TenantConfig {
  final String tenantId;
  final String databaseUrl;
  final Map<String, dynamic> theme;
  final Map<String, dynamic> settings;

  const TenantConfig({
    required this.tenantId,
    required this.databaseUrl,
    this.theme = const {},
    this.settings = const {},
  });
}
