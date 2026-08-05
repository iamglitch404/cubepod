# cubepod_enterprise

Enterprise-grade primitives for CubePod — feature flags, multi-tenancy, and audit logging.

## What's inside

- **`FeatureFlags`** — toggle features per user, tenant, or environment
- **`TenantConfig`** — per-tenant configuration management
- **`AuditLogger`** — structured event logging for compliance

## Install

```yaml
dependencies:
  cubepod_enterprise: ^0.1.1
```

## Usage

```dart
import 'package:cubepod_enterprise/cubepod_enterprise.dart';

final flags = CubePod.get<FeatureFlags>();

// Check a feature flag
if (flags.isEnabled('new-dashboard')) {
  showNewDashboard();
}

// Audit log an action
final audit = CubePod.get<AuditLogger>();
audit.log(AuditEvent(
  action: 'user.password_changed',
  userId: currentUser.id,
  timestamp: DateTime.now(),
));
```

See [cubepod](https://pub.dev/packages/cubepod) for the full docs.
