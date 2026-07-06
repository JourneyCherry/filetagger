import 'package:filetagger/data/scanner/image_dimensions.dart';
import 'package:flutter_test/flutter_test.dart';

// 크기 400x300을 담은 최소 헤더 픽스처들. 전체 이미지가 아니라 크기 필드까지만 채운다.

List<int> _png() => [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // 시그니처
  0x00, 0x00, 0x00, 0x0D, // IHDR 길이
  0x49, 0x48, 0x44, 0x52, // "IHDR"
  0x00, 0x00, 0x01, 0x90, // width = 400 (BE)
  0x00, 0x00, 0x01, 0x2C, // height = 300 (BE)
];

List<int> _gif() => [
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, // "GIF89a"
  0x90, 0x01, // width = 400 (LE)
  0x2C, 0x01, // height = 300 (LE)
];

List<int> _bmp() => [
  0x42, 0x4D, // "BM"
  ...List<int>.filled(16, 0), // 파일 헤더 나머지 + DIB 크기까지 채움(오프셋 18까지)
  0x90, 0x01, 0x00, 0x00, // width = 400 (LE32)
  0x2C, 0x01, 0x00, 0x00, // height = 300 (LE32)
];

List<int> _jpeg() => [
  0xFF, 0xD8, // SOI
  0xFF, 0xC0, // SOF0
  0x00, 0x11, // 세그먼트 길이
  0x08, // 정밀도
  0x01, 0x2C, // height = 300 (BE)
  0x01, 0x90, // width = 400 (BE)
  0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
];

List<int> _webpVp8x() => [
  0x52, 0x49, 0x46, 0x46, // "RIFF"
  0x00, 0x00, 0x00, 0x00, // 파일 크기(무시)
  0x57, 0x45, 0x42, 0x50, // "WEBP"
  0x56, 0x50, 0x38, 0x58, // "VP8X"
  0x00, 0x00, 0x00, 0x00, // 청크 크기(무시)
  0x00, // 플래그
  0x00, 0x00, 0x00, // 예약
  0x8F, 0x01, 0x00, // width-1 = 399 (LE24) → 400
  0x2B, 0x01, 0x00, // height-1 = 299 (LE24) → 300
];

void main() {
  test('PNG 헤더에서 크기를 읽는다', () {
    expect(readImageDimensions(_png()), '400x300');
  });

  test('GIF 헤더에서 크기를 읽는다', () {
    expect(readImageDimensions(_gif()), '400x300');
  });

  test('BMP 헤더에서 크기를 읽는다', () {
    expect(readImageDimensions(_bmp()), '400x300');
  });

  test('JPEG SOF0 세그먼트에서 크기를 읽는다', () {
    expect(readImageDimensions(_jpeg()), '400x300');
  });

  test('WebP(VP8X) 캔버스 크기를 읽는다', () {
    expect(readImageDimensions(_webpVp8x()), '400x300');
  });

  test('이미지가 아니거나 헤더가 잘리면 null', () {
    expect(readImageDimensions([1, 2, 3, 4]), isNull);
    expect(readImageDimensions(const []), isNull);
    // PNG 시그니처만 있고 IHDR가 잘린 경우.
    expect(
      readImageDimensions([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
      isNull,
    );
  });
}
