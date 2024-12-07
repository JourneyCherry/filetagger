import 'dart:io';
import 'package:async/async.dart';

class DirectoryReader {
  static final DirectoryReader _instance = DirectoryReader._internal();

  factory DirectoryReader() {
    return _instance;
  }

  DirectoryReader._internal();

  String? path;
  Future<List<FileSystemEntity>> fileList = Future<List<FileSystemEntity>>(
    () => [],
  );
  CancelableOperation? _operation;

  void readDirectory(String? path) async {
    if (_operation != null) {
      await _operation!.cancel();
    }
    this.path = path;
    if (path == null) return;

    _operation = CancelableOperation.fromFuture(
      fileList,
    );
    fileList = Directory(path).list(recursive: false).toList();
  }

  Future<List<FileSystemEntity>> fetchDirectory() async {
    return fileList;
  }
}
