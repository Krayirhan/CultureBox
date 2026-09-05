import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'dart:io';

part 'local_database.g.dart';

class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ownerUid => text().withDefault(const Constant(''))();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  TextColumn get title => text()();
  TextColumn get kind => text()();
  TextColumn get meta => text().withDefault(const Constant(''))();
  TextColumn get dateLabel => text().withDefault(const Constant(''))();
  TextColumn get imageUrl => text().withDefault(const Constant(''))();
  RealColumn get progress => real().withDefault(const Constant(0))();
  TextColumn get progressLabel => text().withDefault(const Constant(''))();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class OutboxOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ownerUid => text().withDefault(const Constant(''))();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class AppPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Items, OutboxOperations, AppPreferences])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase(super.e);
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(items, items.ownerUid);
        await m.addColumn(items, items.metadataJson);
        await m.addColumn(outboxOperations, outboxOperations.ownerUid);
      }
    },
  );

  Future<List<Item>> allItems({String ownerUid = ''}) =>
      (select(items)..where((t) => t.ownerUid.equals(ownerUid))).get();
  Future<int> insertItem(ItemsCompanion item) => into(items).insert(item);
  Future<bool> updateItem(ItemsCompanion item) => update(items).replace(item);
  Future<int> deleteItem(int id) =>
      (delete(items)..where((t) => t.id.equals(id))).go();
  Future<int> enqueue(
    String operation,
    String payload, {
    String ownerUid = '',
  }) => into(outboxOperations).insert(
    OutboxOperationsCompanion.insert(
      operation: operation,
      payload: payload,
      ownerUid: Value(ownerUid),
    ),
  );
  Future<List<OutboxOperation>> pendingOperations({String ownerUid = ''}) =>
      (select(outboxOperations)
            ..where((t) => t.ownerUid.equals(ownerUid))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();
  Future<int> removeOperation(int id) =>
      (delete(outboxOperations)..where((t) => t.id.equals(id))).go();
  Future<void> clearOutbox({String ownerUid = ''}) => (delete(
    outboxOperations,
  )..where((t) => t.ownerUid.equals(ownerUid))).go();

  Future<void> clearItems({String ownerUid = ''}) =>
      (delete(items)..where((t) => t.ownerUid.equals(ownerUid))).go();

  Future<String?> preference(String key) async => (await (select(
    appPreferences,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setPreference(String key, String value) => into(appPreferences)
      .insertOnConflictUpdate(
        AppPreferencesCompanion.insert(key: key, value: value),
      );
}

LazyDatabase openLocalDatabase() => LazyDatabase(() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'culturebox.sqlite'));
    return NativeDatabase.createInBackground(file);
  } on Object {
    // Flutter unit tests do not register path_provider; use an isolated DB.
    return NativeDatabase.memory();
  }
});
