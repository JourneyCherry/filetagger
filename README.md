# File Tagger

특정 디렉토리의 모든 파일/서브디렉토리를 읽어, 사용자가 정의한 **태그 및 태그값**을
파일·디렉토리에 부여하고, 그 태그를 기준으로 **정렬·필터·탐색**을 돕는 데스크톱
애플리케이션입니다.

## 주요 기능

- 관리할 루트 디렉토리를 선택하고 파일/폴더를 스캔
- 라벨 / 텍스트 / 숫자 / 날짜 형태의 태그를 파일·폴더에 부여
- 태그 조합 필터와 태그값 기준 정렬
- 특정 태그가 부여된 항목만 모아보는 가상 폴더 뷰

## 기술 스택

- **Flutter** (멀티플랫폼 GUI, 데스크톱 우선: Windows / macOS / Linux)
- **Drift** (SQLite) — 태그 영속화
- **Riverpod** — 상태 관리

## 태그 저장 방식

태그 데이터는 관리 대상 디렉토리 루트의 `.filetagger/` 폴더 안 SQLite DB에
저장됩니다. 폴더를 이동·복사하면 태그도 함께 따라갑니다. 앱 전역 설정(최근 연
폴더 등)만 OS 애플리케이션 데이터 폴더에 보관합니다.

## 빌드 / 실행

```bash
flutter pub get
dart run build_runner build   # 코드 생성 (Drift)
flutter run -d windows        # 데스크톱 실행
```

## 프로젝트 구조

```
lib/
  domain/        엔티티, repository 인터페이스, 유즈케이스 (플랫폼 무관)
  data/          DB(Drift), 파일시스템 스캐너, repository 구현
  presentation/  Riverpod providers, 화면, 위젯
  core/          공통 유틸, 상수
```

설계 상세와 진행 상황은 [CLAUDE.md](CLAUDE.md), [docs/design.md](docs/design.md)
참조.

## 라이선스

[MIT](LICENSE)
