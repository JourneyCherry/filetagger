/// 이미지 파일의 픽셀 크기를 **헤더만 읽어** 알아내는 순수 파서. 전체 디코딩
/// (dart:ui/외부 패키지) 없이 앞부분 바이트에서 크기를 뽑아, 스캐너가 이동 추적용
/// 해시로 이미 읽는 바이트를 그대로 재사용한다(새 의존성 없음 — FNV 해시와 동일 방침).
///
/// 지원: PNG · JPEG · GIF · BMP · WebP(VP8/VP8L/VP8X). 형식을 모르거나 헤더가
/// 잘려 크기를 못 읽으면 null(그 파일은 '이미지 크기' 시스템 태그를 갖지 않는다).
library;

/// [bytes](파일 앞부분)에서 이미지 크기를 "가로x세로"로 읽는다. 실패 시 null.
String? readImageDimensions(List<int> bytes) {
  final size =
      _png(bytes) ??
      _gif(bytes) ??
      _bmp(bytes) ??
      _webp(bytes) ??
      _jpeg(bytes);
  if (size == null) return null;
  return '${size.$1}x${size.$2}';
}

typedef _Size = (int width, int height);

int _beU16(List<int> b, int o) => (b[o] << 8) | b[o + 1];
int _beU32(List<int> b, int o) =>
    (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
int _leU16(List<int> b, int o) => b[o] | (b[o + 1] << 8);
int _leS32(List<int> b, int o) =>
    (b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24)).toSigned(32);

bool _startsWith(List<int> b, List<int> sig, [int offset = 0]) {
  if (b.length < offset + sig.length) return false;
  for (var i = 0; i < sig.length; i++) {
    if (b[offset + i] != sig[i]) return false;
  }
  return true;
}

/// PNG: 8바이트 시그니처 뒤 IHDR 청크에 width(BE32)·height(BE32).
_Size? _png(List<int> b) {
  const sig = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  if (!_startsWith(b, sig)) return null;
  if (b.length < 24) return null;
  return (_beU32(b, 16), _beU32(b, 20));
}

/// GIF: "GIF87a"/"GIF89a" 뒤 논리 화면 width(LE16)·height(LE16).
_Size? _gif(List<int> b) {
  if (!_startsWith(b, [0x47, 0x49, 0x46])) return null; // "GIF"
  if (b.length < 10) return null;
  return (_leU16(b, 6), _leU16(b, 8));
}

/// BMP: "BM" 뒤 DIB 헤더의 width(LE32)·height(LE32, top-down이면 음수→절댓값).
_Size? _bmp(List<int> b) {
  if (!_startsWith(b, [0x42, 0x4D])) return null; // "BM"
  if (b.length < 26) return null;
  return (_leS32(b, 18).abs(), _leS32(b, 22).abs());
}

/// WebP: "RIFF"...."WEBP" 뒤 청크 유형별(VP8/VP8L/VP8X)로 크기를 뽑는다.
_Size? _webp(List<int> b) {
  if (!_startsWith(b, [0x52, 0x49, 0x46, 0x46])) return null; // "RIFF"
  if (!_startsWith(b, [0x57, 0x45, 0x42, 0x50], 8)) return null; // "WEBP"

  if (_startsWith(b, [0x56, 0x50, 0x38, 0x20], 12)) {
    // "VP8 " 손실. 프레임 태그(3) 뒤 시작코드 0x9d 0x01 0x2a, 이어 14비트 크기.
    if (b.length < 30) return null;
    if (b[23] != 0x9D || b[24] != 0x01 || b[25] != 0x2A) return null;
    final w = _leU16(b, 26) & 0x3FFF;
    final h = _leU16(b, 28) & 0x3FFF;
    return (w, h);
  }
  if (_startsWith(b, [0x56, 0x50, 0x38, 0x4C], 12)) {
    // "VP8L" 무손실. 시그니처 0x2F 뒤 4바이트에 (width-1)·(height-1) 14비트씩.
    if (b.length < 25) return null;
    if (b[20] != 0x2F) return null;
    final b0 = b[21], b1 = b[22], b2 = b[23], b3 = b[24];
    final w = 1 + (((b1 & 0x3F) << 8) | b0);
    final h = 1 + (((b3 & 0x0F) << 10) | (b2 << 2) | ((b1 & 0xC0) >> 6));
    return (w, h);
  }
  if (_startsWith(b, [0x56, 0x50, 0x38, 0x58], 12)) {
    // "VP8X" 확장. 캔버스 (width-1)·(height-1) 각 3바이트 LE.
    if (b.length < 30) return null;
    final w = 1 + (b[24] | (b[25] << 8) | (b[26] << 16));
    final h = 1 + (b[27] | (b[28] << 8) | (b[29] << 16));
    return (w, h);
  }
  return null;
}

/// JPEG: FFD8 뒤 마커를 훑어 SOFn 세그먼트의 height(BE16)·width(BE16)를 읽는다.
_Size? _jpeg(List<int> b) {
  if (!_startsWith(b, [0xFF, 0xD8])) return null;
  var o = 2;
  while (o + 9 < b.length) {
    // 다음 마커까지 0xFF 채움을 건너뛴다.
    if (b[o] != 0xFF) {
      o++;
      continue;
    }
    var marker = b[o + 1];
    // 0xFF 연속은 채움 바이트.
    while (marker == 0xFF && o + 1 < b.length) {
      o++;
      marker = b[o + 1];
    }
    o += 2;
    // 크기 없는 독립 마커(RSTn·SOI·EOI·TEM)는 세그먼트 길이가 없다.
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD9)) continue;
    if (o + 1 >= b.length) return null;
    final segLen = _beU16(b, o);
    // SOF0..SOF15 중 크기 정보를 담은 것(DHT 0xC4·JPG 0xC8·DAC 0xCC 제외).
    final isSof =
        marker >= 0xC0 &&
        marker <= 0xCF &&
        marker != 0xC4 &&
        marker != 0xC8 &&
        marker != 0xCC;
    if (isSof) {
      if (o + 7 >= b.length) return null;
      final h = _beU16(b, o + 3);
      final w = _beU16(b, o + 5);
      return (w, h);
    }
    o += segLen; // 이 세그먼트를 건너뛴다.
  }
  return null;
}
