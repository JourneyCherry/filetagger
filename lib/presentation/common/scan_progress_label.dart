import '../../domain/entities/scan_progress.dart';
import '../../l10n/app_localizations.dart';

/// 스캔 진행 상태를 한 줄 문구로. 목록 자리의 스피너와 상태표시줄이 같은 문구를
/// 나눠 쓴다(두 곳이 다른 말을 하면 같은 작업이 둘로 보인다).
///
/// 아직 첫 보고가 오지 않았으면 수치 없이 "스캔 중"만 알린다. 파일을 읽기 시작한
/// 뒤에는 읽은 수를 덧붙여, 훑기가 끝나고도 작업이 남아 있음을 드러낸다.
String scanProgressLabel(AppLocalizations l10n, ScanProgress? progress) {
  if (progress == null) return l10n.scanning;
  if (progress.filesIndexed == 0) {
    return l10n.scanningSeen(progress.entriesSeen);
  }
  return l10n.scanningSeenIndexed(progress.entriesSeen, progress.filesIndexed);
}
