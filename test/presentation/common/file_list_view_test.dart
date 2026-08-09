import 'package:filetagger/presentation/common/file_list_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('얕은 깊이는 그대로 들여쓰고, 한계를 넘으면 같은 단계로 눌린다', () {
    expect(visualIndentDepth(0), 0);
    expect(visualIndentDepth(kMaxIndentDepth), kMaxIndentDepth);
    expect(visualIndentDepth(kMaxIndentDepth + 5), kMaxIndentDepth);
  });
}
