import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/presentation/widgets/reconnect_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FileNode node(String path) => FileNode(path: path, isDirectory: false);

  test('이름이 유사한 후보를 위로 정렬한다', () {
    final candidates = [
      node('other/zzz.txt'),
      node('moved/report.txt'), // 이름 동일 → 가장 유사
      node('moved/reprt.txt'), // 한 글자 차이
    ];

    final sorted =
        sortCandidatesByNameSimilarity('report.txt', candidates);

    expect(sorted.first.path, 'moved/report.txt');
    expect(sorted[1].path, 'moved/reprt.txt');
    expect(sorted.last.path, 'other/zzz.txt');
  });

  test('편집 거리 동률이면 경로순으로 안정 정렬한다', () {
    final candidates = [
      node('b/report.txt'),
      node('a/report.txt'),
    ];

    final sorted =
        sortCandidatesByNameSimilarity('report.txt', candidates);

    expect(sorted.map((n) => n.path), ['a/report.txt', 'b/report.txt']);
  });

  test('대소문자를 무시하고 비교한다', () {
    final candidates = [node('x/PHOTO.JPG'), node('y/aaaaaa.bin')];

    final sorted = sortCandidatesByNameSimilarity('photo.jpg', candidates);

    expect(sorted.first.path, 'x/PHOTO.JPG');
  });
}
