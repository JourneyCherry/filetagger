import 'dart:io';

import 'package:filetagger/data/queue/command_export.dart';
import 'package:filetagger/data/queue/command_json.dart';
import 'package:filetagger/data/thumbnails/thumbnail_store.dart';
import 'package:filetagger/domain/entities/external_tag_command.dart';
import 'package:filetagger/domain/usecases/export_tag_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory out;

  setUp(() {
    root = Directory.systemTemp.createTempSync('filetagger_export_test');
    out = Directory(p.join(root.path, 'out'))..createSync(recursive: true);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  File cacheFile(String key) =>
      File(p.join(thumbnailCacheDirPath(root.path), key))
        ..createSync(recursive: true)
        ..writeAsStringSync('이미지 바이트 $key');

  ExportedCommands exported({
    List<ExternalTagCommand> commands = const [],
    Set<String> imageKeys = const {},
  }) => ExportedCommands(commands: commands, imageKeys: imageKeys);

  const command = ExternalTagCommand(targetPath: 'a.png', tagName: '읽음');

  test('명령을 배열 파일 하나로 쓴다', () async {
    final path = p.join(out.path, 'tags.json');

    final result = await writeCommandExport(
      filePath: path,
      exported: exported(commands: [command, command]),
      workspaceRoot: root.path,
    );

    expect(result.commands, 2);
    final decoded = decodeCommandFile(File(path).readAsStringSync());
    // 항목이 하나여도 배열이어야 한다 — 받는 쪽이 항목마다 결과를 가른다.
    expect(decoded.isArray, isTrue);
    expect(decoded.items, hasLength(2));
  });

  test('참조하는 캐시 파일을 요청 파일 옆에 같은 이름으로 복사한다', () async {
    cacheFile('cafe01.png');
    final path = p.join(out.path, 'tags.json');

    final result = await writeCommandExport(
      filePath: path,
      exported: exported(commands: [command], imageKeys: {'cafe01.png'}),
      workspaceRoot: root.path,
    );

    expect(result.images, 1);
    // 큐가 이미지의 상대 경로를 요청함 폴더 기준으로 찾으므로 나란히 있으면 맞는다.
    final copied = File(p.join(out.path, 'cafe01.png'));
    expect(copied.readAsStringSync(), '이미지 바이트 cafe01.png');
  });

  test('캐시 파일이 사라졌으면 그 항목만 건너뛰고 나머지는 내보낸다', () async {
    final path = p.join(out.path, 'tags.json');

    final result = await writeCommandExport(
      filePath: path,
      exported: exported(commands: [command], imageKeys: {'없는키.png'}),
      workspaceRoot: root.path,
    );

    expect(result.images, 0);
    expect(result.commands, 1);
    expect(File(path).existsSync(), isTrue);
  });

  test('저장 위치의 폴더가 없으면 만든다', () async {
    final path = p.join(out.path, '깊은', '자리', 'tags.json');

    await writeCommandExport(
      filePath: path,
      exported: exported(commands: [command]),
      workspaceRoot: root.path,
    );

    expect(File(path).existsSync(), isTrue);
  });
}
