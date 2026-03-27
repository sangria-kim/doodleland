import 'dart:io';

import 'package:path_provider/path_provider.dart';

enum CharacterStorageKind {
  original,
  transparent,
  thumbnail,
}

extension _CharacterStorageKindPath on CharacterStorageKind {
  String get directoryName {
    switch (this) {
      case CharacterStorageKind.original:
        return 'original';
      case CharacterStorageKind.transparent:
        return 'transparent';
      case CharacterStorageKind.thumbnail:
        return 'thumbnail';
    }
  }
}

class CharacterStoragePaths {
  const CharacterStoragePaths({
    required this.baseDirectory,
    this.rootDirectoryName = 'characters',
  });

  final Directory baseDirectory;
  final String rootDirectoryName;

  Future<Directory> get originalDirectory =>
      _ensureDirectory(CharacterStorageKind.original);

  Future<Directory> get transparentDirectory =>
      _ensureDirectory(CharacterStorageKind.transparent);

  Future<Directory> get thumbnailDirectory =>
      _ensureDirectory(CharacterStorageKind.thumbnail);

  Future<Directory> _ensureDirectory(CharacterStorageKind kind) async {
    final directory = Directory(
      '${baseDirectory.path}/$rootDirectoryName/${kind.directoryName}',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<String> originalImagePath({String extension = 'png'}) =>
      _nextImagePath(CharacterStorageKind.original, extension: extension);

  Future<String> transparentImagePath({String extension = 'png'}) =>
      _nextImagePath(CharacterStorageKind.transparent, extension: extension);

  Future<String> thumbnailImagePath({String extension = 'png'}) =>
      _nextImagePath(CharacterStorageKind.thumbnail, extension: extension);

  Future<String> _nextImagePath(
    CharacterStorageKind kind, {
    required String extension,
  }) async {
    final directory = await _ensureDirectory(kind);
    final filename = _nextFileName(kind, DateTime.now());
    return '${directory.path}/$filename.$extension';
  }

  String _nextFileName(CharacterStorageKind kind, DateTime timestamp) {
    final millis = timestamp.millisecondsSinceEpoch;
    return '${kind.directoryName}_$millis';
  }
}

class CharacterStoragePathFactory {
  const CharacterStoragePathFactory();

  Future<CharacterStoragePaths> create() async {
    final documentDirectory = await getApplicationDocumentsDirectory();
    return CharacterStoragePaths(baseDirectory: documentDirectory);
  }
}
