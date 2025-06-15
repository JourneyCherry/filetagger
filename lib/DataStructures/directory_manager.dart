import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
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
    await _scanDirectory(rootDirectoryPath: _directory!.path);

    _watchSubscription = dir.watch(recursive: true).listen(_handleEvent);

    return ErrorCode.success;
  }

  /// 초기 전체 스캔
  Future<void> _scanDirectory({
    required String rootDirectoryPath,
    bool rootInclude = false,
  }) async {
    Queue<Directory> queue = Queue<Directory>();
    Directory rootEntity = Directory(rootDirectoryPath);

    if (rootInclude) {
      final rootUpath = _unifyPath(rootDirectoryPath);
      _entityMap[rootUpath] = rootEntity;
    }
    queue.addLast(rootEntity);

    while (queue.isNotEmpty) {
      final dir = queue.removeFirst();

      await for (var entity in dir.list(recursive: false, followLinks: false)) {
        if (isHiddenEntity(entity)) continue; //숨김 파일/디렉토리는 무시

        final upath = _unifyPath(entity.path);
        _entityMap[upath] = entity;
        _controller.add(DirectoryChangeEvent(FileSystemEvent.create, upath));

        if (entity is Directory) {
          queue.addLast(entity);
        }
      }
    }
  }

  /// 변경 이벤트 처리
  Future<void> _handleEvent(FileSystemEvent event) async {
    final upath = _unifyPath(event.path);

    switch (event.type) {
      case FileSystemEvent.create: // 파일/디렉토리 생성
        final type = FileSystemEntity.typeSync(event.path, followLinks: false);
        if (type == FileSystemEntityType.notFound) return;

        final entity = (type == FileSystemEntityType.directory)
            ? Directory(event.path)
            : File(event.path);

        if (isHiddenEntity(entity)) return;

        _entityMap[upath] = entity;
        _controller.add(DirectoryChangeEvent(
          event.type,
          upath,
          entity: entity,
        ));
        break;
      case FileSystemEvent.modify: // 파일/디렉토리 속성 변경
        final type = FileSystemEntity.typeSync(event.path, followLinks: false);
        if (type == FileSystemEntityType.notFound) return;

        final entity = (type == FileSystemEntityType.directory)
            ? Directory(event.path)
            : File(event.path);
        if (isHiddenEntity(entity)) {
          // 파일/디렉토리를 숨김처리 하는 경우
          _entityMap.remove(upath); // 본인을 목록에서 제거하고
          _entityMap.removeWhere((subUpath, subEntity) => //해당 디렉토리의 하위 파일들을 제거
              !(p.isWithin(event.path, subEntity.path)));
        } else {
          //파일/디렉토리를 숨기지 않음 처리 하는 경우
          if (entity is File) {
            _entityMap[upath] = entity; // 파일은 단순 추가
          } else {
            _scanDirectory(
                rootDirectoryPath: event.path,
                rootInclude: true); // 디렉토리는 서브 엔티티 전체 스캔
          }
        }
        break;

      case FileSystemEvent.delete: // 파일/디렉토리 제거
        _entityMap.remove(upath); //TODO : 하위 파일/디렉토리도 삭제해야하는지 확인 필요
        _controller.add(DirectoryChangeEvent(event.type, upath));
        break;
      case FileSystemEvent.move: // 파일/디렉토리 이동 //TODO : 실제로 어떻게 이벤트가 발생하는지 확인 필요
      default:
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

  bool isHiddenEntity(FileSystemEntity entity) {
    if (isHiddenEntityUnix(entity)) return true; // 유닉스 형식 숨김 파일/디렉토리는 전체 적용
    if (Platform.isWindows && isHiddenEntityWindows(entity)) return true;

    return false;
  }

  /// 윈도우 시스템에서 파일/디렉토리 숨김 여부
  bool isHiddenEntityWindows(FileSystemEntity entity) {
    final ptr = entity.path.toNativeUtf16();
    final attrs = GetFileAttributes(ptr); // 파일 속성 가져와서 비교
    calloc.free(ptr);
    if (attrs == -1) return false; //INVALID_FILE_ATTRIBUTES
    return (attrs & FILE_FLAGS_AND_ATTRIBUTES.FILE_ATTRIBUTE_HIDDEN) != 0;
  }

  /// 유닉스 시스템에서 파일/디렉토리 숨김 여부
  bool isHiddenEntityUnix(FileSystemEntity entity) {
    return p.basename(entity.path).startsWith('.'); //이름이 '.'으로 시작하면 숨김파일
  }
}
