# DB/ERD & MySQL 설계 정리 (v0 기준)

> 이 문서는 `docs/db`에 포함된 **OTT 서비스 DB 1차 설계(v0)** 를 기준으로  
> 설계 의도, MySQL 타입/제약 선택 이유, 핵심 테이블 관계를 정리한 문서입니다.

## 참고 파일

- ERD 다이어그램: `docs/db/ott-db-v0.png`
- 실행 가능한 DDL: `docs/db/ott-db-v0-schema.sql`
- 데모 시드 데이터: `docs/db/ott-db-v0-seed.sql`
- (선택) ERD Cloud 원본 DDL: `docs/db/ott-db-v0-erdcloud.sql`
- API 문서(v1): `docs/api/ott-api-v1.md`

---

## 0. 전제

- DBMS: **MySQL**
- ERD 도구: **ERD Cloud**
- 이 문서는 DDL을 그대로 나열하는 문서가 아니라,
  **“왜 이런 구조/타입/제약을 선택했는지”를 설명하기 위한 설계 노트**이다.
- v0는 설계/학습/포트폴리오 목적의 1차안이며,
  실제 구현(Spring Boot + JPA) 과정에서 v1, v2로 보완될 수 있다.

---

## 1. ERD Cloud에서 쓰는 규칙

### 1-1. 테이블/컬럼 이름 (Logical vs Physical)

- **Physical Name(물리명)**
  - 실제 MySQL에 생성될 이름(영어, snake_case)
  - 예: `users`, `profiles`, `watch_histories`, `user_id`, `created_at`

- **Logical Name(논리명)**
  - 설계/문서용 한글 이름(사람이 읽기 쉽게)
  - 예:
    - 테이블: `users` → 회원/계정
    - 컬럼: `user_id` → 회원 고유 ID

- ERD Cloud 사용 방식
  - **왼쪽**: Logical(한글)
  - **오른쪽**: Physical(MySQL 실제 컬럼명)
  - comment(코멘트)에 UNIQUE/INDEX/FK 등 제약 설명을 적어 둔다.

### 1-2. PK / FK / NOT NULL / DEFAULT / 제약 입력

- **PK**
  - ERD Cloud에서 Key 체크 시 NOT NULL이 자동 반영되지만,
    설계상 혼동을 줄이기 위해 **NOT NULL도 함께 체크**하는 편.

- **FK**
  - Foreign Key 항목에 참조 테이블/컬럼을 지정한다.
  - v0에서는 “영화/시리즈 통합”을 위해 `episode_id`가 NULL이 될 수 있으며,
    이 경우 FK는 `ON DELETE SET NULL`로 처리하는 테이블이 존재한다
    (예: `watch_histories.episode_id`, `watch_sessions.episode_id`, `watch_party_rooms.episode_id`).

- **UNIQUE / INDEX**
  - ERD Cloud 무료 플랜에서는 제약을 모두 아이콘으로 표현하기 어렵기 때문에,
    UNIQUE/복합 UNIQUE/INDEX는 **comment로 메모**해 둔다.

- **DEFAULT & ON UPDATE**
  - DEFAULT 값은 Default 칸에 입력:
    - `CURRENT_TIMESTAMP(3)`, `0`, `1`, `TRUE`, `FALSE` 등
  - `ON UPDATE CURRENT_TIMESTAMP(3)`는 Default 칸에 문자열로 기록하는 방식으로 표현.

---

## 2. ERD 전체 관계(요약)

- **users(계정)** 1 ─ N **profiles(프로필)**
- **profiles** 1 ─ 1 **profile_settings**, **subtitle_style**
- **users** N ─ M **terms(약관)** (중간: **user_terms_agreement**)
- **contents(작품)** 1 ─ N **seasons** 1 ─ N **episodes**
- **contents** N ─ M **genres** (중간: **content_genres**)
- **contents** N ─ M **people** (중간: **content_people**)
- **profiles** N ─ M **contents** (사용자 행동 데이터)
  - 찜: **wishlists**
  - 시청기록 요약(이어보기): **watch_histories**
  - 시청 세션 로그: **watch_sessions**
  - 리뷰: **reviews**
  - 추천 제외: **content_blocks**
- **users** 1 ─ N **subscriptions** N ─ 1 **plans**
- **subscriptions** 1 ─ N **payments** (promo_codes optional)
- **Watch Party(Phase2)**: **watch_party_rooms / watch_party_members / watch_party_messages**
  - v0 schema에는 “확장 대비”로 테이블이 포함되어 있으며,
    기능 구현은 Phase2에서 진행하는 것을 목표로 한다.

---

## 3. MySQL 타입 관련 합의/공부 내용

### 3-1. 정수 타입 & UNSIGNED

- 자주 쓰는 정수 타입
  - `TINYINT`(1 byte), `SMALLINT`(2 byte), `INT`(4 byte), `BIGINT`(8 byte)
- **UNSIGNED**
  - 음수 없이 0부터 시작하는 타입.
  - PK, 금액, 시청시간(초), 카운트성 값은 보통 UNSIGNED로 설계.
- 괄호 표기(`TINYINT(1)`)는 표시 폭(display width)이라 범위에 영향 없음.

### 3-2. BOOLEAN vs TINYINT(1)

- MySQL에서 `BOOLEAN/BOOL`은 실제로 `TINYINT(1)`의 별칭.
- 결론:
  - 어느 쪽이든 가능하지만,
    **프로젝트 내 스타일을 통일하는 것이 더 중요**하다.
  - v0에서는 가독성 측면에서 BOOLEAN 표현을 사용한다.

### 3-3. ENUM

- 값이 적고 고정된 컬럼에서 오타/이상값을 DB 레벨에서 막기 위해 사용한다.
- 예:
  - provider(KAKAO/GOOGLE/NAVER), 콘텐츠 type(MOVIE/SERIES), 결제 method, age_rating, device_type 등
- 이식성이 중요하면 코드테이블(VARCHAR + master table) 선호가 있을 수 있다는 점은 인지한다.

### 3-4. YEAR, DATETIME(3), CHAR(7), DECIMAL

- YEAR: `release_year YEAR`
- DATETIME(3): 밀리초까지 기록
  - `created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)`
  - `updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)`
- CHAR(7): HEX 색상 코드 `#FFFFFF`
- DECIMAL(2,1): 별점(0.0~5.0) 등 소수점 1자리 평점에 사용

---

## 4. 보안/설계 관련 개념들

### 4-1. password_hash

- 비밀번호는 평문 저장 금지.
- DB에는 `password_hash`만 저장한다.
- 실제 구현에서는 bcrypt/Argon2 등 사용을 전제로 한다.

### 4-2. created_at / updated_at

- 레코드 생성/수정 시점을 추적한다.
- 정렬, 통계, 기간 조회, 디버깅, 운영/관리 확장에 유용하다.
- 핵심 테이블(계정/구독/리뷰 등)에는 기본적으로 포함하는 방향이다.

### 4-3. avatar_code

- 프로필 이미지 자체(URL)를 저장하기보다,
  프리셋 키(`DEFAULT_1`, `CAT_1` 등)를 저장하고 프론트에서 매핑한다.
- 리소스 교체 시 DB 수정 없이 프론트/설정 변경으로 대응 가능하다.

---

## 5. watch_histories & watch_sessions 설계 의도

### 5-1. 영화/시리즈 통합과 episode_id 처리(v0)

- v0에서는 영화/시리즈를 하나의 흐름으로 다루기 위해,
  `watch_histories.episode_id`, `watch_sessions.episode_id`가 **NULL이 될 수 있게 설계**한다.
  - 영화: `episode_id = NULL`
  - 시리즈: 실제 `episodes.episode_id`

### 5-2. watch_histories (이어보기 / 최신 시청 상태)

- 프로필 + 작품(+회차) 기준으로 “최신 상태”를 유지하는 용도다.
- 핵심 역할
  - 이어보기
  - 진행률 표시
  - 시청목록 노출/숨김 처리
- v0 제약/인덱스
  - `UNIQUE(profile_id, content_id, episode_id)`
  - `INDEX(profile_id, is_hidden, last_watched_at)`로 최근 본 순/노출 목록 조회 최적화

중요 메모(UNIQUE + NULL)
- MySQL에서 UNIQUE 인덱스는 NULL을 서로 다른 값으로 취급할 수 있어,
  `episode_id IS NULL`인 행(영화)은 (profile_id, content_id)가 같아도 중복 삽입이 가능해질 수 있다.
- v0에서는 이를 서비스 로직에서 “영화는 1개만 유지(갱신/업서트)”로 관리하는 것을 전제로 한다.

향후 개선안(v1 후보)
- 영화용 `episode_id`를 0 특수값으로 통일하여 DB 레벨에서 유니크 강제
- 또는 생성 컬럼/유니크 키 보강 등으로 “NULL 케이스”를 DB에서 제어

### 5-3. watch_sessions (시청 세션 로그)

- 시청할 때마다 **세션 단위로 누적 기록**하는 로그 테이블이다.
- 역할
  - 통계/분석(디바이스/기간/세션 수)
  - “리뷰 작성 조건(예: 30% 이상 시청)”의 근거 데이터
- v0 포인트
  - `INDEX(profile_id, started_at)`로 프로필별 시청 이력 시간순 조회 최적화
  - `episode_id`는 NULL 가능(영화 케이스)
  - FK는 `CASCADE`와 `SET NULL` 조합으로 정합성을 유지한다.

---

## 6. FK 삭제 규칙(추천 메모)

- users → (profiles, subscriptions, social_accounts, user_terms_agreement): **ON DELETE RESTRICT**
  - 유저는 소프트 삭제가 기본이라 물리 삭제를 거의 하지 않는다는 가정이다.

- profiles → (profile_settings, subtitle_style, wishlists, watch_histories, watch_sessions, reviews, content_blocks, watch_party_*):
  **ON DELETE CASCADE**
  - 프로필 삭제 시 해당 프로필에 종속된 데이터가 함께 정리되는 것이 자연스럽다는 가정이다.

---

## 7. 타임존 가정

- 모든 `DATETIME(3)` 컬럼은 DB에는 **UTC 기준 저장**을 가정한다.
- 클라이언트 표시는 사용자 로컬 타임존(KST 등)으로 변환한다.

---

## 8. 데모 실행 순서(권장)

1) `ott-db-v0-schema.sql` 실행(스키마 생성)
2) `ott-db-v0-seed.sql` 실행(데모 데이터 삽입)
3) 간단 검증
   - 프로필/작품/찜/시청기록/리뷰/구독/결제/워치파티 관계가 정상적으로 조회되는지 확인한다.

