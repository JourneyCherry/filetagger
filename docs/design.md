# File Tagger — 설계 문서

## 1. 목적

특정 디렉토리의 모든 파일/서브디렉토리를 읽어, 사용자가 정의한 태그 및
태그값을 파일·디렉토리에 부여하고, 그 태그를 기준으로 정렬·필터·탐색을 돕는
멀티플랫폼(데스크톱 우선) 애플리케이션.

## 2. 확정된 설계 결정

| 항목 | 결정 | 비고 |
|------|------|------|
| 태그 저장 | 중앙 SQLite DB (Drift) | 빠른 검색·정렬, 멀티플랫폼 일관성 |
| DB 위치 | 관리 폴더 루트의 `.filetagger/` 안 | 폴더 이동·복사 시 태그가 함께 이동 |
| 전역 설정 위치 | OS 앱데이터 폴더 | 최근 연 폴더 목록 등 머신 단위 설정 |
| 태그값 유형 | label / text / number / date | enum은 미채택(추후 확장 가능) |
| 타깃 | 데스크톱 우선 (Windows/macOS/Linux) | 모바일은 추후 |
| 상태관리 | Riverpod | |
| 라이선스 | MIT | |

## 3. 아키텍처 (계층)

```
Presentation (Flutter Widgets)   화면: 폴더 트리, 파일 목록, 태그 패널, 필터바
State (Riverpod)                 상태/유즈케이스 연결
Domain (순수 Dart)               엔티티 + 비즈니스 규칙 + Repository 인터페이스
Data
  ├ FileSystem 스캐너 (dart:io)  디렉토리 순회, 변경 감지
  └ TagRepository (Drift/SQLite) 태그 영속화, 쿼리
```

저장 방식이 바뀌어도 Domain/UI가 영향받지 않도록 Repository 인터페이스로 격리.

## 4. 데이터 모델

```
TagDefinition            태그의 "종류" 정의
  id
  name                   예: 평점, 프로젝트, 검토완료
  valueType              label | text | number | date
  color                  UI 표시용

TagAssignment            특정 파일/폴더에 태그를 부여한 기록
  id
  targetId  ──► FileNode
  tagDefinitionId ──► TagDefinition
  value                  valueType에 맞는 값 (label이면 비어 있음)

FileNode                 스캔된 파일/폴더 1개 (인덱스 캐시)
  id
  path
  isDirectory
  size, modifiedAt
  contentHashPrefix      파일 이동 재연결용 부분 해시
  lastSeenAt             마지막 스캔에서 발견된 시각
```

- 라벨 태그와 키-값 태그를 `valueType` 하나로 통합 처리.
- 한 파일에 여러 태그 부여 가능 (N:M).
- 정렬 비교 로직은 valueType별로 다름(number=숫자, date=시간순, text=사전순).

## 5. 핵심 동작

- **스캔**: 루트 폴더 재귀 순회 → `FileNode` 인덱스 증분 갱신. `.filetagger/`는
  스캔 대상에서 제외.
- **이동 추적**: 경로로 못 찾은 태그는 (크기+수정시각+부분해시) 일치 신규 파일에
  재연결 제안.
- **태그 부여/편집**: 단일·다중 선택 일괄 태깅, 기존 태그 자동완성.
- **필터/정렬/탐색**: 태그 조합 쿼리, 태그값 기준 정렬, 태그별 모아보기(가상 폴더).

## 6. 로드맵

- Phase 0 — 작업 환경 구축
- Phase 1 — Drift/Riverpod 초기화, DB 위치 전략 구현
- Phase 2 — 디렉토리 스캔 + 파일/폴더 목록 표시
- Phase 3 — 태그 정의/부여(label/text/number/date) 영속화
- Phase 4 — 필터/정렬/태그별 모아보기
- Phase 5 — 파일 이동 추적, 폴더 실시간 감시

진행 상황은 [CLAUDE.md](../CLAUDE.md)에서 관리.
