import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:de_vacos/core/database/db_helper.dart';
import 'package:de_vacos/services/supabase_sync_service.dart';

/// Contrato: [SupabaseSyncService.syncDailyReportsInBackground] no propaga errores
/// (try/catch global) y con [CLIENTE_ID] vacío sale antes de tocar DB/Supabase.
///
/// Se usa [DBHelper.testDbPathOverride] para que, si en debug hay `CLIENTE_ID` en
/// `.env`, la lectura de auditoría no falle por DB no abierta en el isolate de test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await DBHelper.initialize();
  });

  setUp(() async {
    final testDbPath = path_utils.join(
      Directory.current.path,
      'sync_bg_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    DBHelper.testDbPathOverride = testDbPath;
    await DBHelper.db;
  });

  tearDown(() async {
    await DBHelper.deleteTestDb();
  });

  test('syncDailyReportsInBackground completa sin lanzar (CLIENTE_ID vacío o no)', () async {
    await expectLater(
      SupabaseSyncService.syncDailyReportsInBackground(),
      completes,
    );
  });
}
