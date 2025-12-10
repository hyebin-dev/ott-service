# DB/ERD & MySQL 설계 정리 (v0 기준)

> 이 문서는 `docs/db/ott-db-v0.{png,sql}` 를 바탕으로  
> OTT 서비스 DB 설계 의도와 MySQL 타입/제약 선택 이유를 정리한 노트입니다.  
> ERD 그림은 `ott-db-v0.png`, MySQL 스키마는 `ott-db-v0.sql` 파일을 참고합니다.

---

## 0. 전제

* DB: **MySQL** 기준으로 설계.
* ERD 도구: **ERD Cloud** 사용.
* 이미 테이블/컬럼 구조는 `ott-db-v0.sql` 스키마(예: `users`, `profiles`, `contents`, `watch_histories`, `watch_sessions` 등)로 1차 확정되어 있고,  
  이 문서는 **그 설계를 이해하고 설명할 수 있게 도와주는 메모/원칙 정리본**이다.

---

## 1. ERD Cloud에서 쓰는 규칙

### 1-1. 테이블/컬럼 이름 (Logical vs Physical)

* **Physical Name(물리명)**  
  * 실제 MySQL에 생성될 이름 (영어, snake_case).
  * 예: `users`, `profiles`, `watch_histories`, `user_id`, `profile_id`, `created_at` 등.

* **Logical Name(논리명)**  
  * 설계/문서용 “한글 이름”. 사람이 알아보기 쉽게 쓰는 이름.
  * 예:
    * 테이블: `users` → 논리명: `회원/계정`
    * 컬럼: `user_id` → 논리명: `회원 고유 ID`

* ERD Cloud 사용 방식:
  * **왼쪽**: Logical (한글)
  * **오른쪽**: Physical (실제 컬럼명)
  * comment(코멘트)에 제약 설명(UNIQUE/INDEX/FK 특이사항)을 적어둔다.

### 1-2. PK / FK / NOT NULL / DEFAULT / 제약 입력

* **PK**
  * ERD Cloud에서 “Key” 체크 → 자동으로 NOT NULL 개념.
  * 그래도 설계상 헷갈리지 않게 하려고 **NOT NULL도 같이 체크**하는 편.

* **FK**
  * “Foreign Key” 항목에 참조 테이블/컬럼을 지정.
  * 단, `episodes` 등과 연계해서 `episode_id = 0` 을 특수값으로 쓰는 경우:
    * 영화용 `0` 때문에 **실제 FK 제약은 안 걸고**
    * comment에 `영화는 episode_id=0(특수값, FK 미적용)`이라고 적어둔다.

* **UNIQUE / INDEX**
  * ERD Cloud 무료 플랜에서는 아이콘/제약으로 다 표현하기 어려워서,
    * UNIQUE, 복합 UNIQUE, 일반 INDEX는 **comment로 메모**해 둔다.
    * 예:
      * `email` comment: `UNIQUE (로그인 아이디 중복 방지)`
      * `UNIQUE(profile_id, content_id, episode_id)` 등.

* **DEFAULT & ON UPDATE**
  * DEFAULT 값은 `Default` 칸에 입력:
    * `CURRENT_TIMESTAMP(3)`
    * `0`, `1`, `'DEFAULT_1'`, `TRUE`, `FALSE` 등.
  * `ON UPDATE CURRENT_TIMESTAMP(3)`는
    * `Default` 칸에
      * `CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)`
    * 이런 식으로 **문자 그대로** 적어두는 방식으로 표현.

---

## 2. MySQL 타입 관련 합의/공부 내용

### 2-1. 정수 타입 & UNSIGNED

* 자주 쓰는 정수 타입:
  * `TINYINT` (1 byte) → -128 ~ 127 / UNSIGNED 0 ~ 255
  * `SMALLINT` (2 byte)
  * `INT` (4 byte)
  * `BIGINT` (8 byte)

* **UNSIGNED**: 음수 없이 0부터 시작하는 타입.
  * 예: `BIGINT UNSIGNED` PK → 아주 큰 ID 범위 커버.
  * 금액, 시청시간, 카운트 값 등은 보통 **UNSIGNED**로 설계.

* 괄호(`TINYINT(1)`) 안 숫자는 **표시 폭(display width)** 개념이라  
  타입 범위에 영향 없음. (`TINYINT` == `TINYINT(1)` 같은 범위)

### 2-2. BOOLEAN vs TINYINT(1)

* MySQL에서 `BOOLEAN` / `BOOL`은 **실제론 `TINYINT(1)`의 별칭**.
* 따라서 아래 둘은 동작상 거의 같다.
  * `is_active BOOLEAN`
  * `is_active TINYINT(1)`

* 실무/포폴 분위기:
  * 옛 스타일/레거시/DBA 선호:  
    → `TINYINT(1) NOT NULL DEFAULT 0/1`
  * 요즘/가독성/ORM 스타일:  
    → `BOOLEAN NOT NULL DEFAULT TRUE/FALSE`

* 결론:
  * **어느 쪽이든 상관없고, 한 프로젝트 안에서 스타일만 통일하면 된다.**
  * 이 프로젝트에서는 처음엔 `TINYINT(1)`로 설계했다가, `BOOLEAN`도 써볼까 고민한 상태.
  * “둘이 실질적으로 동등하다”는 걸 이해하고 있다는 게 포인트.

### 2-3. ENUM

* `ENUM('KAKAO', 'GOOGLE', 'NAVER')` 같은 타입:
  * **특정한 문자열 값만 허용하는 MySQL 전용 타입**.
  * 오타, 이상한 값 저장을 DB 레벨에서 막을 수 있음.

* 사용 위치 예:
  * `gender`, `status`, `type(MOVIE/SERIES)`, `method(결제수단)`,
    `role_detail(ACTOR/DIRECTOR/PRODUCER)`, `device_type`, `age_rating` 등.

* 실무에서는:
  * MySQL 기반 서비스에서는 **많이 쓰이는 편**.
  * 다만 DB 이식성을 중시하는 팀은 `VARCHAR + 코드테이블`을 선호하기도 함.

* 이 프로젝트에서는:
  * 값이 적고 고정된 컬럼에만 ENUM 사용 → **충분히 설득 가능한 설계**.

### 2-4. YEAR, DATETIME(3), CHAR(7), DECIMAL

* **YEAR**
  * `release_year YEAR` 사용.
  * 실무에서는 `SMALLINT UNSIGNED` 등을 쓰는 팀도 있지만,
  * 이 프로젝트에서 YEAR 사용은 타당.

* **DATETIME(3) + CURRENT_TIMESTAMP(3)**
  * 밀리초까지 기록.
  * 패턴:
    * `created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)`
    * `updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)`

* **CHAR(7) for 색상 코드**
  * `'#FFFFFF'` 같은 HEX 색상(7글자)을 저장.
  * `CHAR(7) NOT NULL DEFAULT '#FFFFFF'` → 흔히 쓰는 패턴.

* **DECIMAL(2,1) for rating**
  * `0.0 ~ 9.9` 범위 표현 가능.
  * OTT 별점(0.0~5.0)에는 충분한 범위.
  * 실무에서도 rating 컬럼에 `DECIMAL(2,1)` 또는 `DECIMAL(3,1)` 자주 사용.

---

## 3. 보안/설계 관련 개념들

### 3-1. password vs password_hash, 해시(hash)

* **password**: 사용자가 입력하는 실제 비밀번호 (평문).
* **password_hash**:
  * 비밀번호를 **해시 함수(단방향 함수)**로 변환한 결과.
  * 예: bcrypt, Argon2 등.

* 이유:
  * DB가 털려도 실제 비밀번호를 바로 볼 수 없게 하기 위해  
    **평문을 저장하지 않고, 해시만 저장**하는 것이 보안 상 기본 원칙.

* 그래서 `users` 테이블에서는:
  * `password` 대신 **`password_hash` 컬럼**을 두는 설계를 선택했다.

### 3-2. created_at / updated_at 용도

* 용도:
  * 레코드가 언제 만들어졌는지, 언제 마지막으로 수정됐는지 추적.
  * 통계, 정렬, 기간 조회, 디버깅(“이 문제 언제부터 발생했지?”) 등에 필수.
  * 나중에 관리자/운영 페이지를 만든다면 거의 무조건 쓰이게 되는 컬럼.

* OTT 프로젝트에서도:
  * `users`, `profiles`, `contents`, 로그 테이블 등 거의 전 테이블에  
    `created_at`, 필요 시 `updated_at`을 두는 방향으로 설계했다.

### 3-3. avatar_code 의 의미

* 예: `avatar_code VARCHAR(30) NOT NULL DEFAULT 'DEFAULT_1'`

* 역할:
  * 프로필 이미지에 대응되는 **프리셋/리소스 키 값**을 저장.
  * 실제 이미지 URL이나 파일명 대신,
    * `'DEFAULT_1'`, `'CAT_1'` 같은 코드만 DB에 저장하고
    * 프론트에서 이 코드를 보고 실제 이미지를 매핑한다.

* 장점:
  * 이미지 리소스를 바꿔도 DB 수정 없이  
    프론트 코드/설정만 바꾸면 된다.

---

## 4. watch_histories & watch_sessions 설계 의도

### 4-1. watch_histories (최신 진행률/이어보기)

* 한 줄에 **프로필 + 작품(+회차)** 기준으로 **최신 상태 1개만 유지**.
* 핵심 역할:
  * “어디까지 봤는지” / “이어보기” / “시청목록 노출 여부” 관리.

* 특징:
  * `UNIQUE(profile_id, content_id, episode_id)`
    * 영화: `episode_id = 0` (특수값, FK 안 걸고 comment로 설명)
    * 시리즈: 실제 `episode_id` 저장.
  * `is_hidden`으로 “시청 기록 숨기기” 구현.
  * `last_watched_at` 기준 정렬로 최근 본 순 정렬.

### 4-2. watch_sessions (시청 세션 로그)

* **매 시청 세션마다 한 줄**씩 쌓이는 로그 테이블.
  * 어제 1시간 보고, 오늘 30분 보면 세션 2줄.

* 역할:
  * 통계/분석/이벤트 리스트:
    * “하루에 몇 번 재생했는지”
    * “어떤 디바이스에서 얼마나 봤는지”
    * “리뷰 작성 조건(30% 이상 시청)이 충족되는지” 계산 근거.

* 설계 포인트:
  * `session_id` PK
  * `profile_id`, `content_id` FK
  * `episode_id`는 영화=0 / 시리즈=실제 episode_id  
    → 이 컬럼도 FK는 실제로 안 걸고 “0은 영화용 특수값”이라고 메모.
  * `started_at`, `ended_at`, `watched_sec`, `device_type`
  * `INDEX(profile_id, started_at)` 로  
    프로필별 시청 이력을 시간순 조회 최적화.

