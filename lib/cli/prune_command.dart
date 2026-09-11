/// `prune` — 가리키는 곳이 없어진 참조를 걷어낸다.
///
/// **없앤 시스템 태그의 id**를 가리키는 참조가 대상이다. 시스템 태그는 DB에 행으로
/// 살지 않고 노드에서 계산되므로 태그를 없애도 지울 부여 기록이 없지만, 그 id를 적어
/// 둔 보기 설정과 조건 프리셋은 `.filetagger/` 안에 그대로 남는다.
///
/// **자동으로 돌지 않는다.** 다른 명령이 몰래 설정 파일을 고쳐 쓰면, 무엇을 물어본
/// 명령이 무엇을 바꿨는지 알 길이 없다 — 전체 스캔을 `scan` 하나로 모아 둔 것과 같은
/// 이유다. 화면은 폴더를 열 때 스스로 정리하므로 이 명령은 콘솔만 쓰는 자리의 몫이다.
library;

import 'dart:io';

import '../data/repositories/drift_tag_repository.dart';
import '../data/settings/query_preset_store.dart';
import '../data/settings/view_settings_store.dart';
import '../domain/usecases/purge_retired_system_tags.dart';
import 'cli_command.dart';
import 'cli_output.dart';

class PruneCommand extends CliCommand {
  PruneCommand(super.strings);

  @override
  String get name => 'prune';

  @override
  String get description => strings.pruneDescription;

  @override
  String get invocation => '$executableName $name';

  @override
  Future<int> run() async {
    if (rest.isNotEmpty) usageException(strings.takesNoArguments(name));

    return withWorkspace((root, db) async {
      final settingsStore = JsonViewSettingsStore(root);
      final presetStore = JsonQueryPresetStore(root);

      final settings = purgeRetiredFromViewSettings(await settingsStore.load());
      final presets = purgeRetiredFromPresets(await presetStore.load());
      // 가리키는 곳이 없는 부여는 어느 화면에도 뜨지 않아 손으로 지울 수단이 없다.
      final dangling = await DriftTagRepository(db).deleteDanglingAssignments();

      // **바뀐 것만 다시 쓴다** — 손댈 것이 없는데 파일을 덮어쓰면 수정 시각만 흔들려
      // 백업·동기화가 매번 달라진 것으로 본다.
      if (settings.changed) await settingsStore.save(settings.value);
      if (presets.changed) await presetStore.save(presets.value);

      final total = settings.removed + presets.removed + dangling;
      if (!writeCount(total)) return exitOk;
      if (asJson) {
        writeJson({
          _kRoot: root,
          _kViewSettings: settings.removed,
          _kPresets: presets.removed,
          _kAssignments: dangling,
        });
      } else {
        stdout
          ..writeln('${strings.labelViewSettings}\t${settings.removed}')
          ..writeln('${strings.labelPresets}\t${presets.removed}')
          ..writeln('${strings.labelAssignments}\t$dangling');
      }
      return exitOk;
    });
  }
}

const String _kRoot = 'root';
const String _kViewSettings = 'viewSettings';
const String _kPresets = 'presets';
const String _kAssignments = 'assignments';
