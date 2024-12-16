import 'dart:async';
import 'dart:io';

class DirectoryReader {
  static final DirectoryReader _instance = DirectoryReader._internal();
  factory DirectoryReader() => _instance;
  DirectoryReader._internal();

  final List<StreamSubscription> _subscriptions = [];

  Future<List<FileSystemEntity>> readDirectory(String path) {
    return Directory(path).list(recursive: false).toList();
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
