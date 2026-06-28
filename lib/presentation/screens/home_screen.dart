import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/workspace_provider.dart';

/// Phase 1 확인용 화면: 관리 폴더를 열어 `.filetagger/` DB 연결과 최근 폴더
/// 영속화가 동작하는지 보여준다. 파일 목록/태그 UI는 이후 단계에서 채운다.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openFolder(WidgetRef ref) async {
    final path = await FilePicker.getDirectoryPath();
    if (path == null) return;
    ref.read(workspaceRootProvider.notifier).state = path;
    await ref.read(recentFoldersProvider.notifier).touch(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceRoot = ref.watch(workspaceRootProvider);
    // DB는 폴더가 열릴 때 생성/연결된다. 여기서 watch해 생명주기를 활성화한다.
    final database = ref.watch(databaseProvider);
    final recentFolders = ref.watch(recentFoldersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('File Tagger')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton.icon(
              onPressed: () => _openFolder(ref),
              icon: const Icon(Icons.folder_open),
              label: const Text('폴더 열기'),
            ),
            const SizedBox(height: 16),
            if (workspaceRoot != null) ...[
              Text('현재 폴더', style: Theme.of(context).textTheme.titleMedium),
              Text(workspaceRoot),
              const SizedBox(height: 4),
              Text(
                database != null ? 'DB 연결됨 (.filetagger)' : 'DB 미연결',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 32),
            ],
            Text('최근 폴더', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: recentFolders.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('설정을 불러오지 못했습니다: $e'),
                data: (folders) => folders.isEmpty
                    ? const Text('아직 연 폴더가 없습니다.')
                    : ListView.builder(
                        itemCount: folders.length,
                        itemBuilder: (context, index) {
                          final folder = folders[index];
                          return ListTile(
                            leading: const Icon(Icons.folder),
                            title: Text(folder),
                            onTap: () {
                              ref.read(workspaceRootProvider.notifier).state =
                                  folder;
                              ref
                                  .read(recentFoldersProvider.notifier)
                                  .touch(folder);
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => ref
                                  .read(recentFoldersProvider.notifier)
                                  .remove(folder),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
