import 'package:filetagger/core/file_types.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:flutter_test/flutter_test.dart';

FileNode file(String path) => FileNode(path: path, isDirectory: false);
FileNode dir(String path) => FileNode(path: path, isDirectory: true);

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
  });
}
