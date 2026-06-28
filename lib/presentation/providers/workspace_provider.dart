import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 현재 열린 관리 폴더의 루트 경로. null이면 아직 폴더를 열지 않은 상태.
///
/// 이 값이 바뀌면 [databaseProvider]가 해당 폴더의 DB로 다시 연결된다.
final workspaceRootProvider = StateProvider<String?>((ref) => null);
