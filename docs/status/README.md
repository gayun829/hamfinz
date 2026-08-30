# 작업 상태 메모

기능 하나를 진행하는 동안 "지금 뭐가 됐고 뭐가 안 됐는지"를 적어두는 곳이다.
각자 작업하는 걸 마크다운으로 최신화해두면, 복잡해져도 서로 작업이 안 꼬인다.

[database/backend-schema.md](../database/backend-schema.md) · [database-schema.md](../database/database-schema.md)와 역할이 다르다 — 여기엔 스키마·설계 내용을 적지 않는다.

| 여기 (`status/`) | `database/` |
|---|---|
| 브랜치, 커밋, PR, 배포 여부, 남은 할 일 | 컬렉션 구조, 필드, Security Rules |
| "지금 어디까지 됐나" | "무엇을 만들기로 했나" |

## 규칙

- 파일명: `<기능-슬러그>.md` (예: `friends.md`, `news-bookmark.md`)
- 작업 중인 사람이 직접 최신화한다 — 남이 대신 갱신하지 않는다.
- 스키마·설계 결정은 [backend-schema.md](../database/backend-schema.md)에 적고, 여기엔 링크만 남긴다.
- PR이 merge되면 파일을 지운다(또는 "완료"만 남기고 정리한다) — 여기는 진행 중 상태만 담는 곳, 완료된 기능의 영구 문서가 아니다.
- 개인적인 조사·실험 메모는 `.local/`(gitignore)에 — 여기는 팀이 보는 곳이다.
