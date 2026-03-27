---
name: flutter-sqlite-migrations
description: Centralized SQLite migration patterns for Flutter/Dart, providing helper methods for DDL operations (PRAGMA, ALTER TABLE) and eliminating code duplication across repositories.
origin: ECC
---

# Flutter SQLite Migrations

Guidelines for centralizing SQLite migration logic in Flutter/Dart applications, following DRY and SOLID principles. This skill complements `flutter-clean-solid-dry` (principles) and `flutter-working-with-databases` (architecture) by providing concrete patterns for DDL operations.

## 1. DDL Helper Methods

### 1.1 columnExists
Check if a column exists in a table using PRAGMA table_info.

```dart
Future<bool> columnExists(Database db, String tableName, String columnName) async {
  final tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
  final columnNames = tableInfo.map((row) => row['name'] as String).toList();
  return columnNames.contains(columnName);
}
```

### 1.2 addColumnIfNotExists
Add a column to a table if it doesn't exist, with optional default value and update statement.

```dart
Future<void> addColumnIfNotExists(
  Database db,
  String tableName,
  String columnName,
  String columnDefinition, {
  String? defaultValue,
  String? updateSql,
}) async {
  if (!await columnExists(db, tableName, columnName)) {
    await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition');
    if (defaultValue != null) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition DEFAULT $defaultValue');
    }
    if (updateSql != null) {
      await db.execute(updateSql);
    }
  }
}
```

## 2. Centralized Migration Pattern

### 2.1 Move DDL Logic to DBHelper
Instead of duplicating PRAGMA/ALTER TABLE in repositories, centralize in DBHelper.

**Before (duplicated in repositories):**
```dart
// In caja_repository.dart
final tableInfo = await db.rawQuery('PRAGMA table_info(caja_movimientos)');
final columnNames = tableInfo.map((row) => row['name'] as String).toList();
if (!columnNames.contains('isSystemGenerated')) {
  await db.execute('ALTER TABLE caja_movimientos ADD COLUMN isSystemGenerated INTEGER DEFAULT 0');
}
```

**After (centralized in DBHelper):**
```dart
// In db_helper.dart
Future<void> _ensureColumnExists(Database db, String tableName, String columnName, String columnDefinition) async {
  if (!await columnExists(db, tableName, columnName)) {
    await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition');
  }
}

// Usage in repositories
await di.dbHelper.ensureColumnExists(db, 'caja_movimientos', 'isSystemGenerated', 'INTEGER DEFAULT 0');
```

### 2.2 Refactor Existing Code
Identify all duplicated PRAGMA/ALTER patterns in:
- `lib/core/database/db_helper.dart` (lines 74, 94, 113, 234, 247, 262, 281, 469)
- `lib/repositories/caja_repository.dart` (lines 84, 118, 177)
- `lib/repositories/pedido_repository.dart` (line 134)

Replace with helper methods.

## 3. Security Considerations (OWASP)

### 3.1 Prevent SQL Injection
- Use `whereArgs` for dynamic values.
- Validate table and column names against a whitelist.
- Avoid string interpolation for user input.

### 3.2 Error Handling
```dart
try {
  await addColumnIfNotExists(db, tableName, columnName, columnDefinition);
} catch (e) {
  debugPrint('Migration error: $e');
  // Handle gracefully, don't crash app
}
```

### 3.3 Logging
- Use `debugPrint` instead of `print`.
- Log migration steps for debugging.

## 4. Migration Workflow

### 4.1 Adding New Columns
1. Create a helper method in DBHelper.
2. Call it during database open or upgrade.
3. Test with existing data.

### 4.2 Backwards Compatibility
- Add columns with DEFAULT values.
- Update existing records if needed.
- Never drop columns in production.

## 5. Integration with Existing Skills

- **flutter-clean-solid-dry**: Apply DRY principle to eliminate duplication, SOLID for separation of responsibilities.
- **flutter-working-with-databases**: Use repository pattern, but keep DDL logic in DBHelper.
- **flutter-dart-code-review**: Follow code review checklist for quality.

## 6. Checklist for New Migrations

- [ ] Is DDL logic centralized in DBHelper?
- [ ] Are helper methods used?
- [ ] Is SQL injection prevented?
- [ ] Are errors handled gracefully?
- [ ] Is backwards compatibility maintained?
- [ ] Are migrations logged?

## 7. Example Refactoring

See `lib/core/database/db_helper.dart` for current duplicated code. Apply patterns from this skill to refactor.

---

**Sources:**
- SQLite PRAGMA table_info: https://www.sqlite.org/pragma.html#pragma_table_info
- SQLite ALTER TABLE: https://www.sqlite.org/lang_altertable.html
- OWASP SQL Injection Prevention: https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html
