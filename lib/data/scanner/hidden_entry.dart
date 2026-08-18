import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

/// OS 숨김 파일/폴더 판정. 스캔은 숨김 항목을 인덱싱하지 않고 하위도 순회하지
/// 않는다(완전 제외 — 폴더도 노드로 만들지 않는다). 판정 기준은 플랫폼마다 다르다:
/// - POSIX(Linux/macOS): 이름이 '.'으로 시작하면 숨김(관례). 이름만으로 판정한다.
/// - Windows: 이름이 아니라 파일시스템 숨김/시스템 **속성**으로 판정한다. dart:io는
///   속성 조회를 제공하지 않아 FFI로 Win32 `GetFileAttributesW`를 호출한다.
///
/// Windows에서는 항목마다 [isHiddenEntry]로 묻는 대신 폴더 단위로
/// [hiddenLookupFor]를 만들어 쓰는 편이 훨씬 싸다(이유는 그 함수 문서에).
///
/// Windows에서 숨김 속성을 토글해도 실시간 감지는 하지 않고 다음 스캔(앱 시작·
/// 재스캔) 시점에 반영된다. 그때 숨김이 된 폴더는 완전 제외되어, 이미 인덱싱된
/// 하위 노드는 인덱싱 범위 밖으로 밀려나 정리된다(저장소 applyScan의 사라진 노드
/// 처리 — 불투명 전환으로 하위가 빠질 때와 같은 경로).
bool isHiddenEntry(FileSystemEntity entity) {
  if (Platform.isWindows) {
    return _hasHiddenAttribute(entity.path);
  }
  return isHiddenName(p.basename(entity.path));
}

/// POSIX 관례의 이름 기반 숨김 판정(이름이 '.'으로 시작). 순수 함수라 유닛테스트로
/// 커버한다. Windows는 이름이 아니라 속성으로 판정하므로 이 함수를 쓰지 않는다.
bool isHiddenName(String name) => name.startsWith('.');

/// 폴더 하나의 직속 항목들에 대한 숨김 판정기.
///
/// 판정을 **폴더 단위로 한 번** 준비하고 항목은 조회만 하게 만든다. Windows에서
/// 속성 조회는 호출마다 파일시스템을 거쳐, 항목 수만큼 부르면 폴더를 나열하는
/// 것보다 훨씬 비싸고 그 시간 동안 이벤트 루프가 통째로 막힌다. 나열은 이름과
/// 속성을 함께 돌려주므로, 그것을 한 번에 받아 두면 같은 정보를 훨씬 싸게 얻는다.
///
/// POSIX는 이름만 보면 되므로 준비할 것이 없다.
class DirectoryHiddenLookup {
  const DirectoryHiddenLookup._(this._attributesByName);

  /// 이름 → Win32 파일 속성. Windows에서 폴더를 한 번 나열해 채운다. 비-Windows
  /// 이거나 나열에 실패하면 null이며, 그때는 항목별로 직접 묻는 옛 경로를 탄다.
  final Map<String, int>? _attributesByName;

  /// [entity]가 숨김인지. 준비해 둔 속성에 없는 이름(나열 이후에 생긴 항목 등)은
  /// 그 항목 하나만 직접 물어 본다 — 준비분은 어디까지나 같은 답을 싸게 얻으려는
  /// 것이지, 판정 기준을 바꾸는 것이 아니다.
  bool isHidden(FileSystemEntity entity) {
    final byName = _attributesByName;
    if (byName == null) return isHiddenEntry(entity);
    final attributes = byName[p.basename(entity.path)];
    if (attributes == null) return isHiddenEntry(entity);
    return _isHiddenAttributes(attributes);
  }
}

/// [directoryPath]의 직속 항목들에 대한 숨김 판정기를 만든다. 폴더를 나열하기
/// 직전이나 직후에 한 번 만들어, 그 폴더의 항목들에 재사용한다.
DirectoryHiddenLookup hiddenLookupFor(String directoryPath) {
  if (!Platform.isWindows) return const DirectoryHiddenLookup._(null);
  return DirectoryHiddenLookup._(_attributesInDirectory(directoryPath));
}

// --- Windows 속성 조회(FFI) ---------------------------------------------------

/// Win32 파일 속성 비트. `GetFileAttributesW` 결과가 숨김/시스템 비트를 포함하면
/// 숨김으로 본다(탐색기의 숨김·보호된 OS 파일 감춤과 같은 취지).
const int _fileAttributeHidden = 0x2;
const int _fileAttributeSystem = 0x4;

/// 조회 실패 시 `GetFileAttributesW`가 돌려주는 표식(모든 비트 1). 이 경우 숨김으로
/// 단정하지 않는다(존재하지 않거나 접근 불가 — 스캔의 다른 단계가 자연히 걸러낸다).
const int _invalidFileAttributes = 0xFFFFFFFF;

// kernel32와 함수 심볼은 top-level final의 지연 초기화로, Windows에서 아래 함수가
// 처음 호출될 때만 로드된다(비-Windows에서는 DynamicLibrary.open이 실행되지 않음).
final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');
final int Function(Pointer<Utf16>) _getFileAttributesW = _kernel32
    .lookupFunction<
      Uint32 Function(Pointer<Utf16>),
      int Function(Pointer<Utf16>)
    >('GetFileAttributesW');
final int Function(Pointer<Utf16>, int) _setFileAttributesW = _kernel32
    .lookupFunction<
      Int32 Function(Pointer<Utf16>, Uint32),
      int Function(Pointer<Utf16>, int)
    >('SetFileAttributesW');

bool _hasHiddenAttribute(String path) {
  final ptr = path.toNativeUtf16();
  try {
    final attrs = _getFileAttributesW(ptr);
    if (attrs == _invalidFileAttributes) return false;
    return _isHiddenAttributes(attrs);
  } finally {
    malloc.free(ptr);
  }
}

/// 속성 비트가 숨김을 뜻하는지(탐색기의 숨김·보호된 OS 파일 감춤과 같은 취지).
bool _isHiddenAttributes(int attributes) =>
    (attributes & (_fileAttributeHidden | _fileAttributeSystem)) != 0;

// --- Windows 폴더 나열(FFI) ---------------------------------------------------

/// `WIN32_FIND_DATAW`에서 우리가 쓰는 자리. 구조체 전체 크기와 파일 이름이 시작하는
/// 위치만 알면 되고(속성은 맨 앞), 시각·크기 등 나머지 필드는 건너뛴다.
const int _findDataBytes = 592;
const int _findDataNameOffset = 44;

/// `FindFirstFileW`가 실패했을 때 돌려주는 핸들 값(INVALID_HANDLE_VALUE).
const int _invalidHandle = -1;

final int Function(Pointer<Utf16>, Pointer<Uint8>) _findFirstFileW = _kernel32
    .lookupFunction<
      IntPtr Function(Pointer<Utf16>, Pointer<Uint8>),
      int Function(Pointer<Utf16>, Pointer<Uint8>)
    >('FindFirstFileW');
final int Function(int, Pointer<Uint8>) _findNextFileW = _kernel32
    .lookupFunction<
      Int32 Function(IntPtr, Pointer<Uint8>),
      int Function(int, Pointer<Uint8>)
    >('FindNextFileW');
final int Function(int) _findClose = _kernel32
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>('FindClose');

/// 폴더를 한 번 나열해 직속 항목의 이름 → 속성을 모은다. 나열하지 못하면
/// null(호출부는 항목별 조회로 돌아간다). 자기 자신·부모 항목은 담지 않는다.
Map<String, int>? _attributesInDirectory(String directoryPath) {
  final data = malloc.allocate<Uint8>(_findDataBytes);
  // 폴더 안의 모든 항목을 뜻하는 검색 패턴(구분자는 플랫폼 규칙을 따른다).
  final pattern = p.join(directoryPath, '*').toNativeUtf16();
  try {
    final handle = _findFirstFileW(pattern, data);
    if (handle == _invalidHandle) return null;
    final attributesByName = <String, int>{};
    try {
      do {
        final name = (data + _findDataNameOffset).cast<Utf16>().toDartString();
        if (name == '.' || name == '..') continue;
        attributesByName[name] = data.cast<Uint32>().value;
      } while (_findNextFileW(handle, data) != 0);
    } finally {
      _findClose(handle);
    }
    return attributesByName;
  } finally {
    malloc.free(data);
    malloc.free(pattern);
  }
}

/// 주어진 경로(폴더/파일)를 OS 숨김으로 표시한다. `.filetagger/`를 만들고 나서
/// 탐색기 등에서 감추는 용도다. 플랫폼별로 숨김 의미가 다르다:
/// - POSIX(Linux/macOS): 이름이 '.'으로 시작하면 이미 관례상 숨김이므로 할 일이 없다.
/// - Windows: 이름이 아니라 숨김 **속성**을 실제로 설정해야 감춰진다(FFI
///   `SetFileAttributesW`). 기존 속성을 보존하고 숨김 비트만 더한다.
///
/// 숨김은 편의 기능이라 조회/설정 실패나 미지원 플랫폼에서는 조용히 넘어간다
/// (앱 동작에는 지장이 없다). 이미 숨김이면 불필요한 설정 호출을 건너뛴다.
void markPathHidden(String path) {
  if (!Platform.isWindows) return;
  final ptr = path.toNativeUtf16();
  try {
    final attrs = _getFileAttributesW(ptr);
    if (attrs == _invalidFileAttributes) return;
    if ((attrs & _fileAttributeHidden) != 0) return;
    _setFileAttributesW(ptr, attrs | _fileAttributeHidden);
  } finally {
    malloc.free(ptr);
  }
}
