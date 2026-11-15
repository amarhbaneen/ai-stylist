import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'database/app_database.dart';
import 'storage/file_store.dart';

part 'providers.g.dart';

/// App-private storage root, resolved once in bootstrap and injected with
/// `appSupportDirectoryProvider.overrideWithValue(...)`.
@Riverpod(keepAlive: true)
Directory appSupportDirectory(Ref ref) => throw UnimplementedError(
  'appSupportDirectoryProvider must be overridden in bootstrap or tests',
);

/// The database, created in bootstrap (or in-memory in tests) and injected.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) => throw UnimplementedError(
  'appDatabaseProvider must be overridden in bootstrap or tests',
);

@Riverpod(keepAlive: true)
FileStore fileStore(Ref ref) {
  final root = ref.watch(appSupportDirectoryProvider);
  return LocalFileStore(Directory(p.join(root.path, 'files')));
}

@Riverpod(keepAlive: true)
Clock clock(Ref ref) => const SystemClock();

@Riverpod(keepAlive: true)
IdGenerator idGenerator(Ref ref) => const UuidV4Generator();

/// UUID v4 implementation of the domain [IdGenerator].
final class UuidV4Generator implements IdGenerator {
  const UuidV4Generator();

  static const _uuid = Uuid();

  @override
  String newId() => _uuid.v4();
}
