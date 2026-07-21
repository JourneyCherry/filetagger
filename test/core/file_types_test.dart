import 'package:filetagger/core/file_types.dart';
import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:flutter_test/flutter_test.dart';

FileNode file(String path) => FileNode(path: path, isDirectory: false);
FileNode dir(String path) => FileNode(path: path, isDirectory: true);
FileNode nodeWithId(int id, String path, {bool isDirectory = false}) =>
    FileNode(id: id, path: path, isDirectory: isDirectory);

AssignedTag linkTag(int fileId, int defId, String? value) => AssignedTag(
  assignment: TagAssignment(
    fileNodeId: fileId,
    tagDefinitionId: defId,
    value: value,
  ),
  definition: TagDefinition(
    id: defId,
    name: '썸네일',
    valueType: TagValueType.link,
  ),
);

void main() {
  group('isImagePath', () {
    test('이미지 확장자를 대소문자 무시하고 인식한다', () {
      expect(isImagePath('a/b.png'), isTrue);
      expect(isImagePath('a/b.JPG'), isTrue);
      expect(isImagePath('photo.jpeg'), isTrue);
      expect(isImagePath('anim.GIF'), isTrue);
      expect(isImagePath('x.webp'), isTrue);
      expect(isImagePath('x.bmp'), isTrue);
    });

    test('이미지가 아니거나 확장자가 없으면 false', () {
      expect(isImagePath('a/b.txt'), isFalse);
      expect(isImagePath('doc.pdf'), isFalse);
      expect(isImagePath('noext'), isFalse);
      expect(isImagePath('trailing.'), isFalse);
      expect(isImagePath('.hidden'), isFalse);
    });
  });

  group('preferHorizontalPreview', () {
    test('가로가 세로 이상이면 가로 배치', () {
      expect(preferHorizontalPreview(800, 600), isTrue);
      expect(preferHorizontalPreview(500, 500), isTrue);
    });
    test('세로가 더 길면 세로 배치', () {
      expect(preferHorizontalPreview(400, 700), isFalse);
    });
  });

  group('buildFolderThumbnailIndex', () {
    test('폴더 하위(재귀)의 이름순 이미지들을 상한까지 모은다', () {
      final nodes = [
        dir('gallery'),
        file('gallery/zebra.png'),
        file('gallery/apple.jpg'),
        dir('gallery/nested'),
        file('gallery/nested/cat.png'),
        file('gallery/notes.txt'),
      ];
      final index = buildFolderThumbnailIndex(nodes);
      // gallery 하위 이미지: apple.jpg, nested/cat.png, zebra.png → 이름순
      expect(index['gallery'], [
        'gallery/apple.jpg',
        'gallery/nested/cat.png',
        'gallery/zebra.png',
      ]);
      // 중첩 폴더는 자신 하위 이미지만
      expect(index['gallery/nested'], ['gallery/nested/cat.png']);
    });

    test('상한(kFolderThumbnailStackCount)을 넘지 않는다', () {
      final nodes = [
        dir('many'),
        for (var i = 0; i < 10; i++) file('many/${i}pic.png'),
      ];
      final list = buildFolderThumbnailIndex(nodes)['many']!;
      expect(list, hasLength(kFolderThumbnailStackCount));
    });

    test('연결 끊김 노드와 폴더 자신은 후보에서 제외한다', () {
      final nodes = [
        dir('d'),
        FileNode(
          path: 'd/broken.png',
          isDirectory: false,
          missingSince: DateTime(2026),
        ),
        file('d/ok.png'),
      ];
      expect(buildFolderThumbnailIndex(nodes)['d'], ['d/ok.png']);
    });

    test('이미지가 없는 폴더는 인덱스에 없다', () {
      final nodes = [dir('empty'), file('empty/readme.txt')];
      expect(buildFolderThumbnailIndex(nodes).containsKey('empty'), isFalse);
    });
  });

  group('resolveThumbnailRelPaths', () {
    test('이미지 파일은 자기 자신 한 장', () {
      expect(resolveThumbnailRelPaths(file('a/b.png'), const {}), ['a/b.png']);
    });
    test('비이미지 파일은 빈 목록', () {
      expect(resolveThumbnailRelPaths(file('a/b.txt'), const {}), isEmpty);
    });
    test('폴더는 대표 이미지들을 인덱스에서 찾는다', () {
      final index = {
        'a': ['a/x.png', 'a/y.png'],
      };
      expect(resolveThumbnailRelPaths(dir('a'), index), ['a/x.png', 'a/y.png']);
      expect(resolveThumbnailRelPaths(dir('b'), index), isEmpty);
    });
    test('연결 끊김 노드는 빈 목록', () {
      final missing = FileNode(
        path: 'a/b.png',
        isDirectory: false,
        missingSince: DateTime(2026),
      );
      expect(resolveThumbnailRelPaths(missing, const {}), isEmpty);
    });
    test('커스텀 지정이 있으면 자기 이미지·폴더 대표보다 우선한다', () {
      // 이미지 파일이라도 커스텀 지정이 있으면 그것을 쓴다.
      expect(
        resolveThumbnailRelPaths(
          file('a/self.png'),
          const {},
          custom: const ['other/pick.png'],
        ),
        ['other/pick.png'],
      );
      // 폴더도 커스텀이 대표 인덱스를 덮는다.
      final index = {
        'a': ['a/x.png'],
      };
      expect(
        resolveThumbnailRelPaths(dir('a'), index, custom: const ['z/cover.png']),
        ['z/cover.png'],
      );
    });
    test('연결 끊김 노드는 커스텀이 있어도 빈 목록', () {
      final missing = FileNode(
        path: 'a/b.png',
        isDirectory: false,
        missingSince: DateTime(2026),
      );
      expect(
        resolveThumbnailRelPaths(missing, const {}, custom: const ['x/y.png']),
        isEmpty,
      );
    });

    group('preferSelfImage(프리뷰)', () {
      test('자기 이미지가 있는 노드는 커스텀보다 자기 자신을 우선한다', () {
        expect(
          resolveThumbnailRelPaths(
            file('a/self.png'),
            const {},
            custom: const ['other/pick.png'],
            preferSelfImage: true,
          ),
          ['a/self.png'],
        );
      });

      test('자기 이미지가 없는 파일(텍스트 등)은 커스텀을 쓴다', () {
        expect(
          resolveThumbnailRelPaths(
            file('a/notes.txt'),
            const {},
            custom: const ['other/pick.png'],
            preferSelfImage: true,
          ),
          ['other/pick.png'],
        );
      });

      test('폴더는 자기 이미지가 없으므로 커스텀을 쓴다', () {
        expect(
          resolveThumbnailRelPaths(
            dir('a'),
            const {},
            custom: const ['other/pick.png'],
            preferSelfImage: true,
          ),
          ['other/pick.png'],
        );
      });

      test('커스텀이 없으면 폴더는 대표 이미지로 폴백한다', () {
        final index = {
          'a': ['a/x.png'],
        };
        expect(
          resolveThumbnailRelPaths(dir('a'), index, preferSelfImage: true),
          ['a/x.png'],
        );
      });
    });
  });

  group('buildCustomThumbnailIndex', () {
    final target = nodeWithId(10, 'imgs/cover.png');
    final nonImage = nodeWithId(11, 'docs/readme.txt');
    final nodesById = {10: target, 11: nonImage};

    test('지정 태그가 없으면 빈 인덱스', () {
      final index = buildCustomThumbnailIndex(
        thumbnailTagId: null,
        assignmentsByFile: {
          1: [linkTag(1, 5, '10')],
        },
        nodesById: nodesById,
      );
      expect(index, isEmpty);
    });

    test('링크가 가리키는 대상 이미지를 그 노드의 썸네일로 쓴다', () {
      final index = buildCustomThumbnailIndex(
        thumbnailTagId: 5,
        assignmentsByFile: {
          1: [linkTag(1, 5, '10')],
        },
        nodesById: nodesById,
      );
      expect(index[1], ['imgs/cover.png']);
    });

    test('대상이 이미지가 아니거나 없으면 그 노드는 인덱스에서 빠진다', () {
      final index = buildCustomThumbnailIndex(
        thumbnailTagId: 5,
        assignmentsByFile: {
          1: [linkTag(1, 5, '11')], // 텍스트 파일 → 제외
          2: [linkTag(2, 5, '999')], // 없는 노드 → 제외
          3: [linkTag(3, 5, null)], // 값 없음 → 제외
        },
        nodesById: nodesById,
      );
      expect(index, isEmpty);
    });

    test('지정 태그가 아닌 링크 부여는 무시한다', () {
      final index = buildCustomThumbnailIndex(
        thumbnailTagId: 5,
        assignmentsByFile: {
          1: [linkTag(1, 6, '10')], // 다른 태그 id
        },
        nodesById: nodesById,
      );
      expect(index, isEmpty);
    });
  });
}
