import 'dart:async';
import 'dart:io';

import 'package:filetagger/DataStructures/error_code.dart';
import 'package:path/path.dart' as p;

class DirectoryChangeEvent {
  final int type; //FileSystemEvent
  final String path;
  FileSystemEntity? entity;

  DirectoryChangeEvent(this.type, this.path, {this.entity});
}

class DirectoryManager {
  static final DirectoryManager _instance = DirectoryManager._internal();

  factory DirectoryManager() {
    return _instance;
  }

  DirectoryManager._internal();

  Directory? _directory;
  // ignore: prefer_final_fields
  Map<String, FileSystemEntity> _entityMap = {};
  StreamSubscription<FileSystemEvent>? _watchSubscription;
  final _controller = StreamController<DirectoryChangeEvent>.broadcast();

  /// 현재까지의 파일 및 디렉토리 목록
  Iterable<String> getFilePathList() => _entityMap.keys;

  /// 존재하는 파일에 대한 정보 가져오기
  FileSystemEntity? getFileEntity(String path) => _entityMap[path];

  /// 변경 알림 Stream
  Stream<DirectoryChangeEvent> get onChange => _controller.stream;

  Future<void> closeDirectory() async {
    await _watchSubscription?.cancel();
    _watchSubscription = null;
    _directory = null;
    _entityMap.clear();
  }

  Future<ErrorCode> openDirectory(String path) async {
    if (_directory != null) return ErrorCode.directoryOtherStillOpened;

    final dir = Directory(path);
    if (!await dir.exists()) {
      throw FileSystemException("Directory does not exist", path);
    }

    _directory = dir;
    await _initialScan();

    _watchSubscription = dir.watch(recursive: true).listen(_handleEvent);

    return ErrorCode.success;
  }

  /// 초기 전체 스캔
  Future<void> _initialScan() async {
    await for (var entity
        in _directory!.list(recursive: true, followLinks: false)) {
      final path = _unifyPath(entity.path);
      _entityMap[path] = entity;
      _controller.add(DirectoryChangeEvent(FileSystemEvent.create, path));
    }
  }

  /// 변경 이벤트 처리
  Future<void> _handleEvent(FileSystemEvent event) async {
    final path = _unifyPath(event.path);

    switch (event.type) {
      case FileSystemEvent.create:
      case FileSystemEvent.modify:
        final type = FileSystemEntity.typeSync(event.path, followLinks: false);
        if (type == FileSystemEntityType.notFound) return;

        final entity = (type == FileSystemEntityType.directory)
            ? Directory(event.path)
            : File(event.path);
        _entityMap[path] = entity;
        _controller.add(DirectoryChangeEvent(
          event.type,
          path,
          entity: entity,
        ));
        break;

      case FileSystemEvent.delete:
      case FileSystemEvent.move:
        _entityMap.remove(path);
        _controller.add(DirectoryChangeEvent(event.type, path));
        break;
    }
  }

  void dispose() {
    _controller.close();
  }

  String _unifyPath(String path) {
    if (_directory == null) return path;
    path = p.relative(path, from: _directory!.path);
    //TODO : OS 디렉토리 구분자에 무관하게 하나로 통일(리눅스 형식)
    return path;
  }

  // 필요하면 주석 해제하고 사용
  //String _specifyPath(String path) {
  //  //TODO : 현재 OS에 맞는 디렉토리 구분자로 변경
  //  path = p.absolute(path);
  //  return path;
  //}
}
