# OTT API v1 명세서 (수정본, v1 freeze 초안)

## Changelog

### 2025-12-31

* DB schema(v1) 기준으로 API 필드/정책 통일
* Watch History 필드명 매핑 규칙 명시

  * API: `last_position_sec`, `total_duration_sec`
  * DB: `watch_histories.progress_sec`, `watch_histories.duration_sec`
* Contents 이미지 URL 정책 명시

  * v1에서는 `thumbnail_url`은 `poster_url`과 동일 값 사용 가능
* `max_age_rating`의 출처/타입 명시

  * `profile_settings.max_age_rating` 값 사용 (`ALL|7|12|15|19`)
* `my_state.my_rating` 정책 명시

  * v1에서 별점은 리뷰의 `rating`과 동일(리뷰 없는 별점 단독 저장은 v2)
* Contents synopsis 필드 정책 명시

  * DB 구조와 통일: `synopsis_short`, `synopsis_long`

### 2025-12-23

* API v1 초안 정리 및 규칙 확정
* 프로필 컨텍스트 전달 방식 `X-Profile-Id` 헤더 통일 정책 확정
* 시간 표기 규칙 ISO 8601 UTC(Z) 고정
* Refresh Token 정책 확정 (로테이션 + 서버 저장 + 로그아웃 시 폐기)
* 공통 HTTP Status 코드 매핑 기준 명확화
* 영화/시리즈 통합 `episode_id` 처리 규칙 확정

  * 영화: `episode_id = null`
  * 시리즈: 실제 `episode_id` 사용
* Base URL: `/api/v1`
* Request/Response: JSON (snake_case)
* Auth: `Authorization: Bearer {access_token}`
* Profile Context: `X-Profile-Id: {profile_id}`

---

## 0. 공통 규칙

### 0-1. 공통 응답 Envelope

성공:

```json
{
  "success": true,
  "data": {},
  "error": null
}
```

에러:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "PROFILE_LIMIT_EXCEEDED",
    "message": "프로필은 계정당 최대 5개까지 생성할 수 있습니다."
  }
}
```

* `code`: ENUM 스타일의 에러 코드(영문, SNAKE_CASE)
* `message`: 한글 메시지(클라이언트에 그대로 노출 가능)

---

### 0-2. 인증

```http
Authorization: Bearer {access_token}
```

* 로그인 후 발급되는 access_token을 사용한다.
* 예외: `POST /api/v1/auth/signup`, `POST /api/v1/auth/login`, `POST /api/v1/auth/refresh`는 토큰이 필요 없다.

---

### 0-3. 프로필 컨텍스트 (X-Profile-Id)

프로필 기준 API(찜/시청기록/리뷰 등):

```http
X-Profile-Id: {profile_id}
```

* 계정 토큰: “어떤 계정인가”
* `X-Profile-Id`: “그 계정 안에서 어떤 프로필 기준인가”
* 프로필 자체 관리 API(프로필 생성/수정/삭제/목록)는 `X-Profile-Id` 불필요

---

### 0-4. HTTP Status & Error Code 매핑

* `200 OK`: 성공(조회/처리)
* `201 Created`: 생성 성공
* `204 No Content`: 성공(응답 바디 없음)
* `400 Bad Request`: 요청 형식/검증 실패 (`VALIDATION_ERROR` 등)
* `401 Unauthorized`: 인증 실패/토큰 만료 (`UNAUTHORIZED`, `TOKEN_EXPIRED`)
* `403 Forbidden`: 정책 위반 (`PROFILE_LIMIT_EXCEEDED`, `WATCH_TIME_TOO_SHORT` 등)
* `404 Not Found`: 리소스 없음 (`USER_NOT_FOUND`, `CONTENT_NOT_FOUND` 등)
* `409 Conflict`: 중복/상태 충돌 (`EMAIL_ALREADY_IN_USE`, `ALREADY_REVIEWED`)
* `429 Too Many Requests`: 과도한 요청(선택)
* `500 Internal Server Error`: 서버 내부 오류 (`INTERNAL_ERROR`)

---

### 0-5. 시간/날짜 표기

* **DATETIME/TIMESTAMP 계열**: ISO 8601 UTC(Z) 문자열

  * 예: `"2025-12-10T12:34:56.789Z"`
* **DATE 계열**: `"YYYY-MM-DD"` 문자열

  * 예: `"2026-01-01"`

---

### 0-6. 영화/시리즈 통합 episode_id 규칙

* 영화: `episode_id = null`
* 시리즈: 실제 `episode_id` 사용

---

### 0-7. DB 매핑 규칙 (v1 고정)

* Watch Histories

  * API `last_position_sec` ↔ DB `watch_histories.progress_sec`
  * API `total_duration_sec` ↔ DB `watch_histories.duration_sec`
* Contents 이미지

  * v1에서는 `thumbnail_url`을 별도 컬럼으로 분리하지 않고, `thumbnail_url = poster_url`로 동일 값 사용 가능
* Rating(별점)

  * v1에서 별점은 리뷰의 `rating`과 동일(리뷰 없는 별점 단독 저장은 v2)
* Profiles 연령 제한

  * API의 `max_age_rating`은 `profile_settings.max_age_rating` 값 사용 (`ALL|7|12|15|19`)

---

## 1. Auth & Users

### 1-1. 회원가입 – `POST /api/v1/auth/signup`

#### Request Body

```json
{
  "email": "user@example.com",
  "password": "PlainPassword123!",
  "name": "김혜빈",
  "phone": "010-1234-5678",
  "birth_date": "2000-01-01",
  "gender": "NONE",
  "agreed_term_codes": ["AGE14", "SERVICE", "PRIVACY", "PAID"],
  "agreed_marketing": false
}
```

* `agreed_term_codes`: 필수 약관 코드 배열
* `agreed_marketing`: true면 `MARKETING` 동의도 함께 저장

#### Response (201)

```json
{
  "success": true,
  "data": {
    "user": {
      "user_id": 1,
      "email": "user@example.com",
      "name": "김혜빈",
      "status": "ACTIVE",
      "created_at": "2025-12-10T12:34:56.789Z"
    },
    "access_token": "JWT_ACCESS_TOKEN",
    "refresh_token": "JWT_REFRESH_TOKEN"
  },
  "error": null
}
```

---

### 1-2. 로그인 – `POST /api/v1/auth/login`

#### Request Body

```json
{
  "email": "user@example.com",
  "password": "PlainPassword123!"
}
```

#### Response (200)

```json
{
  "success": true,
  "data": {
    "user": {
      "user_id": 1,
      "email": "user@example.com",
      "name": "김혜빈"
    },
    "access_token": "JWT_ACCESS_TOKEN",
    "refresh_token": "JWT_REFRESH_TOKEN"
  },
  "error": null
}
```

---

### 1-3. 토큰 재발급 – `POST /api/v1/auth/refresh`

#### Request Body

```json
{
  "refresh_token": "JWT_REFRESH_TOKEN"
}
```

#### Response (200)

```json
{
  "success": true,
  "data": {
    "access_token": "NEW_ACCESS_TOKEN",
    "refresh_token": "NEW_REFRESH_TOKEN"
  },
  "error": null
}
```

---

### 1-4. 내 계정 정보 조회 – `GET /api/v1/users/me`

#### Response (200)

```json
{
  "success": true,
  "data": {
    "user_id": 1,
    "email": "user@example.com",
    "name": "김혜빈",
    "status": "ACTIVE",
    "current_plan": {
      "plan_id": 2,
      "name": "STANDARD",
      "price_monthly": 13500,
      "next_billing_date": "2026-01-01"
    },
    "created_at": "2025-12-01T10:00:00.000Z"
  },
  "error": null
}
```

* `next_billing_date`는 DATE이므로 `"YYYY-MM-DD"`

---

## 2. Profiles

### 2-1. 프로필 목록 조회 – `GET /api/v1/profiles`

#### Response (200)

```json
{
  "success": true,
  "data": {
    "profiles": [
      {
        "profile_id": 10,
        "name": "혜빈",
        "avatar_code": "DEFAULT_1",
        "is_kids": false,
        "pin_enabled": false,
        "max_age_rating": "ALL"
      }
    ],
    "max_profiles": 5
  },
  "error": null
}
```

* `max_age_rating`은 `profile_settings.max_age_rating` 값

---

### 2-2. 프로필 생성 – `POST /api/v1/profiles`

#### Request Body

```json
{
  "name": "새 프로필",
  "avatar_code": "DEFAULT_1",
  "is_kids": false,
  "pin": null,
  "max_age_rating": "19"
}
```

* 생성 시 서버는 `profile_settings` / `subtitle_style` 기본 row를 함께 생성한다(서비스 로직).

---

### 2-3. 프로필 수정 – `PATCH /api/v1/profiles/{profile_id}`

#### Request Body

```json
{
  "name": "수정된 이름",
  "avatar_code": "CAT_1",
  "max_age_rating": "12",
  "pin": "1234",
  "pin_enabled": true
}
```

* `name/avatar_code/is_kids/pin_enabled/pin` → profiles 반영
* `max_age_rating` → profile_settings 반영

---

## 3. Contents

### 3-1. 콘텐츠 목록 – `GET /api/v1/contents`

(변경 없음 — 기존 문서 유지)

---

### 3-2. 콘텐츠 상세 – `GET /api/v1/contents/{content_id}`

#### Response (200)

```json
{
  "success": true,
  "data": {
    "content_id": 100,
    "title_kr": "인터스텔라",
    "title_en": "Interstellar",
    "type": "MOVIE",
    "synopsis_short": "우주를 배경으로 한 SF 드라마...",
    "synopsis_long": null,
    "country": "미국",
    "age_rating": "12",
    "release_year": 2014,
    "runtime_min": 169,
    "genres": ["SF", "드라마"],
    "thumbnail_url": "https://example.com/interstellar.jpg",
    "poster_url": "https://example.com/interstellar.jpg",
    "backdrop_url": "https://example.com/interstellar-backdrop.jpg",
    "trailer_url": "https://example.com/interstellar-trailer.mp4",
    "cast": [
      { "person_id": 1, "name": "Matthew McConaughey", "role_detail": "ACTOR" }
    ],
    "crew": [
      { "person_id": 2, "name": "Christopher Nolan", "role_detail": "DIRECTOR" }
    ],
    "my_state": {
      "in_wishlist": true,
      "my_rating": 4.5,
      "my_review_id": 123,
      "last_watched_episode_id": null,
      "last_watched_position_sec": 3600
    }
  },
  "error": null
}
```

* `my_rating`은 v1에서 리뷰의 `rating`과 동일(리뷰 없으면 null)

---

## 4. Watch Histories & Sessions

### 4-1. 시청 기록 목록 – `GET /api/v1/watch-histories`

#### Request

```http
GET /api/v1/watch-histories
Authorization: Bearer {access_token}
X-Profile-Id: 10
```

#### Response (200)

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "content_id": 100,
        "episode_id": null,
        "title_kr": "인터스텔라",
        "type": "MOVIE",
        "thumbnail_url": "https://example.com/interstellar.jpg",
        "last_position_sec": 3600,
        "total_duration_sec": 6000,
        "progress_rate": 0.6,
        "is_hidden": false,
        "last_watched_at": "2025-12-10T12:00:00.000Z"
      }
    ]
  },
  "error": null
}
```

* 매핑: `last_position_sec` ↔ `progress_sec`, `total_duration_sec` ↔ `duration_sec`
* `progress_rate`는 서버에서 계산( `last_position_sec / total_duration_sec` )

---

### 4-2. 시청 기록 업데이트 – `PUT /api/v1/watch-histories`

#### Request

```http
PUT /api/v1/watch-histories
Authorization: Bearer {access_token}
X-Profile-Id: 10
```

#### Request Body

```json
{
  "content_id": 100,
  "episode_id": null,
  "last_position_sec": 4200,
  "total_duration_sec": 6000,
  "is_hidden": false
}
```

#### Response (204)

```json
{
  "success": true,
  "data": null,
  "error": null
}
```

---

### 4-3. 시청 세션 로그 목록 – `GET /api/v1/watch-sessions` (선택)

#### Query Params

* `from`, `to`: DATE 문자열 `"YYYY-MM-DD"`

#### Request

```http
GET /api/v1/watch-sessions?from=2025-12-01&to=2025-12-31
Authorization: Bearer {access_token}
X-Profile-Id: 10
```

#### Response (200)

```json
{
  "success": true,
  "data": {
    "sessions": [
      {
        "session_id": 1,
        "content_id": 100,
        "episode_id": null,
        "started_at": "2025-12-10T11:00:00.000Z",
        "ended_at": "2025-12-10T12:00:00.000Z",
        "watched_sec": 3600,
        "device_type": "WEB"
      }
    ]
  },
  "error": null
}
```

---

## 5. Wishlist (찜)

(변경 없음 — 기존 문서 유지)

---

## 6. Reviews (리뷰/별점)

(변경 없음 — 기존 문서 유지)

---

## 7. Security (향후)

* v1 문서에서는 “향후”로만 유지

---

## 8. 향후 확장 메모

* 멤버십/결제 API(`/plans`, `/subscriptions`, `/payments`)는 v2 분리 설계 예정
* 소셜 로그인 `/auth/{provider}` 확장 가능
* 관리자 API `/admin/api/v1/...` 별도
* Watch Party(Phase2) 문서 분리 가능
