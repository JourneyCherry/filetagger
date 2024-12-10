import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';

class DirectoryReader {
  static final DirectoryReader _instance = DirectoryReader._internal();

  factory DirectoryReader() {
    _instance._group.close();
    return _instance;
  }

  DirectoryReader._internal();

  StreamGroup<FileSystemEntity> _group = StreamGroup();

  Stream<FileSystemEntity> readDirectory(String path) {
    final stream = Directory(path).list(recursive: false);
    if (_group.isClosed) {
      //모든 작업이 완료되면 자동으로 닫히므로, 다시 열어줘야 함.
      _group = StreamGroup();
    }
    _group.add(stream);
    return _group.stream;
  }

  void clear() async {
    if (!_group.isClosed) {
      await _group.stream.drain(); //모든 stream 취소
      await _group.close(); //streamgroup 닫기(더이상 추가 불가)
    }
  }

  @protected
  @visibleForTesting
  bool isClosed() => _group.isClosed;

  @protected
  @visibleForTesting
  Future<void> waitForIdle() async => await _group.onIdle.first;
}
