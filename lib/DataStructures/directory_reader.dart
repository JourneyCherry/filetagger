import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

class DirectoryReader {
  static final DirectoryReader _instance = DirectoryReader._internal();
  factory DirectoryReader() => _instance;
  DirectoryReader._internal();

  final List<StreamSubscription> _subscriptions = [];

  Future<List<FileSystemEntity>> readDirectory(String path) async {
    List<FileSystemEntity> list =
        await Directory(path).list(recursive: false).toList();
    return list.where((file) {
      //TODO : Windows 환경에서 숨김파일 확인 로직 필요.
      return !p.basename(file.path).startsWith('.');
    }).toList();
  }

  void watchDirectory(String path, void Function(FileSystemEvent) onData) {
    _subscriptions.add(Directory(path).watch(recursive: false).listen(
          onData,
        ));
  }

  void close() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}
