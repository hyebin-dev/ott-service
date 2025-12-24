# OTT API v1 명세서 (초안)

## Changelog

### 2025-12-23
- API v1 초안 정리 및 규칙 확정
- 프로필 컨텍스트 전달 방식 `X-Profile-Id` 헤더 통일 정책 확정(프로필 기준 데이터는 헤더 사용)
- 시간 표기 규칙을 ISO 8601 UTC(Z) 형식으로 고정
- Refresh Token 정책 확정 (로테이션 + 서버 저장 + 로그아웃 시 폐기)
- 공통 HTTP Status 코드 매핑 기준 명확화
- 영화/시리즈 통합 `episode_id` 처리 규칙 확정
  - 영화: `episode_id = null`
  - 시리즈: 실제 `episode_id` 사용

- Base URL: `/api/v1`
- Request/Response: JSON (snake_case)
- Auth: `Authorization: Bearer {access_token}` 헤더 사용
- Profile Context: `X-Profile-Id: {profile_id}` 헤더 사용(프로필 기준 데이터 조회/변경 시)
- 모든 시간은 ISO 8601 UTC(Z) 문자열로 통일(예: `"2025-12-10T12:34:56.789Z"`)

---

## 0. 공통 규칙

### 0-1. 공통 응답 형태

기본적으로 아래와 같은 envelope 형태를 사용한다.

```json
{
  "success": true,
  "data": {},
  "error": null
}
````

에러 시:

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
* `message`: 한글 메시지(클라이언트에서 그대로 출력 가능한 수준)

---

### 0-2. 인증

로그인 후 발급되는 액세스 토큰을 `Authorization` 헤더에 넣는다.

```http
Authorization: Bearer {access_token}
```

* 로그인/회원가입/토큰 재발급 등 일부 API를 제외하고는 기본적으로 토큰이 필요하다.

---

### 0-3. 프로필 컨텍스트(X-Profile-Id)

프로필 기준으로 동작하는 API(찜/시청기록/리뷰 작성 등)는 아래 헤더를 사용한다.

```http
X-Profile-Id: {profile_id}
```

* 계정 토큰은 “누구의 계정인지”를 증명한다.
* `X-Profile-Id`는 “그 계정 안에서 어떤 프로필 기준인지”를 지정한다.
* 프로필 자체를 관리하는 API(프로필 생성/수정/삭제, 목록 조회)는 `X-Profile-Id`가 필요하지 않다.

---

### 0-4. HTTP Status & Error Code 매핑(기준)

* `200 OK`: 성공(일반 조회/처리)
* `201 Created`: 생성 성공(리소스 생성)
* `204 No Content`: 성공(응답 바디 없음)
* `400 Bad Request`: 요청 형식/파라미터 검증 실패

  * `VALIDATION_ERROR`, `INVALID_PASSWORD_FORMAT` 등
* `401 Unauthorized`: 인증 실패/토큰 누락/만료

  * `UNAUTHORIZED`, `TOKEN_EXPIRED`
* `403 Forbidden`: 권한/정책 위반

  * `FORBIDDEN`, `PROFILE_PIN_REQUIRED`, `WATCH_TIME_TOO_SHORT`
* `404 Not Found`: 리소스 없음

  * `USER_NOT_FOUND`, `CONTENT_NOT_FOUND`, `PROFILE_NOT_FOUND`
* `409 Conflict`: 중복/상태 충돌

  * `EMAIL_ALREADY_IN_USE`, `ALREADY_REVIEWED`
* `429 Too Many Requests`: 과도한 요청(선택)

  * `RATE_LIMITED`
* `500 Internal Server Error`: 서버 내부 오류

  * `INTERNAL_ERROR`

---

### 0-5. 시간 표기

* 모든 시간은 ISO 8601 UTC(Z) 문자열로 통일한다.
* 예: `"2025-12-10T12:34:56.789Z"`

---

### 0-6. 영화/시리즈 통합 episode_id 규칙(v0 DB 설계 기준)

* 영화: `episode_id = null`
* 시리즈: 실제 `episode_id` 사용

---

## 1. Auth & Users (계정/인증)

### 1-1. 회원가입 – `POST /api/v1/auth/signup`

이메일/비밀번호 기반 회원가입 + 약관 동의.

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

* `agreed_term_codes`: 필수 약관 동의 저장을 위한 코드 배열
* `agreed_marketing`: 선택 약관(MARKETING) 동의 여부

  * true인 경우 서버에서 `MARKETING` 동의 기록을 추가 저장한다.

#### Response (성공, 201)

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

#### 에러 코드 예시

* `EMAIL_ALREADY_IN_USE` (409)
* `INVALID_PASSWORD_FORMAT` (400)
* `TERMS_NOT_ACCEPTED` (403)
* `VALIDATION_ERROR` (400)

---

### 1-2. 로그인 – `POST /api/v1/auth/login`

이메일/비밀번호 로그인.

#### Request Body

```json
{
  "email": "user@example.com",
  "password": "PlainPassword123!"
}
```

#### Response (성공, 200)

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

#### 에러 코드 예시

* `USER_NOT_FOUND` (404)
* `INVALID_CREDENTIALS` (401)
* `USER_BLOCKED` (403)

---

### 1-3. 토큰 재발급 – `POST /api/v1/auth/refresh`

#### Request Body

```json
{
  "refresh_token": "JWT_REFRESH_TOKEN"
}
```

#### Response (성공, 200)

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

#### 에러 코드 예시

* `INVALID_REFRESH_TOKEN` (401)
* `REFRESH_TOKEN_EXPIRED` (401)

---

### 1-4. 내 계정 정보 조회 – `GET /api/v1/users/me`

현재 토큰 기준 계정 정보.

#### Request

```http
GET /api/v1/users/me
Authorization: Bearer {access_token}
```

#### Response (성공, 200)

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

---

## 2. Profiles (프로필 관리)

### 2-1. 프로필 목록 조회 – `GET /api/v1/profiles`

현재 계정의 모든 프로필 리스트.

#### Request

```http
GET /api/v1/profiles
Authorization: Bearer {access_token}
```

#### Response (성공, 200)

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
        "max_age_rating": "19"
      },
      {
        "profile_id": 11,
        "name": "동생",
        "avatar_code": "CAT_1",
        "is_kids": true,
        "pin_enabled": true,
        "max_age_rating": "12"
      }
    ],
    "max_profiles": 5
  },
  "error": null
}
```

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

* `pin`을 null로 보내면 PIN 미설정.
* `is_kids`가 true일 때 `max_age_rating`을 자동으로 낮추는 정책도 가능(서버 정책).

#### Response (성공, 201)

```json
{
  "success": true,
  "data": {
    "profile_id": 12,
    "name": "새 프로필",
    "avatar_code": "DEFAULT_1",
    "is_kids": false,
    "pin_enabled": false,
    "max_age_rating": "19"
  },
  "error": null
}
```

#### 에러 코드 예시

* `PROFILE_LIMIT_EXCEEDED` (403)
* `VALIDATION_ERROR` (400)

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

* 바꾸고 싶은 필드만 보내는 부분 업데이트.
* PIN 변경/활성화 같은 민감 설정은 “계정 비밀번호 재확인” 정책을 추가할 수 있다(향후).

#### Response (성공, 200)

```json
{
  "success": true,
  "data": {
    "profile_id": 10,
    "name": "수정된 이름",
    "avatar_code": "CAT_1",
    "is_kids": false,
    "pin_enabled": true,
    "max_age_rating": "12"
  },
  "error": null
}
```

---

### 2-4. 프로필 삭제 – `DELETE /api/v1/profiles/{profile_id}`

#### Response (성공, 204)

```json
{
  "success": true,
  "data": null,
  "error": null
}
```

* 최소 1개 프로필은 남겨야 한다면, 마지막 1개 삭제 시:

  * `LAST_PROFILE_CANNOT_BE_DELETED` (403)

---

## 3. Contents (콘텐츠 목록/상세)

### 3-1. 콘텐츠 목록 – `GET /api/v1/contents`

홈/탐색에 쓰이는 기본 리스트.
필터/정렬 옵션은 쿼리 파라미터로 전달.

#### Request

```http
GET /api/v1/contents?type=MOVIE&genre=ACTION&page=1&size=20
Authorization: Bearer {access_token}
```

#### Query Params 예시

* `type`: `MOVIE` | `SERIES` (없으면 전체)
* `genre`: 장르(문자열) 또는 장르 코드(정책 확정 필요)
* `age_rating_lte`: 연령 등급 필터(예: `12`, `15`)
* `sort`: `POPULAR`, `NEW`, `TOP_RATED` 등
* `page`, `size`: 페이지네이션

#### Response (성공, 200)

```json
{
  "success": true,
  "data": {
    "contents": [
      {
        "content_id": 100,
        "title_kr": "인터스텔라",
        "type": "MOVIE",
        "age_rating": "12",
        "thumbnail_url": "https://example.com/interstellar.jpg",
        "average_rating": 4.8
      }
    ],
    "page": 1,
    "size": 20,
    "total_elements": 120,
    "total_pages": 6
  },
  "error": null
}
```

---

### 3-2. 콘텐츠 상세 – `GET /api/v1/contents/{content_id}`

영화/시리즈 공통 상세.
프로필 기준 상태(찜 여부, 이어보기 등)를 포함하므로 `X-Profile-Id`가 필요하다.

#### Request

```http
GET /api/v1/contents/100
Authorization: Bearer {access_token}
X-Profile-Id: 10
```

#### Response (성공, 200)

```json
{
  "success": true,
  "data": {
    "content_id": 100,
    "title_kr": "인터스텔라",
    "title_en": "Interstellar",
    "type": "MOVIE",
    "synopsis": "우주를 배경으로 한 SF 드라마...",
    "country": "미국",
    "age_rating": "12",
    "release_year": 2014,
    "runtime_min": 169,
    "genres": ["SF", "드라마"],
    "thumbnail_url": "https://example.com/interstellar.jpg",
    "poster_url": "https://example.com/interstellar-poster.jpg",
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

---

### 3-3. 회차 목록(시리즈) – `GET /api/v1/contents/{content_id}/episodes`

시리즈 콘텐츠의 시즌/회차 목록.

#### Response (성공, 200)

```json
{
  "success": true,
  "data": {
    "seasons": [
      {
        "season_id": 1,
        "season_number": 1,
        "episodes": [
          {
            "episode_id": 10,
            "episode_number": 1,
            "title": "1화",
            "runtime_min": 50
          }
        ]
      }
    ]
  },
  "error": null
}
```

---

## 4. Watch Histories & Sessions (시청 기록 / 이어보기)

프로필 기준 데이터이므로 `X-Profile-Id`가 필요하다.

### 4-1. 시청 기록 목록 – `GET /api/v1/watch-histories`

홈의 “이어보기” 섹션 + 시청 기록 화면에 사용.

#### Request

```http
GET /api/v1/watch-histories
Authorization: Bearer {access_token}
X-Profile-Id: 10
```

#### Response (성공, 200)

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

---

### 4-2. 시청 기록 업데이트 – `PUT /api/v1/watch-histories`

플레이어에서 주기적으로 호출하거나 종료 시점에 호출해서
“어디까지 봤는지”를 저장한다.

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

* 영화: `episode_id = null`
* 시리즈: 실제 `episode_id` 사용

#### Response (성공, 204)

```json
{
  "success": true,
  "data": null,
  "error": null
}
```

---

### 4-3. 시청 세션 로그 목록 – `GET /api/v1/watch-sessions` (선택)

분석/이력 화면 등에 사용 가능(선택 구현).

#### Request

```http
GET /api/v1/watch-sessions?from=2025-12-01&to=2025-12-31
Authorization: Bearer {access_token}
X-Profile-Id: 10
```

#### Response (성공, 200)

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

프로필 기준 데이터이므로 `X-Profile-Id`가 필요하다.

### 5-1. 찜 목록 조회 – `GET /api/v1/wishlist`

#### Request

```http
GET /api/v1/wishlist
Authorization: Bearer {access_token}
X-Profile-Id: 10
```

#### Response (성공, 200)

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "content_id": 100,
        "title_kr": "인터스텔라",
        "type": "MOVIE",
        "thumbnail_url": "https://example.com/interstellar.jpg",
        "added_at": "2025-12-09T10:00:00.000Z"
      }
    ]
  },
  "error": null
}
```

---

### 5-2. 찜 추가 – `POST /api/v1/wishlist`

#### Request

```http
POST /api/v1/wishlist
Authorization: Bearer {access_token}
X-Profile-Id: 10
```

#### Request Body

```json
{
  "content_id": 100
}
```

#### Response (성공, 204)

```json
{
  "success": true,
  "data": null,
  "error": null
}
```

---

### 5-3. 찜 제거 – `DELETE /api/v1/wishlist/{content_id}`

#### Request

```http
DELETE /api/v1/wishlist/100
Authorization: Bearer {access_token}
X-Profile-Id: 10
```

#### Response (성공, 204)

```json
{
  "success": true,
  "data": null,
  "error": null
}
```

---

## 6. Reviews (리뷰/별점)

### 6-1. 작품 리뷰 목록 – `GET /api/v1/contents/{content_id}/reviews`

#### Query Params

* `sort`: `NEWEST`(기본), `HIGHEST_RATED`, `LOWEST_RATED`

#### Response (성공, 200)

```json
{
  "success": true,
  "data": {
    "reviews": [
      {
        "review_id": 123,
        "profile_name": "혜빈",
        "rating": 4.5,
        "title": "몰입감 최고",
        "body": "중간중간 살짝 루즈하지만 전체적으로 재밌었어요.",
        "contains_spoiler": false,
        "created_at": "2025-12-10T10:00:00.000Z"
      }
    ]
  },
  "error": null
}
```

* DB 컬럼 `spoiler`는 API에서는 `contains_spoiler`로 노출한다.

---

### 6-2. 리뷰 작성 – `POST /api/v1/contents/{content_id}/reviews`

조건: 해당 프로필이 해당 작품을 **30% 이상 시청한 경우에만** 허용.

#### Request

```http
POST /api/v1/contents/100/reviews
Authorization: Bearer {access_token}
X-Profile-Id: 10
```

#### Request Body

```json
{
  "rating": 4.5,
  "title": "몰입감 최고",
  "body": "중간중간 살짝 루즈하지만 전체적으로 재밌었어요.",
  "contains_spoiler": false,
  "is_private": false
}
```

#### Response (성공, 201)

```json
{
  "success": true,
  "data": {
    "review_id": 123
  },
  "error": null
}
```

#### 에러 코드 예시

* `WATCH_TIME_TOO_SHORT` (403)
* `ALREADY_REVIEWED` (409)

---

### 6-3. 리뷰 수정 – `PATCH /api/v1/reviews/{review_id}`

#### Request Body

```json
{
  "rating": 5.0,
  "title": "재감상 후 재평가",
  "body": "두 번째 보니까 더 좋았어요.",
  "contains_spoiler": false,
  "is_private": false
}
```

#### Response (성공, 204)

```json
{
  "success": true,
  "data": null,
  "error": null
}
```

---

### 6-4. 리뷰 삭제 – `DELETE /api/v1/reviews/{review_id}`

#### Response (성공, 204)

```json
{
  "success": true,
  "data": null,
  "error": null
}
```

---

## 7. Security (보안/디바이스 관리) (향후)

* v0 DB에는 디바이스 테이블이 아직 없으므로, v1 문서에서는 “향후”로만 정리한다.

### 7-1. 최근 접속 기기 목록 – `GET /api/v1/security/devices` (향후)

### 7-2. 특정 디바이스 로그아웃 – `POST /api/v1/security/devices/{device_id}/logout` (향후)

### 7-3. 모든 디바이스에서 로그아웃 – `POST /api/v1/security/devices/logout-all` (향후)

---

## 8. 향후 확장 메모

* 멤버십/결제 API (`/plans`, `/subscriptions`, `/payments`) 는 v2에서 분리 설계 예정.
* 소셜 로그인(Kakao/Google/Naver)용 `/auth/{provider}` 엔드포인트 추가 가능.
* 관리자용 API는 `/admin/api/v1/...` 네임스페이스로 별도 분리 예정.
* Watch Party(Phase2)는 별도 문서로 분리 가능.
