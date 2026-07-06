/// 프로젝트 전역에서 쓰이는 고정 이름들의 단일 출처.
///
/// 값 자체를 주석/문서에 중복 기재하지 않기 위해(컨벤션 2) 이름 상수는
/// 모두 이 파일에서만 정의한다.
library;

/// 관리 폴더 루트에 생성되는 태그 메타데이터 폴더 이름.
///
/// 폴더 이동·복사 시 태그 DB가 함께 따라오도록 관리 폴더 안에 둔다.
/// 스캔 대상에서는 항상 제외된다.
const String filetaggerDirName = '.filetagger';

/// 태그 DB 파일 이름. [filetaggerDirName] 폴더 안에 생성된다.
const String databaseFileName = 'filetagger.sqlite';

/// 전역 설정(최근 연 폴더 목록 등 머신 단위 설정) 파일 이름.
///
/// 관리 폴더가 아니라 OS 앱데이터 폴더에 저장된다.
const String settingsFileName = 'settings.json';

/// 워크스페이스별 보기 설정(필터·정렬) 파일 이름.
///
/// [filetaggerDirName] 폴더 안에 저장되어 폴더 이동·복사 시 함께 따라온다.
const String viewSettingsFileName = 'view.json';
