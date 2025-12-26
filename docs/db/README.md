# DB/ERD & MySQL 설계 정리 (v1 기준)

> 이 문서는 `docs/db`에 포함된 **OTT 서비스 DB 설계(v1)** 를 기준으로
> v0 대비 보완된 제약/정책, 인증(Refresh Token) 저장 전략, 핵심 테이블 관계를 정리한 문서입니다.

## 참고 파일

* ERD 다이어그램(v0): `docs/db/ott-db-v0.png`
* 실행 가능한 DDL(v0): `docs/db/ott-db-v0-schema.sql`
* 실행 가능한 DDL(v1): `docs/db/ott-db-v1-schema.sql`
* 데모 시드 데이터(v0): `docs/db/ott-db-v0-seed.sql`
* 데모 시드 데이터(v1): `docs/db/ott-db-v1-seed.sql`
* (선택) ERD Cloud 원본 DDL: `docs/db/ott-db-v0-erdcloud.sql`
* API 문서(v1): `docs/api/ott-api-v1.md`

---

## 0. 전제

* DBMS: **MySQL**
* Storage Engine: **InnoDB**
* Charset/Collation: **utf8mb4 / utf8mb4_0900_ai_ci**
* 이 문서는 DDL을 그대로 나열하는 문서가 아니라, **“왜 이런 구조/타입/제약을 선택했는지”를 설명하기 위한 설계 노트**이다.
* v1은 v0의 1차 설계를 기반으로, **구현(Spring Boot + JPA) 전 단계에서 제약을 강화(정합성·무결성 보강)** 한 버전이다.

---

## 1. v1의 핵심 변경점(v0 → v1)

### 1-1. Refresh Token 서버 저장 테이블 추가

* v1에서는 Refresh Token 정책을 “로테이션 + 서버 저장 + 로그아웃 시 폐기”로 확정한다.
* DB에는 **원문 토큰을 저장하지 않고 해시(token_hash)만 저장**한다.
* 사용자별/기기별 세션 추적 및 폐기 처리를 위해 `refresh_tokens` 테이블을 추가한다.

핵심 컬럼 의도

* `token_hash`: 토큰 원문 저장 금지, 해시만 저장
* `expires_at`: 만료 시각(토큰 검증/정리 작업에 사용)
* `revoked_at`: 폐기 시각(로그아웃/탈취 의심 대응)
* `replaced_by_id`: 로테이션 체인 추적(선택)
* `user_agent`, `ip_address`: 디바이스/접속 환경 식별(선택)

---

### 1-2. watch_histories의 UNIQUE + NULL 문제를 DB 레벨에서 해결

v0에서는 `watch_histories`의 유니크 키가 `(profile_id, content_id, episode_id)`였고,
MySQL의 UNIQUE 인덱스에서 `NULL`은 서로 다른 값으로 취급될 수 있어 **영화(episode_id = NULL)** 케이스에서 중복 삽입이 가능해질 수 있었다.

v1에서는 이를 DB 레벨에서 제어하기 위해 아래 전략을 적용한다.

* `episode_key` 생성 컬럼을 추가하고 `episode_key = IFNULL(episode_id, 0)` 으로 저장한다.
* UNIQUE는 `(profile_id, content_id, episode_key)`로 걸어 영화(episode_key=0)는 **프로필+작품당 1개만 유지**되도록 강제한다.

---

### 1-3. 데이터 정합성을 위한 CHECK 제약 추가(하드닝)

v1에서는 “서비스 로직으로 충분히 막을 수 있는 값”이라도 DB 레벨에서 기본적인 정합성을 보장하기 위해 CHECK 제약을 추가한다.

* `promo_codes.discount_value`

  * PERCENT: 0~100
  * AMOUNT: 0 이상
  * FREE_TRIAL: 1 이상
* `watch_histories`

  * `duration_sec > 0`
  * `0 <= progress_sec <= duration_sec`
* `watch_sessions`

  * `ended_at`이 존재하면 `ended_at >= started_at`
  * `watched_sec >= 0`
* `reviews.rating`

  * `0.0 <= rating <= 5.0`

---

## 2. ERD 전체 관계(요약)

* **users(계정)** 1 ─ N **profiles(프로필)**
* **profiles** 1 ─ 1 **profile_settings**, **subtitle_style**
* **users** N ─ M **terms(약관)** (중간: **user_terms_agreement**)
* **users** 1 ─ N **refresh_tokens** (v1 추가)
* **contents(작품)** 1 ─ N **seasons** 1 ─ N **episodes**
* **contents** N ─ M **genres** (중간: **content_genres**)
* **contents** N ─ M **people** (중간: **content_people**)
* **profiles** N ─ M **contents** (사용자 행동 데이터)

  * 찜: **wishlists**
  * 시청기록 요약(이어보기): **watch_histories**
  * 시청 세션 로그: **watch_sessions**
  * 리뷰: **reviews**
  * 추천 제외: **content_blocks**
* **users** 1 ─ N **subscriptions** N ─ 1 **plans**
* **subscriptions** 1 ─ N **payments** (promo_codes optional)
* **Watch Party(Phase2)**: **watch_party_rooms / watch_party_members / watch_party_messages**

  * v1 schema에도 확장 대비로 포함되어 있으며, 기능 구현은 Phase2 목표로 둔다.

---

## 3. MySQL 타입/설계 규칙(프로젝트 합의)

### 3-1. 정수 타입 & UNSIGNED

* PK, 금액, 시청시간(초), 카운트성 값은 음수가 없으므로 보통 `UNSIGNED`로 설계한다.
* 자주 쓰는 타입

  * `TINYINT`(1 byte), `SMALLINT`(2 byte), `INT`(4 byte), `BIGINT`(8 byte)

### 3-2. BOOLEAN vs TINYINT(1)

* MySQL에서 `BOOLEAN/BOOL`은 실제로 `TINYINT(1)`의 별칭이다.
* 프로젝트 내 일관성을 위해 BOOLEAN 표현을 사용한다.

### 3-3. ENUM

* 값이 적고 고정된 컬럼은 ENUM을 사용해 오타/이상값을 DB 레벨에서 방지한다.
* 예: provider(KAKAO/GOOGLE/NAVER), 콘텐츠 type(MOVIE/SERIES), 결제 method, age_rating, device_type 등
* 이식성이 중요하면 코드테이블을 선호할 수도 있으나, 본 프로젝트에서는 설계 명확성/제약 강화를 우선한다.

### 3-4. DATETIME(3), YEAR, CHAR(7), DECIMAL(2,1)

* `DATETIME(3)`: 밀리초까지 기록
* `YEAR`: 공개/개봉 연도
* `CHAR(7)`: HEX 색상 코드(`#FFFFFF`)
* `DECIMAL(2,1)`: 별점(0.0~5.0)

---

## 4. 보안/정책 관련 설계 의도

### 4-1. 비밀번호 및 PIN 저장 정책

* 비밀번호는 평문 저장 금지이며 DB에는 `password_hash`만 저장한다.
* 프로필 PIN도 평문 저장 금지이며 `pin_hash`로 저장한다.
* 구현에서는 bcrypt/Argon2 등 해시 알고리즘 사용을 전제로 한다.

### 4-2. Refresh Token 저장 정책(v1)

* Refresh Token은 서버 저장 방식으로 운영한다.
* DB에는 토큰 원문을 저장하지 않고 `token_hash`만 저장한다.
* 로그아웃 시 `revoked_at`을 기록해 즉시 폐기한다.
* 로테이션 적용 시 `replaced_by_id`로 체인을 추적할 수 있다(선택).

### 4-3. created_at / updated_at

* 계정/구독/리뷰 등 핵심 테이블에는 생성/수정 시간을 포함한다.
* 정렬, 통계, 기간 조회, 디버깅, 운영/관리 확장에 유용하다.

---

## 5. watch_histories & watch_sessions 설계 의도(v1 기준)

### 5-1. 영화/시리즈 통합과 episode_id 처리

* 영화/시리즈를 하나의 흐름으로 다루기 위해 `episode_id`는 NULL 가능하다.

  * 영화: `episode_id = NULL`
  * 시리즈: 실제 `episodes.episode_id`

### 5-2. watch_histories(이어보기 / 최신 시청 상태)

* 프로필 + 작품(+회차) 기준으로 “최신 상태”를 유지하는 용도다.
* 홈의 “이어보기”, 진행률 표시, 시청목록 노출/숨김 처리에 사용한다.
* v1에서는 영화 중복 문제를 해결하기 위해 `episode_key`를 도입하고 UNIQUE를 `(profile_id, content_id, episode_key)`로 강제한다.
* 인덱스

  * `INDEX(profile_id, is_hidden, last_watched_at)`로 최근 본 순/노출 목록 조회 최적화

### 5-3. watch_sessions(시청 세션 로그)

* 시청할 때마다 세션 단위로 누적 기록하는 로그 테이블이다.
* 통계/분석(디바이스/기간/세션 수) 및 “리뷰 작성 조건(예: 30% 이상 시청)” 검증 근거로 사용한다.
* 인덱스

  * `INDEX(profile_id, started_at)`로 프로필별 시청 이력 시간순 조회 최적화
* v1에서는 시간/값 정합성을 위해 CHECK 제약을 추가한다.

---

## 6. FK 삭제 규칙(추천)

* users → (profiles, subscriptions, social_accounts, user_terms_agreement, refresh_tokens): **ON DELETE RESTRICT**

  * 유저는 소프트 삭제가 기본이라 물리 삭제를 거의 하지 않는다는 가정이다.

* profiles → (profile_settings, subtitle_style, wishlists, watch_histories, watch_sessions, reviews, content_blocks, watch_party_*): **ON DELETE CASCADE**

  * 프로필 삭제 시 해당 프로필에 종속된 데이터가 함께 정리되는 것이 자연스럽다는 가정이다.

---

## 7. 타임존 가정

* 운영 기준으로는 DB 저장은 **UTC**를 권장한다.
* 로컬 개발/데모 seed 실행 환경에 따라 `SET time_zone`이 다를 수 있으며, 클라이언트 표시는 사용자 로컬 타임존(KST 등)으로 변환한다.

---

## 8. 실행 순서(권장)

### 8-1. 스키마 적용(v1)

1. `docs/db/ott-db-v1-schema.sql` 실행(스키마 생성)

```bash
# (선택) DB 생성
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS ott_service DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_0900_ai_ci;"

# 스키마 적용 (v1)
mysql -u root -p ott_service < docs/db/ott-db-v1-schema.sql
```

> DB 생성/USE는 SQL 파일에 넣지 않고 실행 커맨드에서 통제한다.
> `-p` 옵션은 비밀번호를 프롬프트로 입력받는 방식이며, `-pPASSWORD` 형태로 직접 붙여 쓰는 것은 피한다.

---

### 8-2. 데모/검증용 Seed 적용(카탈로그 전용, public-safe)

본 프로젝트의 seed는 GitHub 공개를 전제로 **catalog-only** 데이터를 넣는다.

* 포함: plans/terms/genres/contents/seasons/episodes/people 및 매핑
* 미포함: users/profiles/subscriptions/payments/watch/review 등 사용자 데이터

> 보통은 v1 스키마 기준으로 `ott-db-v1-seed.sql`을 사용하며, `ott-db-v0-seed.sql`은 v0 스키마 재현/비교용으로 유지한다.

#### (A) v0 seed: 최소 카탈로그 seed (고정 PK 기반)

* 파일: `docs/db/ott-db-v0-seed.sql`
* 특징:

  * `plan_id`, `genre_id`, `content_id` 등을 **고정값으로 명시**해 관계를 단순하게 검증하기 좋다.
  * 실행 전제: v0 스키마(`ott-db-v0-schema.sql`) 기준

```bash
mysql -u root -p ott_service < docs/db/ott-db-v0-seed.sql
```

> v0 seed는 파일 내부에 `USE ott_service;`가 포함되어 있어 DB명이 다르면 수정이 필요하다.

#### (B) v1 seed: v1 스키마용 카탈로그 seed (재실행 안전)

* 파일: `docs/db/ott-db-v1-seed.sql`
* 특징:

  * 재실행 안전성: `ON DUPLICATE KEY UPDATE`, `INSERT IGNORE`, `NOT EXISTS` 기반
  * v1에서 추가된 제약(CHECK 등) 및 테이블 구조 기준으로 카탈로그/예시 데이터를 빠르게 구성

```bash
mysql -u root -p ott_service < docs/db/ott-db-v1-seed.sql
```

---

### 8-3. 간단 검증(예시)

* 테이블 생성 확인: `SHOW TABLES;`
* DDL 확인: `SHOW CREATE TABLE watch_histories;`
* 카탈로그 관계 확인: 콘텐츠/장르/인물/시즌/에피소드 매핑이 정상 조회되는지 확인

---

## 9. Troubleshooting / 시행착오 기록

### 9-1. ERROR 1064 (SQL syntax error)

* 원인: MySQL 클라이언트(`mysql>` 프롬프트) 내부에서 `< file.sql` 리다이렉션 명령을 실행하려고 해서 발생
* 해결:

  * `mysql -u root -p dbname < file.sql` 은 **OS 터미널(CMD/PowerShell/Git Bash)** 에서 실행해야 한다.

---

### 9-2. ERROR 1826 (Duplicate foreign key constraint name)

* 원인:

  * MySQL은 **스키마(DB) 전체에서 FK constraint name이 유일**해야 한다.
  * 여러 테이블에서 동일한 FK 이름을 재사용하면 충돌한다. (예: `fk_wpm_profiles`, `fk_wpm_rooms` 등)
* 해결:

  * FK 이름에 **테이블명을 포함**하도록 규칙화했다.
  * 적용 규칙: `fk_{table}_{reference}`

---

### 9-3. ERROR 1215 (Cannot add foreign key constraint)

* 원인 후보:

  1. 참조 대상 컬럼과 타입/UNSIGNED 여부 불일치
  2. 참조 대상 컬럼에 PK 또는 UNIQUE 인덱스가 없음
  3. 참조 테이블 생성 이전에 FK를 추가함
  4. NULL 허용 여부 / ON DELETE 규칙 불일치
* 실제 처리(v1):

  * `watch_histories.episode_id`는 영화/시리즈 통합 모델 때문에 NULL 허용이며,
  * `episode_key`(GENERATED COLUMN) + FK 분리 추가(ALTER) 조합에서 FK 생성 시점 충돌 가능성이 커,
  * v1에서는 `watch_histories → episodes` FK를 제거하고 애플리케이션 로직에서 무결성을 보장한다.
* 근거:

  * 영화(MOVIE)는 episode가 없고, 시리즈(SERIES)만 episode가 존재하는 “혼합 모델”을 단순하게 유지하기 위함이다.
  * “watch_histories는 ‘이어보기 요약’ 테이블이라, 영화/시리즈 통합 모델에서 episode FK 강제보다 중복 방지(episode_key)와 조회 성능을 우선했다.”

---

### 9-4. 검증 결과

* MySQL 8.0.44 환경에서 스키마가 정상 실행됨을 확인했다.

---

## 10. 다음 단계(구현 메모)

* DB(v1)와 API(v1) 계약을 기준으로, 이후 단계에서는 **Spring Boot 기반 백엔드 구현**을 진행한다.
* 본 문서는 DB/ERD 설계 범위까지만을 다루며, 구현 상세는 백엔드 코드 및 API 문서에서 다룬다.

