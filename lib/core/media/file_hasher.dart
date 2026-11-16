import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

/// Computes the hex SHA-256 of a file's bytes.
typedef FileHasher = Future<String> Function(String path);

/// Streams the file through SHA-256 on a background isolate so hashing a
/// large photo never blocks the UI thread.
Future<String> sha256OfFile(String path) => Isolate.run(() async {
  final digest = await sha256.bind(File(path).openRead()).first;
  return digest.toString();
});
