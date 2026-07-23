import 'package:filetagger/core/constants.dart';
import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/thumbnail_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('thumbnailCacheRelPath', () {
    test('캐시 키를 .filetagger 하위 상대 경로로 만든다', () {
      expect(
        thumbnailCacheRelPath('abc123.png'),
        '$filetaggerDirName/$thumbnailCacheDirName/abc123.png',
      );
    });
  });

  group('downscaleTargetSize', () {
    test('가장 긴 변이 상한 이하면 축소하지 않는다(null)', () {
      expect(downscaleTargetSize(800, 600, 1024), isNull);
      expect(downscaleTargetSize(1024, 1024, 1024), isNull);
    });

    test('상한을 넘으면 비율을 유지해 가장 긴 변을 상한에 맞춘다', () {
      final r = downscaleTargetSize(4000, 2000, 1000);
      expect(r, isNotNull);
      expect(r!.$1, 1000);
      expect(r.$2, 500);
    });

    test('세로가 더 길면 세로를 상한에 맞춘다', () {
      final r = downscaleTargetSize(1000, 4000, 1000);
      expect(r!.$1, 250);
      expect(r.$2, 1000);
    });

    test('0 이하 크기는 축소 없음으로 안전 폴백', () {
      expect(downscaleTargetSize(0, 0, 1000), isNull);
    });
  });

  group('referencedImageKeys', () {
    AssignedTag tagOf(TagValueType type, String? value) => AssignedTag(
      assignment: TagAssignment(
        fileNodeId: 1,
        tagDefinitionId: 1,
        value: value,
      ),
      definition: TagDefinition(name: 't', valueType: type),
    );

    test('이미지 태그의 비어있지 않은 값만 모은다', () {
      final byFile = {
        1: [
          tagOf(TagValueType.image, 'a.png'),
          tagOf(TagValueType.link, '42'),
          tagOf(TagValueType.text, 'hello'),
        ],
        2: [
          tagOf(TagValueType.image, 'b.jpg'),
          tagOf(TagValueType.image, ''),
          tagOf(TagValueType.image, null),
        ],
      };
      expect(referencedImageKeys(byFile), {'a.png', 'b.jpg'});
    });

    test('이미지 태그가 없으면 빈 집합', () {
      final byFile = {
        1: [tagOf(TagValueType.text, 'x')],
      };
      expect(referencedImageKeys(byFile), isEmpty);
    });
  });
}
