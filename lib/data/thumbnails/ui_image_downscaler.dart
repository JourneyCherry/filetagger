/// 썸네일 축소기의 Flutter 구현. 엔진 디코더(dart:ui)를 쓰므로 **Flutter가 떠 있는
/// 실행에서만** 성립하며, 그래서 저장소([thumbnail_store])와 한 파일에 두지 않는다 —
/// 같은 저장소를 콘솔 진입점도 지나가기 때문이다.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

/// [bytes]를 [targetWidth]x[targetHeight]로 축소해 PNG 바이트로 인코딩한다.
///
/// 디코더에 목표 크기를 함께 주므로 원본 전체를 메모리에 펼치지 않는다. 형식을
/// 못 읽는 등 어떤 이유로든 실패하면 null을 돌려주고, 호출부는 원본을 그대로 보관한다.
Future<Uint8List?> downscaleImageWithUi(
  Uint8List bytes,
  int targetWidth,
  int targetHeight,
) async {
  try {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    codec.dispose();
    return data?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}
