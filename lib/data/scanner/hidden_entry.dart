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
    return (attrs & (_fileAttributeHidden | _fileAttributeSystem)) != 0;
  } finally {
    malloc.free(ptr);
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
