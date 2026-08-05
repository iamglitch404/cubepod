import 'package:cubepod_annotation/cubepod_annotation.dart';
import 'package:cubepod_core/cubepod_core.dart';

part 'di.g.dart';

// ─── Services ────────────────────────────────────────────────────────────────

@CubeInjectable()
class DatabaseService {
  DatabaseService() {
    print('  DatabaseService created');
  }

  Future<String> query(String sql) async {
    await Future.delayed(Duration(milliseconds: 10));
    return 'result for: $sql';
  }
}

@CubeInjectable(scope: CubeScope.factory)
class ApiClient {
  final DatabaseService db;

  ApiClient(this.db) {
    print('  ApiClient created (factory — fresh instance each time)');
  }

  Future<String> get(String path) async {
    return db.query('SELECT * FROM cache WHERE path = "$path"');
  }
}

@CubeInjectable()
class AuthRepo {
  final ApiClient api;

  AuthRepo(this.api) {
    print('  AuthRepo created');
  }

  Future<String> login(String email) async {
    return api.get('/auth/login?email=$email');
  }
}

// ─── Setup ───────────────────────────────────────────────────────────────────

@cubepodInit
void setup() => $initCubePod();
