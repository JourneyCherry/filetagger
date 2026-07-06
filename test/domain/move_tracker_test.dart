import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/usecases/move_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final mtime = DateTime(2024, 1, 1, 12, 30, 15);

  FileNode file(
    String path, {
    int size = 10,
    String hash = 'abc',
    DateTime? at,
  }) => FileNode(
    path: path,
    isDirectory: false,
    size: size,
    modifiedAt: at ?? mtime,
    contentHashPrefix: hash,
  );

  const tracker = MoveTracker();

  test('크기·수정시각·해시가 같은 유일 쌍을 이동으로 매칭한다', () {
    final old = file('old/a.txt');
    final moved = file('new/a.txt');

    final result = tracker.match([old], [moved]);

    expect(result, hasLength(1));
    expect(result[old], moved);
  });

  test('수정시각이 초 미만으로만 달라도 같은 파일로 본다', () {
    final old = file('old/a.txt', at: DateTime(2024, 1, 1, 12, 30, 15));
    final moved = file(
      'new/a.txt',
      at: DateTime(2024, 1, 1, 12, 30, 15, 800),
    ); // 밀리초 차이

    final result = tracker.match([old], [moved]);

    expect(result[old], moved);
  });

  test('내용 해시가 다르면 매칭하지 않는다', () {
    final old = file('old/a.txt', hash: 'aaa');
    final other = file('new/a.txt', hash: 'bbb');

    expect(tracker.match([old], [other]), isEmpty);
  });

  test('같은 시그니처 후보가 여럿이면(모호) 매칭하지 않는다', () {
    final old = file('old/a.txt');
    final cand1 = file('new/a.txt');
    final cand2 = file('new/b.txt');

    expect(tracker.match([old], [cand1, cand2]), isEmpty);
  });

  test('여러 옛 노드가 한 후보를 가리키면(모호) 매칭하지 않는다', () {
    final old1 = file('old/a.txt');
    final old2 = file('old/b.txt');
    final cand = file('new/x.txt');

    expect(tracker.match([old1, old2], [cand]), isEmpty);
  });

  FileNode dir(String path, {String? sig}) =>
      FileNode(path: path, isDirectory: true, childSignature: sig);

  test('자식 시그니처가 같은 유일한 폴더 쌍을 이동으로 매칭한다', () {
    final old = dir('old/d', sig: 'sig1');
    final moved = dir('new/d', sig: 'sig1');

    final result = tracker.match([old], [moved]);

    expect(result[old], moved);
  });

  test('자식 시그니처가 다르면 폴더를 매칭하지 않는다', () {
    expect(
      tracker.match([dir('old/d', sig: 'a')], [dir('new/d', sig: 'b')]),
      isEmpty,
    );
  });

  test('시그니처가 없는(빈) 폴더는 매칭하지 않는다', () {
    expect(tracker.match([dir('old/d')], [dir('new/d')]), isEmpty);
  });

  test('같은 시그니처 폴더 후보가 여럿이면(모호) 매칭하지 않는다', () {
    final old = dir('old/d', sig: 's');
    expect(
      tracker.match([old], [dir('new/d1', sig: 's'), dir('new/d2', sig: 's')]),
      isEmpty,
    );
  });

  test('파일과 폴더는 시그니처 문자열이 같아도 서로 매칭하지 않는다', () {
    // 파일 해시와 폴더 시그니처가 우연히 같은 문자열이어도 유형이 달라 매칭 불가.
    final f = file('old/x', hash: 'same');
    final d = dir('new/x', sig: 'same');

    expect(tracker.match([f], [d]), isEmpty);
    expect(tracker.match([d], [f]), isEmpty);
  });

  test('서로 다른 두 이동을 각각 올바르게 매칭한다', () {
    final oldA = file('old/a.txt', size: 10, hash: 'aaa');
    final oldB = file('old/b.txt', size: 20, hash: 'bbb');
    final newA = file('new/a.txt', size: 10, hash: 'aaa');
    final newB = file('new/b.txt', size: 20, hash: 'bbb');

    final result = tracker.match([oldA, oldB], [newA, newB]);

    expect(result[oldA], newA);
    expect(result[oldB], newB);
  });
}
