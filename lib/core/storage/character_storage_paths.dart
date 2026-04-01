import 'dart:io';

import 'package:path_provider/path_provider.dart';

enum CharacterStorageKind { original, transparent, thumbnail }

enum CharacterDebugStorageKind { original, stroke, floodfill, mask, preview }

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

extension _CharacterDebugStorageKindPath on CharacterDebugStorageKind {
  String get directoryName {
    switch (this) {
      case CharacterDebugStorageKind.original:
        return 'original';
      case CharacterDebugStorageKind.stroke:
        return 'stroke';
      case CharacterDebugStorageKind.floodfill:
        return 'floodfill';
      case CharacterDebugStorageKind.mask:
        return 'mask';
      case CharacterDebugStorageKind.preview:
        return 'preview';
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

  Future<Directory> get debugRootDirectory async {
    final directory = Directory(
      '${baseDirectory.path}/$rootDirectoryName/debug',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<Directory> debugDirectory(CharacterDebugStorageKind kind) async {
    final rootDirectory = await debugRootDirectory;
    final directory = Directory('${rootDirectory.path}/${kind.directoryName}');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

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
